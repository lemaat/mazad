"""
seed_demo_data — Populate the database with a realistic demo dataset.

Safety guards:
  - Aborts if settings.DEBUG is False.
  - Requires the explicit --i-know-what-im-doing flag.

Usage:
  python manage.py seed_demo_data --i-know-what-im-doing
  python manage.py seed_demo_data --i-know-what-im-doing --clear
"""
import os
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files import File
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from auctions.models import (
    Address,
    Bid,
    Category,
    Deposit,
    Dispute,
    Favorite,
    Listing,
    ListingImage,
    Notification,
    Sale,
    Wallet,
)


_SEED_DIR = os.path.join(os.path.dirname(__file__), 'seed_assets')

# Real JPEG assets available under seed_assets/, kept here purely as an
# inventory reference. Actual listing <-> photo assignment is explicit in
# _LISTING_IMAGES below, not derived from this dict — a listing's title is
# written to match whatever photo it's actually given, rather than handing
# out "next available photo in this category" and hoping it's plausible.
_SEED_IMAGES = {
    'cars': [
        'cars/honda_civic.jpg',
    ],
    'land': [
        'land/aerial_plot.jpg',
        'land/house_property.jpg',
    ],
    'goods': [
        'goods/laptop.jpg',
        'goods/sofa.jpg',
        'goods/guitar.jpg',
        'goods/bistro_table_chairs.jpg',
        'goods/hotel_beds.jpg',
    ],
}

# Explicit listing-key -> photo path(s) map. Every title below was written
# (or rewritten) to describe exactly what the assigned photo shows — no
# listing gets a photo of a different kind of item than its title. Two
# photos are intentionally unused (goods/bistro_table_chairs.jpg,
# goods/hotel_beds.jpg) and 'pending_decision' intentionally has NO photo:
# there's only one real car photo (honda_civic.jpg), it's already used on
# 'live_car', and reusing it on a second, differently-titled car listing
# would recreate the exact "photo doesn't match the title" bug this map
# exists to avoid. An unphotographed listing is honest; a wrong photo isn't.
_LISTING_IMAGES = {
    'live_car': ['cars/honda_civic.jpg'],
    'live_goods': ['goods/sofa.jpg'],
    'scheduled_land': ['land/aerial_plot.jpg'],
    'ended_sold': ['goods/laptop.jpg'],
    'ended_unsold': ['goods/guitar.jpg'],
}

User = get_user_model()

# Phone numbers used by demo accounts — used to scope --clear deletions.
_DEMO_PHONES = ['22001001', '22001002', '22002001', '22002002', '22002003', '22003001']

# How long the two live demo auctions stay live after seeding, and how far in
# the future the scheduled land auction starts. Long enough to cover a full
# week of testing plus the pitch without anything auto-closing. Change this
# one value to shorten or lengthen every demo timing at once.
DEMO_WINDOW_DAYS = 10

# The real second-chance window (matches offer_second_chance in views.py).
# Re-run the seed right before demoing the Nissan second-chance flow: once
# this lapses, auction_lifecycle auto-closes the listing as unsold.
SECOND_CHANCE_MINUTES = 10


class Command(BaseCommand):
    help = "Populate the database with demo data (DEBUG=True only)."

    def add_arguments(self, parser):
        parser.add_argument(
            '--i-know-what-im-doing',
            action='store_true',
            dest='confirmed',
            help='Required acknowledgement — this will mutate the database.',
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Delete existing demo rows before re-seeding (idempotent).',
        )

    def handle(self, *args, **options):
        from django.conf import settings

        if not settings.DEBUG:
            raise CommandError(
                "Refusing to seed: settings.DEBUG is False. "
                "This command must never run against a production database."
            )
        if not options['confirmed']:
            raise CommandError(
                "Pass --i-know-what-im-doing to confirm you want to seed demo data."
            )

        if options['clear']:
            self._clear()

        with transaction.atomic():
            self._seed()

    # ── Clear ─────────────────────────────────────────────────────────────────

    def _clear(self):
        self.stdout.write("Clearing existing demo data...")
        # Wipe every Listing (and everything that cascades from it — bids,
        # deposits, sales, favorites, images, disputes tied to those sales).
        # This is intentionally unscoped rather than filtered to the demo
        # users below: stray/leftover listings from earlier manual testing
        # (e.g. old "L4"/"L5"-style rows) were never created by this script
        # and don't belong to the demo phone numbers, so a user-scoped
        # delete alone silently leaves them behind. Safe because this whole
        # command already refuses to run unless settings.DEBUG is True.
        listing_deleted, listing_breakdown = Listing.objects.all().delete()
        self.stdout.write(f"  Removed {listing_deleted} listing-related objects "
                          f"({listing_breakdown})")
        deleted, breakdown = User.objects.filter(phone_number__in=_DEMO_PHONES).delete()
        self.stdout.write(f"  Removed {deleted} demo-user objects via CASCADE ({breakdown})\n")

    # ── Seed ──────────────────────────────────────────────────────────────────

    def _seed(self):
        now = timezone.now()

        cats = self._seed_categories()
        users = self._seed_users()
        self._seed_addresses(users)
        listings = self._seed_listings(now, users, cats)
        self._seed_listing_images(listings)
        bid_count = self._seed_bids(listings, users)
        deposit_count = self._seed_deposits(listings, users)
        sales = self._seed_sales(now, listings, users, cats)
        fav_count = self._seed_favorites(listings, users)
        dispute_count = self._seed_disputes(sales, users)
        notif_count = self._seed_notifications(listings, sales, users)

        self._print_summary(listings, bid_count, deposit_count, fav_count, dispute_count, notif_count)

    # ── Categories ────────────────────────────────────────────────────────────

    def _seed_categories(self):
        cars, _ = Category.objects.get_or_create(
            slug='cars',
            # Decimal, not str: on a fresh DB get_or_create returns the
            # in-memory instance, and a str rate would make
            # Decimal * commission_rate raise TypeError in _seed_sales.
            defaults=dict(name='Used Cars', listing_fee=Decimal('500.00'),
                          commission_rate=Decimal('0.035'), requires_id_verification=False),
        )
        land, _ = Category.objects.get_or_create(
            slug='land',
            defaults=dict(name='Land', listing_fee=Decimal('1000.00'),
                          commission_rate=Decimal('0.025'), requires_id_verification=True),
        )
        goods, _ = Category.objects.get_or_create(
            slug='goods',
            defaults=dict(name='Commercial Goods', listing_fee=Decimal('200.00'),
                          commission_rate=Decimal('0.030'), requires_id_verification=False),
        )
        self.stdout.write("  Categories : 3 (cars 3.5%, land 2.5%, goods 3.0%)")
        return {'cars': cars, 'land': land, 'goods': goods}

    # ── Users ─────────────────────────────────────────────────────────────────

    def _seed_users(self):
        def _make(phone, username, **kw):
            u, created = User.objects.get_or_create(
                phone_number=phone,
                defaults=dict(username=username, **kw),
            )
            if created:
                u.set_password('demo1234')
                u.save()
            Wallet.objects.get_or_create(user=u, defaults={'balance': '500000.00'})
            return u

        tier = User.VerificationTier
        seller1 = _make('22001001', 'seller_ahmed',
                        is_merchant=True, verification_tier=tier.ID_VERIFIED)
        seller2 = _make('22001002', 'seller_fatma',
                        is_merchant=True, verification_tier=tier.PHONE_VERIFIED)
        buyer1 = _make('22002001', 'buyer_omar',  verification_tier=tier.PHONE_VERIFIED)
        buyer2 = _make('22002002', 'buyer_mariam', verification_tier=tier.PHONE_VERIFIED)
        buyer3 = _make('22002003', 'buyer_ibra',  verification_tier=tier.UNVERIFIED)
        admin  = _make('22003001', 'admin_mazad',
                       is_staff=True, is_superuser=True, verification_tier=tier.ID_VERIFIED)

        self.stdout.write("  Users      : 6 (seller_ahmed, seller_fatma, buyer_omar, "
                          "buyer_mariam, buyer_ibra, admin_mazad) — password: demo1234")
        return dict(seller1=seller1, seller2=seller2,
                    buyer1=buyer1, buyer2=buyer2, buyer3=buyer3, admin=admin)

    # ── Addresses ─────────────────────────────────────────────────────────────

    def _seed_addresses(self, u):
        rows = [
            (u['seller1'], 'Home',   'Rue 42, Tevragh-Zeina',       'Nouakchott', True),
            (u['seller1'], 'Office', 'Ave Gamal Abdel Nasser',       'Nouakchott', False),
            (u['buyer1'],  'Home',   'Quartier Ksar, Bloc C',        'Nouakchott', True),
            (u['buyer2'],  'Home',   "Rue de l'Espoir, Quartier 5",  'Nouadhibou', True),
        ]
        for user, label, street, city, is_default in rows:
            Address.objects.get_or_create(
                user=user, label=label,
                defaults=dict(full_name=user.username, street=street, city=city,
                              country='Mauritania', phone=user.phone_number,
                              is_default=is_default),
            )
        self.stdout.write("  Addresses  : 4")

    # ── Listings ──────────────────────────────────────────────────────────────

    def _seed_listings(self, now, u, cats):
        def _listing(title, defaults):
            obj, _ = Listing.objects.get_or_create(title=title, defaults=defaults)
            return obj

        live_car = _listing('Honda Civic 2018', dict(
            seller=u['seller1'], category=cats['cars'],
            description='Excellent condition, 45,000 km. Full service history. Single owner.',
            starting_price='1500000.00', reserve_price='2000000.00',
            min_increment='10000.00', current_price='1650000.00',
            auction_start=now - timezone.timedelta(hours=2),
            auction_end=now + timezone.timedelta(days=DEMO_WINDOW_DAYS),
            status=Listing.Status.LIVE, listing_fee_paid=True,
        ))

        live_goods = _listing('Canape Salon 3 Places', dict(
            seller=u['seller2'], category=cats['goods'],
            description='Canape 3 places en tissu, tres peu utilise, aucune tache ni dechirure.',
            starting_price='200000.00', reserve_price='350000.00',
            min_increment='5000.00', current_price='310000.00',
            auction_start=now - timezone.timedelta(hours=3),
            auction_end=now + timezone.timedelta(days=DEMO_WINDOW_DAYS),
            status=Listing.Status.LIVE, listing_fee_paid=True,
        ))

        scheduled_land = _listing('Terrain 500m2 — Tevragh-Zeina', dict(
            seller=u['seller1'], category=cats['land'],
            description='Plot 500 sqm in Tevragh-Zeina residential zone. Full title deed.',
            starting_price='5000000.00', reserve_price='7000000.00',
            min_increment='50000.00', current_price=None,
            auction_start=now + timezone.timedelta(days=DEMO_WINDOW_DAYS),
            auction_end=now + timezone.timedelta(days=DEMO_WINDOW_DAYS + 1),
            status=Listing.Status.SCHEDULED, listing_fee_paid=True,
        ))

        pending_decision = _listing('Nissan Patrol 2017 — Project', dict(
            seller=u['seller2'], category=cats['cars'],
            description='Good base for restoration. Engine runs. Body needs work.',
            starting_price='400000.00', reserve_price='800000.00',
            min_increment='10000.00', current_price='520000.00',
            auction_start=now - timezone.timedelta(days=2),
            auction_end=now - timezone.timedelta(hours=12),
            status=Listing.Status.PENDING_SELLER_DECISION, listing_fee_paid=True,
            seller_grace_period_ends=now + timezone.timedelta(hours=12),
        ))

        ended_sold = _listing('MacBook Pro M3 14 pouces', dict(
            seller=u['seller1'], category=cats['goods'],
            description='Barely used, 6-month warranty remaining. All original accessories.',
            starting_price='180000.00', reserve_price='200000.00',
            min_increment='2000.00', current_price='235000.00',
            auction_start=now - timezone.timedelta(days=7),
            auction_end=now - timezone.timedelta(days=6),
            status=Listing.Status.ENDED_SOLD, listing_fee_paid=True,
        ))

        ended_unsold = _listing('Guitare Acoustique - Comme Neuve', dict(
            seller=u['seller2'], category=cats['goods'],
            description='Guitare acoustique, cordes neuves, etat quasi neuf, housse de transport incluse.',
            starting_price='300000.00', reserve_price='500000.00',
            min_increment='5000.00', current_price='340000.00',
            auction_start=now - timezone.timedelta(days=10),
            auction_end=now - timezone.timedelta(days=9),
            status=Listing.Status.ENDED_UNSOLD, listing_fee_paid=True,
        ))

        result = dict(
            live_car=live_car, live_goods=live_goods,
            scheduled_land=scheduled_land, pending_decision=pending_decision,
            ended_sold=ended_sold, ended_unsold=ended_unsold,
        )
        self.stdout.write(f"  Listings   : {len(result)} "
                          "(1 live car, 1 live goods, 1 scheduled, "
                          "1 pending-decision, 1 sold, 1 unsold)")
        return result

    # ── Listing images ────────────────────────────────────────────────────────

    def _seed_listing_images(self, L):
        # Explicit per-listing assignment (see _LISTING_IMAGES above) —
        # each listing's title was written to match exactly what its
        # assigned photo(s) show, so there is no "generator listing shows a
        # laptop" style mismatch. A listing key with no entry in the map
        # (currently 'pending_decision') intentionally gets zero photos
        # rather than reusing another listing's photo under a wrong title.
        total = 0
        for key, listing in L.items():
            if listing.images.exists():
                continue
            paths = _LISTING_IMAGES.get(key, [])
            for j, rel_path in enumerate(paths):
                abs_path = os.path.join(_SEED_DIR, rel_path)
                filename = os.path.basename(rel_path)
                with open(abs_path, 'rb') as f:
                    img = ListingImage(listing=listing, is_primary=(j == 0), order=j)
                    img.image.save(filename, File(f), save=True)
                total += 1
        self.stdout.write(f"  Images     : {total}")

    # ── Bids ──────────────────────────────────────────────────────────────────

    def _seed_bids(self, L, u):
        sequences = [
            (L['live_car'], [
                (u['buyer3'], '1520000.00'),
                (u['buyer1'], '1580000.00'),
                (u['buyer2'], '1620000.00'),
                (u['buyer1'], '1650000.00'),
            ]),
            (L['live_goods'], [
                (u['buyer1'], '250000.00'),
                (u['buyer2'], '280000.00'),
                (u['buyer3'], '295000.00'),
                (u['buyer2'], '310000.00'),
            ]),
            (L['pending_decision'], [
                (u['buyer2'], '480000.00'),
                (u['buyer1'], '510000.00'),
                (u['buyer2'], '520000.00'),
            ]),
            (L['ended_sold'], [
                (u['buyer2'], '190000.00'),
                (u['buyer3'], '210000.00'),
                (u['buyer1'], '220000.00'),
                (u['buyer2'], '235000.00'),
            ]),
            (L['ended_unsold'], [
                (u['buyer1'], '320000.00'),
                (u['buyer3'], '340000.00'),
            ]),
        ]
        count = 0
        for listing, bids in sequences:
            for bidder, amount in bids:
                Bid.objects.get_or_create(
                    listing=listing, bidder=bidder, amount=Decimal(amount),
                )
                count += 1
        self.stdout.write(f"  Bids       : {count}")
        return count

    # ── Deposits ──────────────────────────────────────────────────────────────

    def _seed_deposits(self, L, u):
        rows = [
            # Live car — active, bid ceiling covers current leader
            (u['buyer1'], L['live_car'],        '165000.00', Deposit.Status.ACTIVE),
            (u['buyer2'], L['live_car'],        '162000.00', Deposit.Status.ACTIVE),
            (u['buyer3'], L['live_car'],        '152000.00', Deposit.Status.ACTIVE),
            # Live goods — active
            (u['buyer1'], L['live_goods'],       '31000.00', Deposit.Status.ACTIVE),
            (u['buyer2'], L['live_goods'],       '31000.00', Deposit.Status.ACTIVE),
            (u['buyer3'], L['live_goods'],       '29500.00', Deposit.Status.ACTIVE),
            # Pending decision — held until seller decides
            (u['buyer1'], L['pending_decision'], '52000.00', Deposit.Status.ACTIVE),
            (u['buyer2'], L['pending_decision'], '52000.00', Deposit.Status.ACTIVE),
            # Ended sold — sale is PAID, and Sale.mark_paid() releases the
            # winner's deposit, so all three are released
            (u['buyer2'], L['ended_sold'],       '23500.00', Deposit.Status.RELEASED),
            (u['buyer1'], L['ended_sold'],       '22000.00', Deposit.Status.RELEASED),
            (u['buyer3'], L['ended_sold'],       '21000.00', Deposit.Status.RELEASED),
            # Ended unsold — all released
            (u['buyer1'], L['ended_unsold'],     '32000.00', Deposit.Status.RELEASED),
            (u['buyer3'], L['ended_unsold'],     '34000.00', Deposit.Status.RELEASED),
        ]
        count = 0
        for buyer, listing, amount, status in rows:
            Deposit.objects.get_or_create(
                user=buyer, listing=listing,
                defaults=dict(amount_held=Decimal(amount), status=status),
            )
            count += 1
        self.stdout.write(f"  Deposits   : {count}")
        return count

    # ── Sales ─────────────────────────────────────────────────────────────────

    def _seed_sales(self, now, L, u, cats):
        # Mirrors the state right after the seller calls offer_second_chance:
        # the Sale still records the original top bidder (buyer2 @ 520k) —
        # accept_second_chance is what swaps in the runner-up (buyer1 @ 510k,
        # derived from the bids) — and only the deadline is set.
        pending_sale, _ = Sale.objects.get_or_create(
            listing=L['pending_decision'],
            defaults=dict(
                buyer=u['buyer2'],
                seller=u['seller2'],
                final_price=Decimal('520000.00'),
                commission_amount=Decimal('520000.00') * cats['cars'].commission_rate,
                status=Sale.Status.PENDING_DECISION,
                second_chance_deadline=now + timezone.timedelta(minutes=SECOND_CHANCE_MINUTES),
            ),
        )

        # Full happy path up to delivery: paid -> address set -> shipped ->
        # received. mark_shipped requires PAID + a delivery address, so the
        # old AWAITING_PAYMENT-but-shipped combination was impossible.
        buyer2_home = Address.objects.get(user=u['buyer2'], label='Home')
        sold_sale, _ = Sale.objects.get_or_create(
            listing=L['ended_sold'],
            defaults=dict(
                buyer=u['buyer2'],
                seller=u['seller1'],
                final_price=Decimal('235000.00'),
                commission_amount=Decimal('235000.00') * cats['goods'].commission_rate,
                status=Sale.Status.PAID,
                delivery_address=buyer2_home,
                shipped_at=now - timezone.timedelta(days=3),
                delivered_at=now - timezone.timedelta(days=1),
                tracking_note='DHL Express — MR12345678',
            ),
        )

        self.stdout.write("  Sales      : 2 (1 second-chance offered to runner-up, "
                          "1 paid, shipped and delivered)")
        return dict(pending=pending_sale, sold=sold_sale)

    # ── Favorites ─────────────────────────────────────────────────────────────

    def _seed_favorites(self, L, u):
        pairs = [
            (u['buyer1'], L['live_car']),
            (u['buyer1'], L['scheduled_land']),
            (u['buyer2'], L['live_car']),
            (u['buyer2'], L['live_goods']),
            (u['buyer3'], L['live_goods']),
        ]
        for user, listing in pairs:
            Favorite.objects.get_or_create(user=user, listing=listing)
        self.stdout.write(f"  Favorites  : {len(pairs)}")
        return len(pairs)

    # ── Disputes ──────────────────────────────────────────────────────────────

    def _seed_disputes(self, sales, u):
        Dispute.objects.get_or_create(
            sale=sales['sold'],
            raised_by=u['buyer2'],
            defaults=dict(
                category=Dispute.Category.ITEM_NOT_AS_DESCRIBED,
                description=(
                    'The MacBook has a dead pixel cluster in the lower-right corner '
                    'that was not mentioned in the listing.'
                ),
                status=Dispute.Status.UNDER_REVIEW,
            ),
        )
        self.stdout.write("  Disputes   : 1 (under_review)")
        return 1

    # ── Notifications ─────────────────────────────────────────────────────────

    def _seed_notifications(self, L, sales, u):
        T = Notification.Type
        rows = [
            (u['buyer1'], T.OUTBID,
             "You've been outbid",
             f'Someone placed a higher bid on "{L["live_car"].title}". Raise your bid to stay in.',
             {'listing_id': str(L['live_car'].id)}, False),

            (u['buyer2'], T.AUCTION_WON,
             "You won the auction!",
             f'Congratulations — you won "{L["ended_sold"].title}" for 235,000 MRU.',
             {'listing_id': str(L['ended_sold'].id), 'final_price': '235000.00'}, True),

            (u['seller1'], T.AUCTION_SOLD,
             "Your item sold!",
             f'"{L["ended_sold"].title}" sold for 235,000 MRU.',
             {'listing_id': str(L['ended_sold'].id), 'final_price': '235000.00'}, True),

            (u['seller2'], T.AUCTION_PENDING_DECISION,
             "Decision required",
             f'Your auction for "{L["pending_decision"].title}" ended below reserve. '
             'Choose to offer a second chance or end unsold.',
             # Read: the seller already acted on it by offering a second chance.
             {'listing_id': str(L['pending_decision'].id)}, True),

            # Goes to the runner-up (buyer1 @ 510k), with the same title/body
            # and data keys offer_second_chance sends in views.py.
            (u['buyer1'], T.SECOND_CHANCE_RECEIVED,
             "Second chance offer!",
             f'You\'ve been offered a second chance on "{L["pending_decision"].title}". '
             f'Expires in {SECOND_CHANCE_MINUTES} minutes.',
             {'listing_id': str(L['pending_decision'].id),
              'listing_title': L['pending_decision'].title,
              'offer_price': '510000.00',
              'deadline': sales['pending'].second_chance_deadline.isoformat()}, False),

            (u['buyer2'], T.DISPUTE_STATUS_CHANGED,
             "Dispute update",
             'Your dispute is now under review. Our team will contact you within 48 hours.',
             {'sale_id': str(sales['sold'].id)}, False),

            # buyer2 won the MacBook, so the shipping notice is theirs.
            (u['buyer2'], T.ORDER_SHIPPED,
             "Your order has been shipped",
             'The seller shipped your item. Tracking: DHL Express — MR12345678.',
             {'sale_id': str(sales['sold'].id)}, False),
        ]
        count = 0
        for recipient, ntype, title, body, data, is_read in rows:
            Notification.objects.get_or_create(
                recipient=recipient, notification_type=ntype, title=title,
                defaults=dict(body=body, data=data, is_read=is_read),
            )
            count += 1
        self.stdout.write(f"  Notifications: {count}")
        return count

    # ── Summary ───────────────────────────────────────────────────────────────

    def _print_summary(self, listings, bid_count, deposit_count, fav_count, dispute_count, notif_count):
        self.stdout.write(self.style.SUCCESS("\nDemo data seeded successfully!\n"))
        self.stdout.write("  Account       Phone      Password")
        self.stdout.write("  " + "-" * 38)
        accounts = [
            ('seller_ahmed',  '22001001'),
            ('seller_fatma',  '22001002'),
            ('buyer_omar',    '22002001'),
            ('buyer_mariam',  '22002002'),
            ('buyer_ibra',    '22002003'),
            ('admin_mazad',   '22003001'),
        ]
        for name, phone in accounts:
            self.stdout.write(f"  {name:<15} {phone}  demo1234")
        self.stdout.write("")
        self.stdout.write(f"  Listings      : {len(listings)}")
        self.stdout.write(f"  Bids          : {bid_count}")
        self.stdout.write(f"  Deposits      : {deposit_count}")
        self.stdout.write(f"  Favorites     : {fav_count}")
        self.stdout.write(f"  Disputes      : {dispute_count}")
        self.stdout.write(f"  Notifications : {notif_count}")
