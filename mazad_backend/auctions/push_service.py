"""
Firebase Cloud Messaging helper.

Reads FIREBASE_CREDENTIALS env var (path to a service account JSON).
No-ops with a log line if it's not set, so the rest of the app works
in dev without Firebase credentials present.
"""
import logging
import os

logger = logging.getLogger(__name__)

_initialized = False
_app = None


def _firebase_app():
    global _initialized, _app
    if _initialized:
        return _app
    _initialized = True

    creds_path = os.environ.get('FIREBASE_CREDENTIALS')
    if not creds_path:
        logger.info(
            'FIREBASE_CREDENTIALS env var not set — push notifications are disabled.'
        )
        return None

    try:
        import firebase_admin
        from firebase_admin import credentials
        cred = credentials.Certificate(creds_path)
        _app = firebase_admin.initialize_app(cred)
        logger.info('Firebase Admin SDK initialised.')
    except Exception as exc:
        logger.warning('Firebase Admin SDK initialisation failed: %s', exc)
        _app = None

    return _app


def send_push(tokens: list[str], title: str, body: str, data: dict | None = None) -> list[str]:
    """
    Send a push to each FCM token in *tokens*.

    Returns a list of tokens that are dead (UNREGISTERED / INVALID_ARGUMENT)
    so the caller can prune them from the database.

    Never raises — push failures are logged and swallowed so the underlying
    business action (bid placement, order update, etc.) is never broken.
    """
    if not tokens:
        return []

    app = _firebase_app()
    if app is None:
        logger.debug('Push skipped (Firebase not configured): %s — %s', title, body)
        return []

    try:
        from firebase_admin import messaging

        str_data = {k: str(v) for k, v in (data or {}).items()}

        messages = [
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=str_data,
                token=token,
            )
            for token in tokens
        ]

        batch = messaging.send_each(messages, app=app)

        dead: list[str] = []
        for token, resp in zip(tokens, batch.responses):
            if resp.success:
                continue
            exc = resp.exception
            if exc is not None and isinstance(exc, (
                messaging.UnregisteredError,
                messaging.SenderIdMismatchError,
            )):
                dead.append(token)
            else:
                logger.warning(
                    'FCM push failed for token …%s: %s', token[-8:], exc
                )
        return dead

    except Exception as exc:
        logger.warning('FCM batch send failed: %s', exc)
        return []
