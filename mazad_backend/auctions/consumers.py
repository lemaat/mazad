import json

from asgiref.sync import sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth.models import AnonymousUser


class AuctionConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.listing_id = self.scope["url_route"]["kwargs"]["listing_id"]
        self.group_name = f"auction_{self.listing_id}"
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def auction_update(self, event):
        await self.send(text_data=json.dumps(event["data"]))


class UserNotificationConsumer(AsyncWebsocketConsumer):
    """
    Personal notification stream for a single authenticated user.

    Connect with: ws://<host>/ws/notifications/?token=<api-token>

    The consumer authenticates via the REST API token passed as a query
    parameter (matching the TokenAuthentication used by the REST API).
    """

    async def connect(self):
        from urllib.parse import parse_qs
        qs = parse_qs(self.scope.get('query_string', b'').decode())
        token_key = (qs.get('token') or [None])[0]

        if not token_key:
            await self.close(code=4001)
            return

        user = await self._get_user(token_key)
        if user is None or isinstance(user, AnonymousUser):
            await self.close(code=4001)
            return

        self.user = user
        self.group_name = f'user_{user.pk}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def user_notify(self, event):
        """Handler for 'user.notify' group messages from notifications_service."""
        await self.send(text_data=json.dumps(event['data']))

    @sync_to_async
    def _get_user(self, token_key: str):
        from rest_framework.authtoken.models import Token
        try:
            return Token.objects.select_related('user').get(key=token_key).user
        except Token.DoesNotExist:
            return None
