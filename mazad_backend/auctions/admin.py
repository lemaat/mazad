from django.contrib import admin
from django.utils import timezone

from .models import (
    Bid, Category, Deposit, DeviceToken, Dispute, Favorite, FeaturedPlacement, KYCSubmission, Listing,
    ListingBan, ListingDocument, ListingImage, MerchantSubscription, Notification,
    Sale, User, Wallet,
)
from .notifications_service import notify

admin.site.register(User)
admin.site.register(Wallet)
admin.site.register(Category)
admin.site.register(Listing)
admin.site.register(ListingImage)
admin.site.register(ListingDocument)
admin.site.register(Deposit)
admin.site.register(ListingBan)
admin.site.register(Bid)
admin.site.register(Sale)
admin.site.register(MerchantSubscription)
admin.site.register(FeaturedPlacement)


@admin.action(description="Approve selected KYC submissions")
def approve_kyc(modeladmin, request, queryset):
    now = timezone.now()
    for sub in queryset.select_related("user").filter(status=KYCSubmission.Status.PENDING):
        sub.status = KYCSubmission.Status.APPROVED
        sub.reviewed_at = now
        sub.save(update_fields=["status", "reviewed_at"])
        sub.user.verification_tier = User.VerificationTier.ID_VERIFIED
        sub.user.save(update_fields=["verification_tier"])
        notify(
            recipient=sub.user,
            notification_type=Notification.Type.KYC_DECISION,
            title='Identity verified',
            body='Your ID verification has been approved. You can now list Land properties.',
            data={'status': 'approved'},
        )


@admin.action(description="Reject selected KYC submissions")
def reject_kyc(modeladmin, request, queryset):
    now = timezone.now()
    for sub in queryset.select_related("user").filter(status=KYCSubmission.Status.PENDING):
        sub.status = KYCSubmission.Status.REJECTED
        sub.reviewed_at = now
        sub.save(update_fields=["status", "reviewed_at"])
        notify(
            recipient=sub.user,
            notification_type=Notification.Type.KYC_DECISION,
            title='Verification not approved',
            body=sub.rejection_reason or 'Your ID verification was not approved. Please resubmit with clearer photos.',
            data={'status': 'rejected', 'rejection_reason': sub.rejection_reason},
        )


@admin.register(KYCSubmission)
class KYCSubmissionAdmin(admin.ModelAdmin):
    list_display = ["user", "status", "submitted_at", "reviewed_at", "rejection_reason"]
    list_filter = ["status"]
    list_editable = ["rejection_reason"]
    readonly_fields = ["user", "id_front", "id_back", "selfie", "submitted_at"]
    actions = [approve_kyc, reject_kyc]


@admin.action(description="Mark selected disputes as resolved")
def resolve_disputes(modeladmin, request, queryset):
    now = timezone.now()
    for dispute in (
        queryset.exclude(status=Dispute.Status.RESOLVED)
        .select_related('raised_by', 'sale__buyer', 'sale__seller', 'sale__listing')
    ):
        dispute.status = Dispute.Status.RESOLVED
        dispute.resolved_at = now
        dispute.save(update_fields=['status', 'resolved_at'])
        for recipient in {dispute.raised_by, dispute.other_party()}:
            notify(
                recipient=recipient,
                notification_type=Notification.Type.DISPUTE_STATUS_CHANGED,
                title='Dispute resolved',
                body=f'Your dispute regarding "{dispute.sale.listing.title}" has been resolved.',
                data={
                    'dispute_id': dispute.pk,
                    'listing_id': str(dispute.sale.listing_id),
                    'listing_title': dispute.sale.listing.title,
                    'new_status': Dispute.Status.RESOLVED,
                },
            )


@admin.action(description="Dismiss selected disputes")
def dismiss_disputes(modeladmin, request, queryset):
    now = timezone.now()
    for dispute in (
        queryset.exclude(status=Dispute.Status.DISMISSED)
        .select_related('raised_by', 'sale__buyer', 'sale__seller', 'sale__listing')
    ):
        dispute.status = Dispute.Status.DISMISSED
        dispute.resolved_at = now
        dispute.save(update_fields=['status', 'resolved_at'])
        for recipient in {dispute.raised_by, dispute.other_party()}:
            notify(
                recipient=recipient,
                notification_type=Notification.Type.DISPUTE_STATUS_CHANGED,
                title='Dispute dismissed',
                body=f'The dispute regarding "{dispute.sale.listing.title}" has been dismissed.',
                data={
                    'dispute_id': dispute.pk,
                    'listing_id': str(dispute.sale.listing_id),
                    'listing_title': dispute.sale.listing.title,
                    'new_status': Dispute.Status.DISMISSED,
                },
            )


@admin.register(Dispute)
class DisputeAdmin(admin.ModelAdmin):
    list_display = ["sale", "raised_by", "category", "status", "created_at", "resolved_at"]
    list_filter = ["status", "category"]
    readonly_fields = ["sale", "raised_by", "category", "description", "evidence", "created_at"]
    fields = ["sale", "raised_by", "category", "description", "evidence", "status", "resolution_note", "created_at", "resolved_at"]
    actions = [resolve_disputes, dismiss_disputes]


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["recipient", "notification_type", "title", "is_read", "created_at"]
    list_filter = ["notification_type", "is_read"]
    readonly_fields = ["recipient", "notification_type", "title", "body", "data", "created_at"]
    ordering = ["-created_at"]


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ["user", "platform", "last_seen_at", "created_at"]
    list_filter = ["platform"]
    readonly_fields = ["user", "token", "platform", "created_at", "last_seen_at"]


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ["user", "listing", "created_at"]
    list_filter = ["listing__category"]
    readonly_fields = ["user", "listing", "created_at"]
