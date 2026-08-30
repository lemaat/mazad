"""
Time-driven listing status transitions, shared between the
`close_expired_auctions` management command and the API views.

Nothing in this project runs on a schedule by default — Django doesn't
have a built-in cron/beat, and this app never wired one up. That has two
consequences that were being treated as one bug but are actually two:

1. A LIVE listing whose auction_end has passed stays LIVE in the database
   until something calls `run()`. That's the half this file originally
   handled (moved here from the management command, which now just calls
   `run()`).

2. A SCHEDULED listing whose auction_start has passed stays SCHEDULED
   forever — nowhere in the codebase ever set status to LIVE except the
   seed script (hardcoding it on a few demo rows) and test fixtures
   (constructing listings directly with status=LIVE, which is exactly why
   the test suite never caught this: no test exercises the transition
   itself). A real listing created through the sell flow goes
   draft -> pending_payment -> scheduled and then never moves again,
   so it could never actually be bid on. `_start_scheduled_auctions`
   below is the fix for that half.

`run()` is called from `ListingViewSet.get_queryset()` (see views.py) so
that listings self-heal on every read instead of requiring an operator to
remember to run the management command — the cheap `.exists()` guard
there means this only does real work when something is actually overdue.
The management command still exists for scripted/cron use if this project
ever wires up a real scheduler instead.
"""
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction
from django.utils import timezone

from .models import Listing, Notification, Sale
from .notifications_service import notify


def run(stdout=None):
    """Run every time-driven transition once. Safe to call as often as you
    like — each step only touches rows that are actually overdue."""
    now = timezone.now()
    _start_scheduled_auctions(now, stdout)
    _close_live_auctions(now, stdout)
    _expire_second_chance_offers(now, stdout)


def has_pending_work():
    """Cheap existence check so callers on a hot path (like a list view)
    can skip the rest of `run()` when there's nothing to do."""
    now = timezone.now()
    if Listing.objects.filter(status=Listing.Status.SCHEDULED, auction_start__lte=now).exists():
        return True
    if Listing.objects.filter(status=Listing.Status.LIVE, auction_end__lt=now).exists():
        return True
    if Sale.objects.filter(
        status=Sale.Status.PENDING_DECISION,
        second_chance_deadline__isnull=False,
        second_chance_deadline__lt=now,
    ).exists():
        return True
    return False


# ── Starting scheduled auctions ─────────────────────────────────────────────

def _start_scheduled_auctions(now, stdout=None):
    candidate_ids = list(
        Listing.objects.filter(
            status=Listing.Status.SCHEDULED, auction_start__lte=now
        ).values_list("id", flat=True)
    )
    count = 0
    for listing_id in candidate_ids:
        with transaction.atomic():
            listing = Listing.objects.select_for_update().get(pk=listing_id)
            if listing.status != Listing.Status.SCHEDULED or listing.auction_start > timezone.now():
                continue
            listing.status = Listing.Status.LIVE
            listing.save(update_fields=["status"])
        count += 1
    if count and stdout:
        stdout.write(f"Started {count} scheduled auction(s).")


# ── Closing live auctions ───────────────────────────────────────────────────

def _close_live_auctions(now, stdout=None):
    candidate_ids = Listing.objects.filter(
        status=Listing.Status.LIVE, auction_end__lt=now
    ).values_list("id", flat=True)

    channel_layer = get_channel_layer()
    count = 0
    for listing_id in candidate_ids:
        payload = None
        notification_tasks = []

        with transaction.atomic():
            listing = Listing.objects.select_for_update().get(pk=listing_id)

            if listing.status != Listing.Status.LIVE or listing.auction_end >= timezone.now():
                continue

            if listing.is_reserve_met():
                payload, notification_tasks = _close_as_sold(listing, stdout)
            else:
                listing.status = Listing.Status.PENDING_SELLER_DECISION
                listing.seller_grace_period_ends = timezone.now() + timezone.timedelta(hours=24)
                listing.save(update_fields=["status", "seller_grace_period_ends"])
                top_bid = listing.bids.first()
                if top_bid:
                    Sale.objects.create(
                        listing=listing,
                        buyer=top_bid.bidder,
                        seller=listing.seller,
                        final_price=top_bid.amount,
                        commission_amount=top_bid.amount * listing.category.commission_rate,
                        status=Sale.Status.PENDING_DECISION,
                    )
                payload = {
                    "type": "auction_closed",
                    "status": "pending_seller_decision",
                    "winner_bidder_number": top_bid.bidder.bidder_number if top_bid else None,
                    "winning_amount": str(top_bid.amount) if top_bid else None,
                }
                notification_tasks = [(
                    listing.seller,
                    Notification.Type.AUCTION_PENDING_DECISION,
                    'Decision required',
                    f'Your auction for "{listing.title}" ended below reserve. Choose to offer a second chance or end unsold.',
                    {'listing_id': str(listing.id), 'listing_title': listing.title},
                )]

            count += 1

        # Broadcast and notify outside the transaction so DB state is committed.
        if payload:
            async_to_sync(channel_layer.group_send)(
                f"auction_{listing_id}",
                {"type": "auction_update", "data": payload},
            )
        for task in notification_tasks:
            notify(*task)

    if stdout:
        stdout.write(f"Closed {count} expired auction(s).")


def _close_as_sold(listing, stdout=None):
    winning_bid = listing.bids.first()

    if not winning_bid:
        listing.status = Listing.Status.ENDED_UNSOLD
        listing.save(update_fields=["status"])
        return (
            {"type": "auction_closed", "status": "ended_unsold",
             "winner_bidder_number": None, "winning_amount": None},
            [],
        )

    sale = Sale.objects.create(
        listing=listing,
        buyer=winning_bid.bidder,
        seller=listing.seller,
        final_price=winning_bid.amount,
        commission_amount=winning_bid.amount * listing.category.commission_rate,
    )

    listing.status = Listing.Status.ENDED_SOLD
    listing.save(update_fields=["status"])
    listing.release_deposits(exclude_user=winning_bid.bidder)

    if stdout:
        stdout.write(
            f"  -> {listing.title}: sold to {winning_bid.bidder.bidder_number} for {sale.final_price}"
        )

    notification_tasks = [
        (
            winning_bid.bidder,
            Notification.Type.AUCTION_WON,
            'You won the auction!',
            f'Congratulations — you won "{listing.title}" for {sale.final_price} MRU.',
            {
                'listing_id': str(listing.id),
                'listing_title': listing.title,
                'final_price': str(sale.final_price),
            },
        ),
        (
            listing.seller,
            Notification.Type.AUCTION_SOLD,
            'Your item sold!',
            f'"{listing.title}" sold for {sale.final_price} MRU.',
            {
                'listing_id': str(listing.id),
                'listing_title': listing.title,
                'final_price': str(sale.final_price),
            },
        ),
    ]

    return (
        {
            "type": "auction_closed",
            "status": "ended_sold",
            "winner_bidder_number": winning_bid.bidder.bidder_number,
            "winning_amount": str(sale.final_price),
        },
        notification_tasks,
    )


# ── Expired second-chance offers ────────────────────────────────────────────

def _expire_second_chance_offers(now, stdout=None):
    """A second-chance offer nobody accepted within its 10-minute window
    auto-closes the listing as unsold, releasing every deposit — the
    seller already made their call by choosing to offer a second chance
    rather than end it themselves, so leaving it sitting in
    pending_seller_decision indefinitely (waiting on a second decision
    that may never come) just locks deposits with no path forward."""
    expired = list(
        Sale.objects.filter(
            status=Sale.Status.PENDING_DECISION,
            second_chance_deadline__isnull=False,
            second_chance_deadline__lt=now,
        )
        .select_related('seller', 'listing')
    )
    count = 0
    for sale in expired:
        with transaction.atomic():
            listing = Listing.objects.select_for_update().get(pk=sale.listing_id)
            # Re-check under the lock — the seller may have resolved this
            # themselves (End Unsold / the runner-up accepting) between the
            # query above and this loop iteration.
            if listing.status != Listing.Status.PENDING_SELLER_DECISION:
                continue
            listing.status = Listing.Status.ENDED_UNSOLD
            listing.save(update_fields=['status', 'updated_at'])
            listing.release_deposits()
            sale.second_chance_deadline = None
            sale.save(update_fields=['second_chance_deadline'])
        notify(
            recipient=sale.seller,
            notification_type=Notification.Type.SECOND_CHANCE_EXPIRED,
            title='Auction ended unsold',
            body=f'No one took the second-chance offer for "{sale.listing.title}", so it has automatically closed as unsold and all deposits have been released.',
            data={
                'listing_id': str(sale.listing_id),
                'listing_title': sale.listing.title,
            },
        )
        count += 1
    if count and stdout:
        stdout.write(f"Auto-closed {count} expired second-chance offer(s) as unsold.")
