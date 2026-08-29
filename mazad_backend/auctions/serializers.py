from django.core.exceptions import ObjectDoesNotExist
from django.db.models import Max
from rest_framework import serializers

from .models import (
    Address, Bid, Category, Deposit, Dispute, Favorite, KYCSubmission, Listing, ListingDocument,
    ListingImage, Notification, Sale, Wallet,
)


class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = ['id', 'label', 'full_name', 'street', 'city', 'country', 'phone', 'is_default', 'created_at']
        read_only_fields = ['id', 'created_at']


class UserPublicSerializer(serializers.Serializer):
    """Minimal, safe-to-expose view of a user — never raw model fields directly."""
    bidder_number = serializers.CharField()
    verification_tier = serializers.CharField()
    is_merchant = serializers.BooleanField()
    rating_average = serializers.DecimalField(max_digits=3, decimal_places=2)
    rating_count = serializers.IntegerField()


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "slug", "name", "requires_id_verification", "listing_fee", "commission_rate"]
        read_only_fields = fields


class ListingImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingImage
        fields = ["id", "image", "is_primary", "order"]


class ListingDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingDocument
        fields = ["id", "file", "label"]


class BidSerializer(serializers.ModelSerializer):
    bidder_display = serializers.SerializerMethodField()

    class Meta:
        model = Bid
        fields = ["id", "listing", "bidder_display", "amount", "is_anonymous", "created_at"]
        read_only_fields = ["id", "created_at", "listing"]

    def get_bidder_display(self, obj):
        # Anonymity is opt-in per bid, but the verification badge always shows —
        # matches the "anonymous identity, visible trust signal" decision.
        if obj.is_anonymous:
            return {"label": obj.bidder.bidder_number, "verification_tier": obj.bidder.verification_tier}
        return {"label": obj.bidder.username or obj.bidder.bidder_number,
                 "verification_tier": obj.bidder.verification_tier}


class PlaceBidSerializer(serializers.Serializer):
    """Write-only input for the place_bid action — not a ModelSerializer,
    since placing a bid involves validation logic beyond a simple field check."""
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    is_anonymous = serializers.BooleanField(default=False)

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Bid amount must be positive.")
        return value


class ListingListSerializer(serializers.ModelSerializer):
    """Lightweight — used for the browse/search feed."""
    category = CategorySerializer(read_only=True)
    primary_image = serializers.SerializerMethodField()
    bid_count = serializers.IntegerField(source="bids.count", read_only=True)
    seller_bidder_number = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Listing
        fields = [
            "id", "title", "category", "current_price", "starting_price",
            "auction_start", "auction_end", "status", "primary_image", "bid_count",
            "seller_bidder_number", "is_favorited",
        ]
        read_only_fields = fields

    def get_primary_image(self, obj):
        img = obj.images.filter(is_primary=True).first() or obj.images.first()
        if not img:
            return None
        request = self.context.get('request')
        return request.build_absolute_uri(img.image.url) if request else img.image.url

    def get_seller_bidder_number(self, obj):
        return obj.seller.bidder_number

    def get_is_favorited(self, obj):
        # Populated by Exists() annotation in ListingViewSet.get_queryset(),
        # or set directly on instances returned by FavoriteListView.
        return bool(getattr(obj, 'is_favorited', False))


class ListingDetailSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        source="category", queryset=Category.objects.all(), write_only=True
    )
    images = ListingImageSerializer(many=True, read_only=True)
    documents = ListingDocumentSerializer(many=True, read_only=True)
    top_bids = serializers.SerializerMethodField()
    sale = serializers.SerializerMethodField()
    seller_bidder_number = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Listing
        fields = [
            "id", "seller", "seller_bidder_number", "category", "category_id", "title", "description",
            "starting_price", "reserve_price", "min_increment", "current_price",
            "auction_start", "auction_end", "soft_close_window_seconds",
            "status", "listing_fee_paid", "images", "documents", "top_bids", "sale", "created_at",
            "is_favorited",
        ]
        read_only_fields = ["id", "seller", "seller_bidder_number", "current_price", "status", "listing_fee_paid", "created_at"]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get('request')
        is_seller = request and request.user.id == instance.seller_id
        if not (is_seller or (request and request.user.is_staff)):
            data.pop('reserve_price', None)
        return data

    def get_is_favorited(self, obj):
        return bool(getattr(obj, 'is_favorited', False))

    def get_seller_bidder_number(self, obj):
        return obj.seller.bidder_number

    def get_top_bids(self, obj):
        return BidSerializer(obj.bids.all()[:10], many=True).data

    def get_sale(self, obj):
        try:
            s = obj.sale
        except ObjectDoesNotExist:
            return None

        from .models import User

        # Runner-up: second-highest unique bidder by their max bid amount
        top_bidder_data = list(
            obj.bids.values('bidder_id')
            .annotate(max_amount=Max('amount'))
            .order_by('-max_amount')[:2]
        )
        runner_up_bidder_number = None
        if len(top_bidder_data) >= 2:
            runner_up = User.objects.filter(id=top_bidder_data[1]['bidder_id']).first()
            if runner_up:
                runner_up_bidder_number = runner_up.bidder_number

        # Delivery address is withheld until the buyer has confirmed payment
        delivery_addr_data = None
        if s.delivery_address_id and s.status != Sale.Status.AWAITING_PAYMENT:
            delivery_addr_data = AddressSerializer(s.delivery_address).data

        return {
            "buyer_bidder_number": s.buyer.bidder_number,
            "final_price": str(s.final_price),
            "status": s.status,
            "second_chance_deadline": s.second_chance_deadline.isoformat() if s.second_chance_deadline else None,
            "runner_up_bidder_number": runner_up_bidder_number,
            "delivery_address": delivery_addr_data,
            "shipped_at": s.shipped_at.isoformat() if s.shipped_at else None,
            "delivered_at": s.delivered_at.isoformat() if s.delivered_at else None,
            "tracking_note": s.tracking_note or None,
        }

    def validate(self, attrs):
        # Reserve price is mandatory everywhere — the model already enforces this
        # at the database level (no null=True), this just gives a clean API error
        # instead of a raw database exception.
        if "reserve_price" not in attrs and self.instance is None:
            raise serializers.ValidationError({"reserve_price": "Reserve price is required for every listing."})

        start = attrs.get("auction_start", getattr(self.instance, "auction_start", None))
        end = attrs.get("auction_end", getattr(self.instance, "auction_end", None))
        if start and end and end <= start:
            raise serializers.ValidationError("auction_end must be after auction_start.")

        category = attrs.get("category")
        request = self.context.get("request")
        if category and category.requires_id_verification and request:
            if request.user.verification_tier != "id_verified":
                raise serializers.ValidationError(
                    f"{category.name} listings require ID verification."
                )
        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        return Listing.objects.create(
            seller=request.user,
            current_price=validated_data["starting_price"],
            status=Listing.Status.PENDING_PAYMENT,
            **validated_data,
        )


class WalletSerializer(serializers.ModelSerializer):
    available_balance = serializers.SerializerMethodField()

    class Meta:
        model = Wallet
        fields = ["balance", "available_balance"]
        read_only_fields = fields

    def get_available_balance(self, obj):
        return str(obj.available_balance())


class DepositCreateSerializer(serializers.Serializer):
    """Committing a hold for a specific listing — separate from wallet top-up."""
    listing_id = serializers.UUIDField()
    amount_held = serializers.DecimalField(max_digits=12, decimal_places=2)

    def validate(self, attrs):
        request = self.context["request"]
        wallet = request.user.wallet
        if attrs["amount_held"] > wallet.available_balance():
            raise serializers.ValidationError("Insufficient wallet balance for this deposit.")
        try:
            attrs["listing"] = Listing.objects.get(pk=attrs["listing_id"])
        except Listing.DoesNotExist:
            raise serializers.ValidationError({"listing_id": "Listing not found."})
        return attrs


class KYCSubmitSerializer(serializers.ModelSerializer):
    class Meta:
        model = KYCSubmission
        fields = ["id_front", "id_back", "selfie"]

    def create(self, validated_data):
        return KYCSubmission.objects.create(**validated_data)


class KYCStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = KYCSubmission
        fields = ["status", "rejection_reason", "submitted_at", "reviewed_at"]
        read_only_fields = fields


class DisputeSubmitSerializer(serializers.Serializer):
    """Write-only input for reporting a dispute on a listing's sale."""
    category = serializers.ChoiceField(choices=Dispute.Category.choices)
    description = serializers.CharField()
    evidence = serializers.ImageField(required=False, allow_null=True)

    def validate_description(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("A description is required.")
        return value


class DisputeSerializer(serializers.ModelSerializer):
    raised_by_bidder_number = serializers.CharField(source="raised_by.bidder_number", read_only=True)
    other_party_bidder_number = serializers.SerializerMethodField()
    listing_id = serializers.UUIDField(source="sale.listing_id", read_only=True)
    listing_title = serializers.CharField(source="sale.listing.title", read_only=True)

    class Meta:
        model = Dispute
        fields = [
            "id", "sale", "listing_id", "listing_title",
            "raised_by_bidder_number", "other_party_bidder_number",
            "category", "description", "evidence", "status", "resolution_note",
            "created_at", "resolved_at",
        ]
        read_only_fields = fields

    def get_other_party_bidder_number(self, obj):
        return obj.other_party().bidder_number


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'notification_type', 'title', 'body', 'data', 'is_read', 'created_at']
        read_only_fields = fields


from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token

from .models import User, Wallet


class RegisterSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate_phone_number(self, value):
        if User.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("This phone number is already registered.")
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            phone_number=validated_data["phone_number"],
            username=validated_data["username"],
            password=validated_data["password"],
        )
        Wallet.objects.create(user=user)
        return user


class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(phone_number=attrs["phone_number"], password=attrs["password"])
        if not user:
            raise serializers.ValidationError("Invalid phone number or password.")
        attrs["user"] = user
        return attrs


