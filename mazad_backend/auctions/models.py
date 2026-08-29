import uuid

from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    
    #Custom user model — phone number is the primary identifier
    

    class VerificationTier(models.TextChoices):
        UNVERIFIED = "unverified", "Unverified"
        PHONE_VERIFIED = "phone_verified", "Phone verified"
        ID_VERIFIED = "id_verified", "ID verified"  # required for land listings

    phone_number = models.CharField(max_length=8, unique=True)
    bidder_number = models.CharField(max_length=20, unique=True, editable=False)
    is_merchant = models.BooleanField(default=False)
    verification_tier = models.CharField(
        max_length=20, choices=VerificationTier.choices, default=VerificationTier.UNVERIFIED
    )
    rating_average = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    rating_count = models.PositiveIntegerField(default=0)

    # Tracked for future use even though there's no enforcement yet (per your call
    # to skip a global strike system for now — the data just shouldn't be lost).
    default_count = models.PositiveIntegerField(default=0)

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = ["username"]

    def save(self, *args, **kwargs):
        if not self.bidder_number:
            # Simple sequential-looking bidder number; swap for something more
            # robust (e.g. zero-padded counter) once you have real registration volume.
            self.bidder_number = f"MZD-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.phone_number} ({self.bidder_number})"


class Wallet(models.Model):
    
    #A user's overall balance. Deposits are carved OUT of this balance per auction

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="wallet")
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    def __str__(self):
        return f"Wallet({self.user.bidder_number}) = {self.balance}"

    def available_balance(self):
        """Balance minus whatever is currently held in active deposits."""
        held = self.user.deposits.filter(status=Deposit.Status.ACTIVE).aggregate(
            total=models.Sum("amount_held")
        )["total"] or 0
        return self.balance - held


class Category(models.Model):
    class Slug(models.TextChoices):
        CARS = "cars", "Used cars"
        LAND = "land", "Land"
        GOODS = "goods", "Commercial goods"

    slug = models.CharField(max_length=20, choices=Slug.choices, unique=True)
    name = models.CharField(max_length=50)
    requires_id_verification = models.BooleanField(default=False)
    listing_fee = models.DecimalField(max_digits=10, decimal_places=2)
    commission_rate = models.DecimalField(max_digits=4, decimal_places=3, default=0.030)

    class Meta:
        verbose_name_plural = "categories"

    def __str__(self):
        return self.name


class Listing(models.Model):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PENDING_PAYMENT = "pending_payment", "Pending listing fee payment"
        SCHEDULED = "scheduled", "Scheduled"
        LIVE = "live", "Live"
        PENDING_SELLER_DECISION = "pending_seller_decision", "Winner defaulted — awaiting seller"
        ENDED_SOLD = "ended_sold", "Ended — sold"
        ENDED_UNSOLD = "ended_unsold", "Ended — unsold"
        CANCELLED = "cancelled", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    seller = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="listings")
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="listings")

    title = models.CharField(max_length=140)
    description = models.TextField()

    starting_price = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(0)])
    # Mandatory everywhere, per your decision — enforced at the serializer/form level
    # (a model-level NOT NULL already does this; no blank=True here on purpose).
    reserve_price = models.DecimalField(max_digits=12, decimal_places=2)
    min_increment = models.DecimalField(max_digits=10, decimal_places=2, default=1000)
    current_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    auction_start = models.DateTimeField()
    auction_end = models.DateTimeField()
    soft_close_window_seconds = models.PositiveIntegerField(default=120)  # 2 minutes for the seller to decide if he want to keep the previous bid

    status = models.CharField(max_length=30, choices=Status.choices, default=Status.DRAFT)
    listing_fee_paid = models.BooleanField(default=False)

    seller_grace_period_ends = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["status", "auction_end"]),
            models.Index(fields=["category", "status"]),
        ]
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.get_status_display()})"

    def is_live(self):
        now = timezone.now()
        return self.status == self.Status.LIVE and self.auction_start <= now <= self.auction_end

    def is_reserve_met(self):
        return self.current_price is not None and self.current_price >= self.reserve_price

    def extend_if_soft_close(self, bid_time):
        """Called every time a valid bid is placed — soft close, 2-min default."""
        window = timezone.timedelta(seconds=self.soft_close_window_seconds)
        if self.auction_end - bid_time <= window:
            self.auction_end = bid_time + window
            self.save(update_fields=["auction_end", "updated_at"])

    def release_deposits(self, exclude_user=None):
        """Release every ACTIVE deposit on this listing, optionally keeping one user's deposit held."""
        qs = Deposit.objects.filter(listing=self, status=Deposit.Status.ACTIVE)
        if exclude_user is not None:
            qs = qs.exclude(user=exclude_user)
        qs.update(status=Deposit.Status.RELEASED)


class ListingImage(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="images")
    image = models.ImageField(upload_to="listings/images/")
    is_primary = models.BooleanField(default=False)
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["order"]


class ListingDocument(models.Model):
    """Supporting docs — vehicle titles, land deeds, etc."""
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="documents")
    file = models.FileField(upload_to="listings/documents/")
    label = models.CharField(max_length=100, help_text="e.g. 'Carte grise', 'Titre foncier'")


class Deposit(models.Model):
    
    #A hold committed by a user for a SPECIFIC listing/auction.
    

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        RELEASED = "released", "Released"
        FORFEITED = "forfeited", "Forfeited"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="deposits")
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="deposits")

    amount_held = models.DecimalField(max_digits=12, decimal_places=2)
    multiplier = models.DecimalField(max_digits=5, decimal_places=2, default=10)  # flat 10x, as decided
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "listing")

    def bid_ceiling(self):
        return self.amount_held * self.multiplier

    def release(self):
        self.status = self.Status.RELEASED
        self.save(update_fields=["status"])

    def forfeit(self):
        """100% to Mazad, no split with the seller."""
        self.status = self.Status.FORFEITED
        self.save(update_fields=["status"])
        self.user.default_count = models.F("default_count") + 1
        self.user.save(update_fields=["default_count"])

    def __str__(self):
        return f"Deposit({self.user.bidder_number} on {self.listing_id}) = {self.amount_held}"


class ListingBan(models.Model):
    """A user banned from bidding on ONE specific listing after defaulting on it"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="listing_bans")
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="bans")
    reason = models.CharField(max_length=200, default="Defaulted on winning bid")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "listing")


class Bid(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="bids")
    bidder = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="bids")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    is_anonymous = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-amount", "created_at"]
        indexes = [models.Index(fields=["listing", "-amount"])]

    def __str__(self):
        return f"{self.amount} on {self.listing_id} by {self.bidder.bidder_number}"


class Sale(models.Model):
    class Status(models.TextChoices):
        PENDING_DECISION = "pending_decision", "Pending seller decision"
        AWAITING_PAYMENT = "awaiting_payment", "Awaiting payment"
        PAID = "paid", "Paid"
        DEFAULTED = "defaulted", "Buyer defaulted"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.OneToOneField(Listing, on_delete=models.CASCADE, related_name="sale")
    buyer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="purchases")
    seller = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="sales")

    final_price = models.DecimalField(max_digits=12, decimal_places=2)
    commission_amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.AWAITING_PAYMENT)

    # 10-minute window for the second-highest bidder to confirm, per your decision.
    second_chance_deadline = models.DateTimeField(null=True, blank=True)

    delivery_address = models.ForeignKey(
        'Address', null=True, blank=True, on_delete=models.SET_NULL, related_name='deliveries'
    )
    shipped_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    tracking_note = models.CharField(max_length=300, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    def compute_commission(self):
        rate = self.listing.category.commission_rate
        return self.final_price * rate

    def mark_paid(self):
        self.status = self.Status.PAID
        self.save(update_fields=["status"])
        Deposit.objects.filter(user=self.buyer, listing=self.listing).update(status=Deposit.Status.RELEASED)

    def mark_defaulted(self):
        self.status = self.Status.DEFAULTED
        self.save(update_fields=["status"])
        deposit = Deposit.objects.filter(user=self.buyer, listing=self.listing).first()
        if deposit:
            deposit.forfeit()
        ListingBan.objects.get_or_create(user=self.buyer, listing=self.listing)


class Address(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='addresses')
    label = models.CharField(max_length=50)
    full_name = models.CharField(max_length=100)
    street = models.CharField(max_length=200)
    city = models.CharField(max_length=100)
    country = models.CharField(max_length=100, default='Mauritania')
    phone = models.CharField(max_length=20)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-is_default', '-created_at']

    def __str__(self):
        return f"{self.label} ({self.user.bidder_number})"


class KYCSubmission(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending review"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="kyc_submissions")
    id_front = models.ImageField(upload_to="kyc/id_front/")
    id_back = models.ImageField(upload_to="kyc/id_back/")
    selfie = models.ImageField(upload_to="kyc/selfie/")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    rejection_reason = models.TextField(blank=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-submitted_at"]

    def __str__(self):
        return f"KYC({self.user.bidder_number}) — {self.get_status_display()}"


class Dispute(models.Model):
    """A buyer or seller flagging a problem with a completed/in-progress sale
    (item not as described, never shipped, payment issue, etc.) for admin review."""

    class Category(models.TextChoices):
        ITEM_NOT_AS_DESCRIBED = "item_not_as_described", "Item not as described"
        ITEM_NOT_RECEIVED = "item_not_received", "Item not received"
        PAYMENT_ISSUE = "payment_issue", "Payment issue"
        SELLER_UNRESPONSIVE = "seller_unresponsive", "Seller unresponsive"
        OTHER = "other", "Other"

    class Status(models.TextChoices):
        OPEN = "open", "Open"
        UNDER_REVIEW = "under_review", "Under review"
        RESOLVED = "resolved", "Resolved"
        DISMISSED = "dismissed", "Dismissed"

    sale = models.ForeignKey(Sale, on_delete=models.CASCADE, related_name="disputes")
    raised_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="disputes_raised")

    category = models.CharField(max_length=30, choices=Category.choices)
    description = models.TextField()
    evidence = models.ImageField(upload_to="disputes/evidence/", blank=True, null=True)

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)
    resolution_note = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def other_party(self):
        return self.sale.seller if self.raised_by_id == self.sale.buyer_id else self.sale.buyer

    def __str__(self):
        return f"Dispute({self.sale_id}) by {self.raised_by.bidder_number} — {self.get_status_display()}"


class Notification(models.Model):
    class Type(models.TextChoices):
        OUTBID = 'outbid', 'Outbid'
        AUCTION_WON = 'auction_won', 'Auction Won'
        AUCTION_SOLD = 'auction_sold', 'Auction Sold'
        AUCTION_PENDING_DECISION = 'auction_pending_decision', 'Auction Pending Decision'
        SECOND_CHANCE_RECEIVED = 'second_chance_received', 'Second Chance Received'
        SECOND_CHANCE_ACCEPTED = 'second_chance_accepted', 'Second Chance Accepted'
        SECOND_CHANCE_EXPIRED = 'second_chance_expired', 'Second Chance Expired'
        ORDER_SHIPPED = 'order_shipped', 'Order Shipped'
        ORDER_RECEIVED = 'order_received', 'Order Received'
        DISPUTE_STATUS_CHANGED = 'dispute_status_changed', 'Dispute Status Changed'
        KYC_DECISION = 'kyc_decision', 'KYC Decision'

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications'
    )
    notification_type = models.CharField(max_length=40, choices=Type.choices)
    title = models.CharField(max_length=200)
    body = models.TextField()
    data = models.JSONField(default=dict)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_notification_type_display()} → {self.recipient.bidder_number}"


class DeviceToken(models.Model):
    class Platform(models.TextChoices):
        ANDROID = 'android', 'Android'
        IOS = 'ios', 'iOS'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='device_tokens'
    )
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=10, choices=Platform.choices)
    created_at = models.DateTimeField(auto_now_add=True)
    last_seen_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.bidder_number} / {self.platform} / {self.token[:20]}…"


class MerchantSubscription(models.Model):
    class Plan(models.TextChoices):
        MONTHLY = "monthly", "Monthly"
        QUARTERLY = "quarterly", "Quarterly"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="subscriptions")
    plan = models.CharField(max_length=20, choices=Plan.choices, default=Plan.MONTHLY)
    price_paid = models.DecimalField(max_digits=10, decimal_places=2)
    start_date = models.DateField()
    end_date = models.DateField()
    is_active = models.BooleanField(default=True)


class FeaturedPlacement(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="featured_placements")
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()

    def is_active(self):
        now = timezone.now()
        return self.start_date <= now <= self.end_date


class Favorite(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='favorites'
    )
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name='favorites')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [('user', 'listing')]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.bidder_number} → {self.listing.title}"