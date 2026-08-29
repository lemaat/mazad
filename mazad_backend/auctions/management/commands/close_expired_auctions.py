from django.core.management.base import BaseCommand

from auctions import auction_lifecycle


class Command(BaseCommand):
    help = (
        "Run every time-driven listing transition once: start any SCHEDULED "
        "auction whose auction_start has passed, close any LIVE auction whose "
        "auction_end has passed, and expire overdue second-chance offers. "
        "The actual logic lives in auctions/auction_lifecycle.py, which "
        "ListingViewSet also calls on read so this doesn't strictly need to "
        "be scheduled — but running it periodically (cron/Task Scheduler) is "
        "still recommended so listings settle even with no API traffic."
    )

    def handle(self, *args, **options):
        auction_lifecycle.run(stdout=self.stdout)
