from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    AddressViewSet, CategoryViewSet, DepositViewSet, FavoriteListView, KYCView,
    ListingViewSet, LoginView, MarkAllReadView, MarkReadView,
    MyBidListView, MyDisputesListView, NotificationListView,
    RegisterDeviceView, RegisterView, UnreadCountView, UnregisterDeviceView,
    WalletView,
)

router = DefaultRouter()
router.register("categories", CategoryViewSet, basename="category")
router.register("listings", ListingViewSet, basename="listing")
router.register("deposits", DepositViewSet, basename="deposit")
router.register("addresses", AddressViewSet, basename="address")

urlpatterns = router.urls + [
    path("wallet/", WalletView.as_view(), name="wallet"),
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("bids/mine/", MyBidListView.as_view(), name="my-bids"),
    path("kyc/", KYCView.as_view(), name="kyc"),
    path("disputes/mine/", MyDisputesListView.as_view(), name="my-disputes"),
    # ── Favorites ─────────────────────────────────────────────────────────────
    path("favorites/", FavoriteListView.as_view(), name="favorites"),
    # ── Notifications ──────────────────────────────────────────────────────────
    path("notifications/", NotificationListView.as_view(), name="notifications"),
    path("notifications/unread_count/", UnreadCountView.as_view(), name="notifications-unread"),
    path("notifications/<int:pk>/mark_read/", MarkReadView.as_view(), name="notifications-mark-read"),
    path("notifications/mark_all_read/", MarkAllReadView.as_view(), name="notifications-mark-all-read"),
    path("notifications/register_device/", RegisterDeviceView.as_view(), name="register-device"),
    path("notifications/unregister_device/", UnregisterDeviceView.as_view(), name="unregister-device"),
]
