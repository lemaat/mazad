from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction
from django.db.models import BooleanField, Exists, Max, OuterRef, Value
from django.utils import timezone
from rest_framework import parsers, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from . import auction_lifecycle
from .models import Address, Bid, Category, Deposit, Dispute, DeviceToken, Favorite, KYCSubmission, Listing, ListingBan, ListingImage, Notification, Sale
from .notifications_service import notify
from .permissions import IsOwnerOrReadOnly
from .serializers import (
    AddressSerializer, BidSerializer, CategorySerializer, DepositCreateSerializer,
    DisputeSerializer, DisputeSubmitSerializer,
    KYCStatusSerializer, KYCSubmitSerializer,
    ListingDetailSerializer, ListingListSerializer, NotificationSerializer, PlaceBidSerializer,
    WalletSerializer,
)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]  # anyone can browse categories


class ListingViewSet(viewsets.ModelViewSet):
    queryset = Listing.objects.select_related("category", "seller").prefetch_related("images", "documents", "bids")
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]

    def get_queryset(self):
        # Self-heal time-driven status transitions on read (start a
        # SCHEDULED auction whose start time has passed, close a LIVE one
        # whose end time has passed, ...) instead of relying on an operator
        # to remember to run `close_expired_auctions` — see
        # auction_lifecycle.py for why this exists. The has_pending_work()
        # guard keeps this to one cheap indexed query on the (overwhelmingly
        # common) case where nothing is actually overdue.
        if auction_lifecycle.has_pending_work():
            auction_lifecycle.run()

        qs = super().get_queryset()
        user = self.request.user
        if user.is_authenticated:
            qs = qs.annotate(
                is_favorited=Exists(
                    Favorite.objects.filter(user=user, listing_id=OuterRef('pk'))
                )
            )
        else:
            qs = qs.annotate(is_favorited=Value(False, output_field=BooleanField()))
        category = self.request.query_params.get('category')
        if category:
            qs = qs.filter(category__slug=category)
        status_param = self.request.query_params.get('status')
        if status_param:
            statuses = [s.strip() for s in status_param.split(',')]
            qs = qs.filter(status__in=statuses)
        mine = self.request.query_params.get('mine')
        if mine == 'true' and user.is_authenticated:
            qs = qs.filter(seller=user)
        return qs

    def get_serializer_class(self):
        return ListingListSerializer if self.action == "list" else ListingDetailSerializer

    def get_serializer_context(self):
        return {"request": self.request}

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def place_bid(self, request, pk=None):
        """
        The core protocol, enforced here:
        - listing must be LIVE right now (no pre-bidding)
        - bidder must not be banned from this specific listing
        - bidder must have an active deposit whose ceiling covers this amount
        - bid must clear current price + min increment
        - triggers 2-min soft close if placed near the deadline
        select_for_update() locks the row so two simultaneous bids can't both
        "win" the same race — the second one waits, then re-checks against
        the now-updated price.
        """
        serializer = PlaceBidSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        amount = serializer.validated_data["amount"]
        is_anonymous = serializer.validated_data["is_anonymous"]

        prev_leader = None
        with transaction.atomic():
            listing = Listing.objects.select_for_update().get(pk=pk)
            now = timezone.now()

            if not listing.is_live():
                return Response({"detail": "This auction is not currently live."}, status=status.HTTP_400_BAD_REQUEST)

            if request.user.id == listing.seller_id:
                return Response({"detail": "Sellers cannot bid on their own listing."}, status=status.HTTP_400_BAD_REQUEST)

            if ListingBan.objects.filter(user=request.user, listing=listing).exists():
                return Response({"detail": "You are banned from bidding on this listing."}, status=status.HTTP_403_FORBIDDEN)

            deposit = Deposit.objects.filter(
                user=request.user, listing=listing, status=Deposit.Status.ACTIVE
            ).first()
            if not deposit:
                return Response({"detail": "You need an active deposit on this listing before bidding."}, status=status.HTTP_400_BAD_REQUEST)

            if amount > deposit.bid_ceiling():
                return Response(
                    {"detail": f"This bid exceeds your ceiling of {deposit.bid_ceiling()} based on your deposit."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            min_acceptable = (listing.current_price or listing.starting_price) + listing.min_increment
            if amount < min_acceptable:
                return Response({"detail": f"Bid must be at least {min_acceptable}."}, status=status.HTTP_400_BAD_REQUEST)

            # Capture the current leader before this bid displaces them.
            if listing.current_price is not None:
                top_other = Bid.objects.filter(listing=listing).exclude(bidder=request.user).first()
                if top_other:
                    prev_leader = top_other.bidder

            bid = Bid.objects.create(listing=listing, bidder=request.user, amount=amount, is_anonymous=is_anonymous)
            listing.current_price = amount
            listing.save(update_fields=["current_price", "updated_at"])
            listing.extend_if_soft_close(now)  # 2-min soft close check

        
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"auction_{listing.id}",
            {
                "type": "auction_update",
                "data": {
                    "type": "bid_placed",
                    "current_price": str(listing.current_price),
                    "auction_end": listing.auction_end.isoformat(),
                    "last_bid_amount": str(amount),
                    "bidder_display": {
                        "label": (
                            bid.bidder.bidder_number
                            if is_anonymous
                            else (bid.bidder.username or bid.bidder.bidder_number)
                        ),
                        "verification_tier": bid.bidder.verification_tier,
                    },
                },
            },
        )

        if prev_leader and prev_leader.pk != request.user.pk:
            notify(
                recipient=prev_leader,
                notification_type=Notification.Type.OUTBID,
                title="You've been outbid!",
                body=f'Someone placed a higher bid on "{listing.title}".',
                data={
                    'listing_id': str(listing.id),
                    'listing_title': listing.title,
                    'current_price': str(amount),
                },
            )

        return Response(BidSerializer(bid).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["get"])
    def bids(self, request, pk=None):
        listing = self.get_object()
        return Response(BidSerializer(listing.bids.all(), many=True).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def pay_listing_fee(self, request, pk=None):
        """Sedad stub — marks listing fee as paid and transitions to SCHEDULED."""
        listing = self.get_object()
        if listing.seller_id != request.user.id:
            return Response({"detail": "Only the seller can pay the listing fee."}, status=status.HTTP_403_FORBIDDEN)
        if listing.status != Listing.Status.PENDING_PAYMENT:
            return Response({"detail": "Listing is not awaiting fee payment."}, status=status.HTTP_400_BAD_REQUEST)
        listing.listing_fee_paid = True
        listing.status = Listing.Status.SCHEDULED
        listing.save(update_fields=["listing_fee_paid", "status", "updated_at"])
        return Response(ListingDetailSerializer(listing, context={"request": request}).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def offer_second_chance(self, request, pk=None):
        """Seller-only: offer the item to the runner-up bidder at their bid price."""
        listing = self.get_object()
        if listing.seller_id != request.user.id:
            return Response({"detail": "Only the seller can offer a second chance."}, status=status.HTTP_403_FORBIDDEN)
        if listing.status != Listing.Status.PENDING_SELLER_DECISION:
            return Response({"detail": "Listing is not pending a seller decision."}, status=status.HTTP_400_BAD_REQUEST)

        top_bidder_data = list(
            listing.bids.values('bidder_id')
            .annotate(max_amount=Max('amount'))
            .order_by('-max_amount')[:2]
        )
        if len(top_bidder_data) < 2:
            return Response({"detail": "No runner-up bidder to offer a second chance to."}, status=status.HTTP_400_BAD_REQUEST)

        from django.contrib.auth import get_user_model
        User = get_user_model()
        runner_up = User.objects.get(id=top_bidder_data[1]['bidder_id'])
        runner_up_amount = top_bidder_data[1]['max_amount']

        sale = listing.sale
        sale.second_chance_deadline = timezone.now() + timezone.timedelta(minutes=10)
        sale.save(update_fields=['second_chance_deadline'])

        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"auction_{listing.id}",
            {
                "type": "auction_update",
                "data": {
                    "type": "second_chance_offered",
                    "runner_up_bidder_number": runner_up.bidder_number,
                    "deadline": sale.second_chance_deadline.isoformat(),
                    "amount": str(runner_up_amount),
                },
            },
        )
        notify(
            recipient=runner_up,
            notification_type=Notification.Type.SECOND_CHANCE_RECEIVED,
            title='Second chance offer!',
            body=f'You\'ve been offered a second chance on "{listing.title}". Expires in 10 minutes.',
            data={
                'listing_id': str(listing.id),
                'listing_title': listing.title,
                'offer_price': str(runner_up_amount),
                'deadline': sale.second_chance_deadline.isoformat(),
            },
        )

        return Response({
            "runner_up_bidder_number": runner_up.bidder_number,
            "deadline": sale.second_chance_deadline.isoformat(),
            "amount": str(runner_up_amount),
        })

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def accept_second_chance(self, request, pk=None):
        """Runner-up bidder accepts the second-chance offer within the deadline."""
        with transaction.atomic():
            listing = Listing.objects.select_for_update().get(pk=pk)
            if listing.status != Listing.Status.PENDING_SELLER_DECISION:
                return Response({"detail": "No active second-chance offer."}, status=status.HTTP_400_BAD_REQUEST)

            sale = listing.sale
            if not sale.second_chance_deadline or timezone.now() > sale.second_chance_deadline:
                return Response({"detail": "Second-chance offer has expired."}, status=status.HTTP_400_BAD_REQUEST)

            top_bidder_data = list(
                listing.bids.values('bidder_id')
                .annotate(max_amount=Max('amount'))
                .order_by('-max_amount')[:2]
            )
            if len(top_bidder_data) < 2 or top_bidder_data[1]['bidder_id'] != request.user.id:
                return Response({"detail": "You are not the runner-up bidder."}, status=status.HTTP_403_FORBIDDEN)

            runner_up_amount = top_bidder_data[1]['max_amount']
            sale.buyer = request.user
            sale.final_price = runner_up_amount
            sale.commission_amount = sale.compute_commission()
            sale.status = Sale.Status.AWAITING_PAYMENT
            sale.second_chance_deadline = None
            sale.save(update_fields=['buyer', 'final_price', 'commission_amount', 'status', 'second_chance_deadline'])

            listing.status = Listing.Status.ENDED_SOLD
            listing.save(update_fields=['status', 'updated_at'])
            # Release all deposits except the new buyer's — theirs stays ACTIVE until mark_paid().
            listing.release_deposits(exclude_user=request.user)

        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"auction_{listing.id}",
            {
                "type": "auction_update",
                "data": {
                    "type": "auction_closed",
                    "status": listing.status,
                    "winner_bidder_number": request.user.bidder_number,
                    "winning_amount": str(runner_up_amount),
                },
            },
        )
        notify(
            recipient=sale.seller,
            notification_type=Notification.Type.SECOND_CHANCE_ACCEPTED,
            title='Second chance accepted',
            body=f'The runner-up accepted your second-chance offer on "{listing.title}".',
            data={
                'listing_id': str(listing.id),
                'listing_title': listing.title,
                'final_price': str(sale.final_price),
            },
        )

        return Response({"status": listing.status, "final_price": str(sale.final_price)})

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def end_unsold(self, request, pk=None):
        """Seller closes the listing as unsold — no second chance offered."""
        listing = self.get_object()
        if listing.seller_id != request.user.id:
            return Response({"detail": "Only the seller can end the listing."}, status=status.HTTP_403_FORBIDDEN)
        if listing.status != Listing.Status.PENDING_SELLER_DECISION:
            return Response({"detail": "Listing is not pending a seller decision."}, status=status.HTTP_400_BAD_REQUEST)
        with transaction.atomic():
            listing.status = Listing.Status.ENDED_UNSOLD
            listing.save(update_fields=['status', 'updated_at'])
            listing.release_deposits()
        return Response({"status": listing.status})

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def confirm_payment(self, request, pk=None):
        """Sedad stub — buyer confirms the winning-bid payment."""
        listing = self.get_object()
        try:
            sale = listing.sale
        except Exception:
            return Response({"detail": "No sale found."}, status=status.HTTP_400_BAD_REQUEST)
        if sale.buyer_id != request.user.id:
            return Response({"detail": "Only the buyer can confirm payment."}, status=status.HTTP_403_FORBIDDEN)
        if sale.status != Sale.Status.AWAITING_PAYMENT:
            return Response({"detail": "Sale is not awaiting payment."}, status=status.HTTP_400_BAD_REQUEST)
        sale.mark_paid()
        return Response({"status": sale.status})

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def set_delivery_address(self, request, pk=None):
        """Buyer links one of their saved addresses to this sale."""
        listing = self.get_object()
        try:
            sale = listing.sale
        except Exception:
            return Response({"detail": "No sale found."}, status=status.HTTP_400_BAD_REQUEST)
        if sale.buyer_id != request.user.id:
            return Response({"detail": "Only the buyer can set the delivery address."}, status=status.HTTP_403_FORBIDDEN)
        address_id = request.data.get('address_id')
        if not address_id:
            return Response({"detail": "address_id is required."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            address = Address.objects.get(id=address_id, user=request.user)
        except Address.DoesNotExist:
            return Response({"detail": "Address not found."}, status=status.HTTP_400_BAD_REQUEST)
        sale.delivery_address = address
        sale.save(update_fields=['delivery_address'])
        return Response(AddressSerializer(address).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def mark_shipped(self, request, pk=None):
        """Seller marks the item as shipped once the buyer has provided an address."""
        listing = self.get_object()
        if listing.seller_id != request.user.id:
            return Response({"detail": "Only the seller can mark as shipped."}, status=status.HTTP_403_FORBIDDEN)
        try:
            sale = listing.sale
        except Exception:
            return Response({"detail": "No sale found."}, status=status.HTTP_400_BAD_REQUEST)
        if sale.status != Sale.Status.PAID:
            return Response({"detail": "Sale must be confirmed paid before marking as shipped."}, status=status.HTTP_400_BAD_REQUEST)
        if not sale.delivery_address_id:
            return Response({"detail": "Buyer must provide a delivery address first."}, status=status.HTTP_400_BAD_REQUEST)
        if sale.shipped_at:
            return Response({"detail": "Already marked as shipped."}, status=status.HTTP_400_BAD_REQUEST)
        sale.shipped_at = timezone.now()
        sale.tracking_note = request.data.get('tracking_note', '')
        sale.save(update_fields=['shipped_at', 'tracking_note'])
        notify(
            recipient=sale.buyer,
            notification_type=Notification.Type.ORDER_SHIPPED,
            title='Your item has been shipped',
            body=f'"{listing.title}" is on its way to you.',
            data={
                'listing_id': str(listing.id),
                'listing_title': listing.title,
                'tracking_note': sale.tracking_note or '',
            },
        )
        return Response({"shipped_at": sale.shipped_at.isoformat(), "tracking_note": sale.tracking_note})

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def favorite(self, request, pk=None):
        listing = self.get_object()
        Favorite.objects.get_or_create(user=request.user, listing=listing)
        return Response({"is_favorited": True})

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def unfavorite(self, request, pk=None):
        listing = self.get_object()
        Favorite.objects.filter(user=request.user, listing=listing).delete()
        return Response({"is_favorited": False})

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def report_dispute(self, request, pk=None):
        """Buyer or seller flags a problem with this listing's sale for admin review."""
        listing = self.get_object()
        try:
            sale = listing.sale
        except Exception:
            return Response({"detail": "No sale found for this listing."}, status=status.HTTP_400_BAD_REQUEST)
        if request.user.id not in (sale.buyer_id, sale.seller_id):
            return Response(
                {"detail": "Only the buyer or seller of this sale can report a dispute."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if Dispute.objects.filter(
            sale=sale, raised_by=request.user, status__in=[Dispute.Status.OPEN, Dispute.Status.UNDER_REVIEW],
        ).exists():
            return Response({"detail": "You already have an open dispute on this sale."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = DisputeSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        dispute = Dispute.objects.create(sale=sale, raised_by=request.user, **serializer.validated_data)
        return Response(DisputeSerializer(dispute).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], parser_classes=[parsers.MultiPartParser],
            permission_classes=[permissions.IsAuthenticated])
    def upload_image(self, request, pk=None):
        """Upload one image to a listing. Owner-only; only while not live or ended."""
        listing = self.get_object()
        if listing.seller_id != request.user.id:
            return Response(
                {'detail': 'Only the listing owner can upload images.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        _uploadable = {
            Listing.Status.PENDING_PAYMENT,
            Listing.Status.SCHEDULED,
            Listing.Status.PENDING_SELLER_DECISION,
        }
        if listing.status not in _uploadable:
            return Response(
                {'detail': 'Photos can only be added while the listing is pending payment, scheduled, or pending a seller decision.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({'detail': 'No image file provided.'}, status=status.HTTP_400_BAD_REQUEST)
        if listing.images.count() >= 5:
            return Response({'detail': 'Maximum 5 images allowed per listing.'}, status=status.HTTP_400_BAD_REQUEST)
        is_primary = not listing.images.exists()
        img = ListingImage.objects.create(listing=listing, image=image_file, is_primary=is_primary)
        return Response(
            {'id': img.id, 'image': request.build_absolute_uri(img.image.url), 'is_primary': img.is_primary},
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def confirm_received(self, request, pk=None):
        """Buyer confirms the item arrived."""
        listing = self.get_object()
        try:
            sale = listing.sale
        except Exception:
            return Response({"detail": "No sale found."}, status=status.HTTP_400_BAD_REQUEST)
        if sale.buyer_id != request.user.id:
            return Response({"detail": "Only the buyer can confirm receipt."}, status=status.HTTP_403_FORBIDDEN)
        if not sale.shipped_at:
            return Response({"detail": "Item has not been marked as shipped yet."}, status=status.HTTP_400_BAD_REQUEST)
        if sale.delivered_at:
            return Response({"detail": "Already confirmed as received."}, status=status.HTTP_400_BAD_REQUEST)
        sale.delivered_at = timezone.now()
        sale.save(update_fields=['delivered_at'])
        notify(
            recipient=sale.seller,
            notification_type=Notification.Type.ORDER_RECEIVED,
            title='Buyer confirmed delivery',
            body=f'The buyer confirmed receipt of "{listing.title}".',
            data={
                'listing_id': str(listing.id),
                'listing_title': listing.title,
            },
        )
        return Response({"delivered_at": sale.delivered_at.isoformat()})


class AddressViewSet(viewsets.ModelViewSet):
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        if serializer.validated_data.get('is_default', False):
            Address.objects.filter(user=self.request.user, is_default=True).update(is_default=False)
        serializer.save(user=self.request.user)

    def perform_update(self, serializer):
        if serializer.validated_data.get('is_default', False):
            Address.objects.filter(user=self.request.user, is_default=True).exclude(
                pk=self.get_object().pk
            ).update(is_default=False)
        serializer.save()


class WalletView(APIView):
    """A user's own wallet — GET only, no editing balance directly via API
    (top-ups will go through the Sedad payment flow later)."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(WalletSerializer(request.user.wallet).data)


class DepositViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        listing_id = request.query_params.get('listing_id')
        qs = Deposit.objects.filter(
            user=request.user, status=Deposit.Status.ACTIVE
        ).select_related('listing')
        if listing_id:
            qs = qs.filter(listing_id=listing_id)
        return Response([
            {
                "id": str(d.id),
                "listing_id": str(d.listing_id),
                "listing_title": d.listing.title,
                "amount_held": str(d.amount_held),
                "bid_ceiling": f"{d.bid_ceiling():.2f}",
                "status": d.status,
            }
            for d in qs
        ])

    def create(self, request):
        serializer = DepositCreateSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        listing = serializer.validated_data["listing"]
        amount_to_add = serializer.validated_data["amount_held"]

        existing = Deposit.objects.filter(
            user=request.user, listing=listing, status=Deposit.Status.ACTIVE
        ).first()
        if existing:
            existing.amount_held += amount_to_add
            existing.save(update_fields=["amount_held"])
            deposit = existing
        else:
            deposit = Deposit.objects.create(
                user=request.user,
                listing=listing,
                amount_held=amount_to_add,
            )
        return Response(
            {
                "id": str(deposit.id),
                "listing_id": str(listing.id),
                "listing_title": listing.title,
                "amount_held": str(deposit.amount_held),
                "bid_ceiling": f"{deposit.bid_ceiling():.2f}",
                "status": deposit.status,
            },
            status=status.HTTP_201_CREATED,
        )

class KYCView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser]

    def get(self, request):
        sub = KYCSubmission.objects.filter(user=request.user).first()
        if not sub:
            return Response({"status": "none"})
        return Response(KYCStatusSerializer(sub).data)

    def post(self, request):
        if KYCSubmission.objects.filter(user=request.user, status=KYCSubmission.Status.PENDING).exists():
            return Response(
                {"detail": "You already have a pending KYC submission."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = KYCSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user)
        return Response({"detail": "Submitted successfully."}, status=status.HTTP_201_CREATED)


class MyDisputesListView(APIView):
    """Every dispute the authenticated user is a party to — filed by them or against them."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from django.db.models import Q
        qs = Dispute.objects.filter(
            Q(raised_by=request.user) | Q(sale__buyer=request.user) | Q(sale__seller=request.user)
        ).select_related('sale__listing', 'raised_by', 'sale__buyer', 'sale__seller').distinct()
        return Response(DisputeSerializer(qs, many=True).data)


class FavoriteListView(APIView):
    """Listings the authenticated user has favorited, ordered newest-first."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        favorites = (
            Favorite.objects.filter(user=request.user)
            .select_related('listing__category', 'listing__seller')
            .prefetch_related('listing__images', 'listing__bids')
            .order_by('-created_at')
        )
        listings = []
        for fav in favorites:
            fav.listing.is_favorited = True
            listings.append(fav.listing)
        return Response(ListingListSerializer(listings, many=True, context={'request': request}).data)


class NotificationListView(APIView):
    """Paginated list of the current user's notifications, newest first."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        page = max(1, int(request.query_params.get('page', 1)))
        page_size = min(100, max(1, int(request.query_params.get('page_size', 20))))
        offset = (page - 1) * page_size
        qs = Notification.objects.filter(recipient=request.user)
        total = qs.count()
        results = qs[offset:offset + page_size]
        return Response({
            'count': total,
            'page': page,
            'page_size': page_size,
            'results': NotificationSerializer(results, many=True).data,
        })


class UnreadCountView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        count = Notification.objects.filter(recipient=request.user, is_read=False).count()
        return Response({'count': count})


class MarkReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        updated = Notification.objects.filter(pk=pk, recipient=request.user).update(is_read=True)
        if not updated:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response({'status': 'ok'})


class MarkAllReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        return Response({'status': 'ok'})


class RegisterDeviceView(APIView):
    """Upsert an FCM device token for the authenticated user."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = request.data.get('token', '').strip()
        platform = request.data.get('platform', '').strip()
        if not token:
            return Response({'detail': 'token is required.'}, status=status.HTTP_400_BAD_REQUEST)
        if platform not in ('android', 'ios'):
            return Response({'detail': 'platform must be "android" or "ios".'}, status=status.HTTP_400_BAD_REQUEST)
        # Upsert — a token can move to a different user on device sign-out/sign-in.
        DeviceToken.objects.update_or_create(
            token=token,
            defaults={'user': request.user, 'platform': platform},
        )
        return Response({'status': 'ok'})


class UnregisterDeviceView(APIView):
    """Remove an FCM token on logout so this device no longer receives pushes."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = request.data.get('token', '').strip()
        if not token:
            return Response({'detail': 'token is required.'}, status=status.HTTP_400_BAD_REQUEST)
        DeviceToken.objects.filter(user=request.user, token=token).delete()
        return Response({'status': 'ok'})


from rest_framework.authtoken.models import Token
from .serializers import LoginSerializer, RegisterSerializer


class MyBidListView(APIView):
    """Returns the authenticated user's highest bid per listing, most recent first."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        aggs = (
            Bid.objects.filter(bidder=request.user)
            .values('listing_id')
            .annotate(my_highest=Max('amount'))
            .order_by('-my_highest')
        )
        listing_ids = [a['listing_id'] for a in aggs]
        bid_map = {a['listing_id']: a['my_highest'] for a in aggs}

        listings = (
            Listing.objects.filter(id__in=listing_ids)
            .select_related('category')
        )
        listing_map = {l.id: l for l in listings}

        result = []
        for agg in aggs:
            listing = listing_map.get(agg['listing_id'])
            if not listing:
                continue
            my_amount = agg['my_highest']
            result.append({
                'listing_id': str(listing.id),
                'listing_title': listing.title,
                'listing_status': listing.status,
                'category_name': listing.category.name,
                'my_amount': str(my_amount),
                'current_price': str(listing.current_price) if listing.current_price else None,
                'is_leading': listing.current_price is not None and my_amount >= listing.current_price,
                'auction_end': listing.auction_end.isoformat(),
                'auction_start': listing.auction_start.isoformat(),
            })
        return Response(result)


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {"token": token.key, "bidder_number": user.bidder_number, "username": user.username, "verification_tier": user.verification_tier},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": token.key, "bidder_number": user.bidder_number, "username": user.username, "verification_tier": user.verification_tier})


