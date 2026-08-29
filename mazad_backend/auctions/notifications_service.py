"""
Central notification helper.

Call notify() from any view, admin action, or management command to:
  1. Persist a Notification row.
  2. Push a real-time event to the user's personal WebSocket group.
  3. Send an FCM push to all registered device tokens.

Push and WebSocket failures are isolated — they never propagate to callers.
"""
import logging

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from .models import DeviceToken, Notification
from .push_service import send_push

logger = logging.getLogger(__name__)


def notify(
    recipient,
    notification_type: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> Notification:
    data = data or {}

    notif = Notification.objects.create(
        recipient=recipient,
        notification_type=notification_type,
        title=title,
        body=body,
        data=data,
    )

    # ── WebSocket ──────────────────────────────────────────────────────────────
    try:
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'user_{recipient.pk}',
            {
                'type': 'user.notify',
                'data': {
                    'id': notif.pk,
                    'notification_type': notification_type,
                    'title': title,
                    'body': body,
                    'data': data,
                    'is_read': False,
                    'created_at': notif.created_at.isoformat(),
                },
            },
        )
    except Exception as exc:
        logger.warning('WebSocket notify failed for user %s: %s', recipient.pk, exc)

    # ── FCM push ───────────────────────────────────────────────────────────────
    tokens = list(DeviceToken.objects.filter(user=recipient).values_list('token', flat=True))
    dead_tokens = send_push(
        tokens,
        title,
        body,
        data={'notification_type': notification_type, **data},
    )
    if dead_tokens:
        DeviceToken.objects.filter(token__in=dead_tokens).delete()

    return notif
