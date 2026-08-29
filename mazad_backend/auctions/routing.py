from django.urls import re_path

from .consumers import AuctionConsumer, UserNotificationConsumer

websocket_urlpatterns = [
    re_path(r'ws/auctions/(?P<listing_id>[0-9a-f-]+)/$', AuctionConsumer.as_asgi()),
    re_path(r'ws/notifications/$', UserNotificationConsumer.as_asgi()),
]
