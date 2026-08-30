from decimal import Decimal
from unittest import mock

from django.core.management import call_command
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import Bid, Category, Deposit, Favorite, Listing, Sale, Wallet


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def _make_user(model, phone, username):
    return model.objects.create_user(
        phone_number=phone,
        username=username,
        password='testpass',
    )


def _patch_view_ws():
    """Context manager: silence WebSocket broadcasts in views.py.

    ListingViewSet.get_queryset() also self-heals overdue listings via
    auction_lifecycle.run() (see that module's docstring), which does its
    own separate WebSocket broadcast when it closes something — patch that
    module too so a test that happens to leave an overdue listing lying
    around doesn't make a real channel-layer call as a side effect of an
    unrelated GET.
    """
    from contextlib import ExitStack

    def _patcher():
        stack = ExitStack()
        stack.enter_context(mock.patch.multiple(
            'auctions.views', get_channel_layer=mock.DEFAULT, async_to_sync=mock.DEFAULT,
        ))
        stack.enter_context(mock.patch.multiple(
            'auctions.auction_lifecycle', get_channel_layer=mock.DEFAULT, async_to_sync=mock.DEFAULT,
        ))
        return stack

    return _patcher()


def _run_close_command():
    """Run close_expired_auctions with WebSocket IO mocked out.

    The actual transition logic lives in auctions/auction_lifecycle.py (the
    management command just calls it — see that module's docstring for why:
    ListingViewSet.get_queryset() calls the same function on read), so the
    WebSocket calls to mock out live there now, not on the command module.
    """
    with mock.patch('auctions.auction_lifecycle.get_channel_layer') as ml:
        ml.return_value = mock.MagicMock()
        with mock.patch('auctions.auction_lifecycle.async_to_sync', return_value=lambda *a, **kw: None):
            call_command('close_expired_auctions', verbosity=0)


def _base_listing_kwargs(category, seller, *, reserve, current_price, status):
    return dict(
        seller=seller,
        category=category,
        title='Test Item',
        description='.',
        starting_price='1000.00',
        reserve_price=str(reserve),
        min_increment='100.00',
        current_price=str(current_price),
        auction_start=timezone.now() - timezone.timedelta(hours=2),
        auction_end=timezone.now() - timezone.timedelta(seconds=30),
        listing_fee_paid=True,
        status=status,
    )


# ---------------------------------------------------------------------------
# end_unsold — deposit release
# ---------------------------------------------------------------------------

class DepositReleaseOnEndUnsoldTest(APITestCase):
    """
    Verifies that end_unsold releases every ACTIVE deposit on the listing.
    These tests create the listing directly in PENDING_SELLER_DECISION so they
    are not coupled to the close_expired_auctions path.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='goods', name='Commercial goods',
            listing_fee='100.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '20000001', 'seller_eu')
        self.bidder1 = _make_user(User, '20000002', 'b1_eu')
        self.bidder2 = _make_user(User, '20000003', 'b2_eu')

        for u in (self.seller, self.bidder1, self.bidder2):
            Wallet.objects.create(user=u, balance='10000.00')

        self.listing = Listing.objects.create(**_base_listing_kwargs(
            self.category, self.seller,
            reserve='5000.00', current_price='2000.00',
            status=Listing.Status.PENDING_SELLER_DECISION,
        ))
        Bid.objects.create(listing=self.listing, bidder=self.bidder1, amount='2000.00')
        Bid.objects.create(listing=self.listing, bidder=self.bidder2, amount='1500.00')

        self.deposit1 = Deposit.objects.create(
            user=self.bidder1, listing=self.listing, amount_held='200.00',
        )
        self.deposit2 = Deposit.objects.create(
            user=self.bidder2, listing=self.listing, amount_held='150.00',
        )

        self.seller_token = Token.objects.create(user=self.seller)

    def test_end_unsold_releases_all_deposits(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.seller_token.key}')
        response = self.client.post(f'/api/listings/{self.listing.id}/end_unsold/')

        self.assertEqual(response.status_code, 200, response.data)
        self.deposit1.refresh_from_db()
        self.deposit2.refresh_from_db()
        self.assertEqual(self.deposit1.status, Deposit.Status.RELEASED)
        self.assertEqual(self.deposit2.status, Deposit.Status.RELEASED)

    def test_end_unsold_listing_status(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.seller_token.key}')
        self.client.post(f'/api/listings/{self.listing.id}/end_unsold/')
        self.listing.refresh_from_db()
        self.assertEqual(self.listing.status, Listing.Status.ENDED_UNSOLD)


# ---------------------------------------------------------------------------
# PENDING_SELLER_DECISION full flow
# ---------------------------------------------------------------------------

class PendingSellerDecisionFlowTest(APITestCase):
    """
    Tests for offer_second_chance and accept_second_chance using the *real*
    close_expired_auctions path so that the provisional-Sale creation is part
    of what's under test, not a hand-rolled stub.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='cars', name='Used cars',
            listing_fee='500.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '30000001', 'seller_psd')
        self.bidder1 = _make_user(User, '30000002', 'b1_psd')   # top bidder
        self.bidder2 = _make_user(User, '30000003', 'b2_psd')   # runner-up

        for u in (self.seller, self.bidder1, self.bidder2):
            Wallet.objects.create(user=u, balance='50000.00')

        # Listing is LIVE and has just expired — reserve not met
        self.listing = Listing.objects.create(**_base_listing_kwargs(
            self.category, self.seller,
            reserve='10000.00', current_price='3000.00',
            status=Listing.Status.LIVE,
        ))
        # bidder1 is the top bidder (3000), bidder2 is the runner-up (2000)
        Bid.objects.create(listing=self.listing, bidder=self.bidder1, amount='3000.00')
        Bid.objects.create(listing=self.listing, bidder=self.bidder2, amount='2000.00')

        self.deposit1 = Deposit.objects.create(
            user=self.bidder1, listing=self.listing, amount_held='300.00',
        )
        self.deposit2 = Deposit.objects.create(
            user=self.bidder2, listing=self.listing, amount_held='200.00',
        )

        self.seller_token = Token.objects.create(user=self.seller)
        self.bidder2_token = Token.objects.create(user=self.bidder2)

        # Silence WS broadcasts from views throughout this test class
        ws_patcher = mock.patch.multiple(
            'auctions.views',
            get_channel_layer=mock.MagicMock(return_value=mock.MagicMock()),
            async_to_sync=mock.MagicMock(return_value=lambda *a, **kw: None),
        )
        ws_patcher.start()
        self.addCleanup(ws_patcher.stop)

        # Drive the listing to PENDING_SELLER_DECISION via the real command
        _run_close_command()
        self.listing.refresh_from_db()

    # ------------------------------------------------------------------
    # Verify the provisional Sale is created correctly
    # ------------------------------------------------------------------

    def test_close_creates_pending_decision_sale(self):
        self.assertEqual(self.listing.status, Listing.Status.PENDING_SELLER_DECISION)
        sale = self.listing.sale  # must not raise RelatedObjectDoesNotExist
        self.assertEqual(sale.status, Sale.Status.PENDING_DECISION)
        self.assertEqual(sale.buyer, self.bidder1)
        self.assertEqual(sale.final_price, Decimal('3000.00'))

    def test_close_provisional_sale_commission(self):
        sale = self.listing.sale
        self.assertEqual(sale.commission_amount, Decimal('3000.00') * Decimal('0.030'))

    # ------------------------------------------------------------------
    # offer_second_chance
    # ------------------------------------------------------------------

    def test_offer_second_chance_sets_deadline(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.seller_token.key}')
        response = self.client.post(f'/api/listings/{self.listing.id}/offer_second_chance/')

        self.assertEqual(response.status_code, 200, response.data)
        sale = self.listing.sale
        sale.refresh_from_db()
        self.assertIsNotNone(sale.second_chance_deadline)
        self.assertGreater(sale.second_chance_deadline, timezone.now())

    def test_offer_second_chance_response_contains_runner_up(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.seller_token.key}')
        response = self.client.post(f'/api/listings/{self.listing.id}/offer_second_chance/')

        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data['runner_up_bidder_number'], self.bidder2.bidder_number)
        self.assertEqual(Decimal(response.data['amount']), Decimal('2000.00'))

    def test_offer_second_chance_forbidden_for_non_seller(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        response = self.client.post(f'/api/listings/{self.listing.id}/offer_second_chance/')
        self.assertEqual(response.status_code, 403)

    # ------------------------------------------------------------------
    # accept_second_chance — deposit release
    # ------------------------------------------------------------------

    def _offer(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.seller_token.key}')
        r = self.client.post(f'/api/listings/{self.listing.id}/offer_second_chance/')
        self.assertEqual(r.status_code, 200, r.data)

    def test_accept_second_chance_keeps_runner_up_deposit_active(self):
        self._offer()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        response = self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')

        self.assertEqual(response.status_code, 200, response.data)
        self.deposit2.refresh_from_db()
        self.assertEqual(
            self.deposit2.status, Deposit.Status.ACTIVE,
            "New buyer's deposit must stay ACTIVE until they confirm payment.",
        )

    def test_accept_second_chance_releases_top_bidder_deposit(self):
        self._offer()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')

        self.deposit1.refresh_from_db()
        self.assertEqual(
            self.deposit1.status, Deposit.Status.RELEASED,
            "Passed-over top bidder's deposit must be released.",
        )

    def test_accept_second_chance_sale_becomes_awaiting_payment(self):
        self._offer()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')

        sale = self.listing.sale
        sale.refresh_from_db()
        self.assertEqual(sale.status, Sale.Status.AWAITING_PAYMENT)
        self.assertEqual(sale.buyer, self.bidder2)
        self.assertEqual(sale.final_price, Decimal('2000.00'))

    def test_accept_second_chance_releases_third_bidder_deposit(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        bidder3 = _make_user(User, '30000004', 'b3_psd')
        Wallet.objects.create(user=bidder3, balance='10000.00')
        Bid.objects.create(listing=self.listing, bidder=bidder3, amount='900.00')
        deposit3 = Deposit.objects.create(
            user=bidder3, listing=self.listing, amount_held='90.00',
        )

        self._offer()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')

        deposit3.refresh_from_db()
        self.assertEqual(deposit3.status, Deposit.Status.RELEASED)

    def test_accept_second_chance_without_offer_is_rejected(self):
        """accept_second_chance must fail if no offer has been made (deadline is None)."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        response = self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')
        self.assertEqual(response.status_code, 400)


# ---------------------------------------------------------------------------
# Deposit bid ceiling
# ---------------------------------------------------------------------------

class DepositBidCeilingTest(APITestCase):
    """
    bid_ceiling() = amount_held * multiplier (default 10).
    A bid at exactly the ceiling is accepted; one cent over is rejected.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='goods', name='Commercial goods',
            listing_fee='100.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '40000001', 'seller_ceil')
        self.bidder = _make_user(User, '40000002', 'bidder_ceil')
        for u in (self.seller, self.bidder):
            Wallet.objects.create(user=u, balance='999999.00')

        now = timezone.now()
        self.listing = Listing.objects.create(
            seller=self.seller, category=self.category,
            title='Ceiling Test', description='.',
            starting_price='1000.00', reserve_price='5000.00',
            min_increment='100.00', current_price='1000.00',
            auction_start=now - timezone.timedelta(hours=1),
            auction_end=now + timezone.timedelta(hours=1),
            listing_fee_paid=True, status=Listing.Status.LIVE,
        )
        # amount_held=1000, multiplier=10 (default) → ceiling=10000
        Deposit.objects.create(
            user=self.bidder, listing=self.listing, amount_held='1000.00',
        )
        self.bidder_token = Token.objects.create(user=self.bidder)

    def _place_bid(self, amount_str):
        with _patch_view_ws():
            self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder_token.key}')
            return self.client.post(
                f'/api/listings/{self.listing.id}/place_bid/',
                {'amount': amount_str},
                format='json',
            )

    def test_bid_at_ceiling_accepted(self):
        response = self._place_bid('10000.00')
        self.assertEqual(response.status_code, 201, response.data)

    def test_bid_above_ceiling_rejected(self):
        response = self._place_bid('10000.01')
        self.assertEqual(response.status_code, 400)
        self.assertIn('ceiling', response.data.get('detail', '').lower())


# ---------------------------------------------------------------------------
# Reserve price — enforcement and non-leakage
# ---------------------------------------------------------------------------

class ReservePriceEnforcementTest(APITestCase):
    """
    At or above reserve → ended_sold after the close command.
    Below reserve → pending_seller_decision.
    Reserve must not appear in buyer-facing detail responses.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='goods', name='Commercial goods',
            listing_fee='100.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '41000001', 'seller_res')
        self.buyer  = _make_user(User, '41000002', 'buyer_res')
        for u in (self.seller, self.buyer):
            Wallet.objects.create(user=u, balance='999999.00')

        base = dict(
            seller=self.seller, category=self.category,
            description='.', starting_price='1000.00', min_increment='100.00',
            auction_start=timezone.now() - timezone.timedelta(hours=2),
            auction_end=timezone.now() - timezone.timedelta(seconds=30),
            listing_fee_paid=True, status=Listing.Status.LIVE,
        )
        self.at_reserve = Listing.objects.create(
            title='At Reserve', reserve_price='5000.00', current_price='5000.00', **base
        )
        Bid.objects.create(listing=self.at_reserve, bidder=self.buyer, amount='5000.00')

        self.below_reserve = Listing.objects.create(
            title='Below Reserve', reserve_price='5000.00', current_price='3000.00', **base
        )
        Bid.objects.create(listing=self.below_reserve, bidder=self.buyer, amount='3000.00')

        self.seller_token = Token.objects.create(user=self.seller)
        self.buyer_token  = Token.objects.create(user=self.buyer)

    def test_at_reserve_closes_as_sold(self):
        _run_close_command()
        self.at_reserve.refresh_from_db()
        self.assertEqual(self.at_reserve.status, Listing.Status.ENDED_SOLD)

    def test_below_reserve_pending_seller_decision(self):
        _run_close_command()
        self.below_reserve.refresh_from_db()
        self.assertEqual(self.below_reserve.status, Listing.Status.PENDING_SELLER_DECISION)

    def test_reserve_hidden_from_buyer_in_detail(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.buyer_token.key}')
        response = self.client.get(f'/api/listings/{self.at_reserve.id}/')
        self.assertEqual(response.status_code, 200)
        self.assertNotIn('reserve_price', response.data)

    def test_reserve_visible_to_seller_in_detail(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.seller_token.key}')
        response = self.client.get(f'/api/listings/{self.at_reserve.id}/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('reserve_price', response.data)


# ---------------------------------------------------------------------------
# Commission calculation — per-category rate
# ---------------------------------------------------------------------------

class CommissionCalculationTest(APITestCase):
    """
    commission_amount = final_price * category.commission_rate, computed per-category.
    Two categories at the same price must produce different commission amounts.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.cars_cat = Category.objects.create(
            slug='cars', name='Used cars', listing_fee='500.00', commission_rate='0.035',
        )
        self.goods_cat = Category.objects.create(
            slug='goods', name='Commercial goods', listing_fee='100.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '42000001', 'seller_comm')
        self.buyer  = _make_user(User, '42000002', 'buyer_comm')
        for u in (self.seller, self.buyer):
            Wallet.objects.create(user=u, balance='999999.00')

        shared = dict(
            seller=self.seller, description='.',
            starting_price='90000.00', min_increment='1000.00',
            current_price='100000.00',
            auction_start=timezone.now() - timezone.timedelta(hours=2),
            auction_end=timezone.now() - timezone.timedelta(seconds=30),
            listing_fee_paid=True, status=Listing.Status.LIVE,
        )
        self.cars_listing = Listing.objects.create(
            title='Cars commission test', category=self.cars_cat,
            reserve_price='80000.00', **shared,
        )
        Bid.objects.create(listing=self.cars_listing, bidder=self.buyer, amount='100000.00')

        self.goods_listing = Listing.objects.create(
            title='Goods commission test', category=self.goods_cat,
            reserve_price='80000.00', **shared,
        )
        Bid.objects.create(listing=self.goods_listing, bidder=self.buyer, amount='100000.00')

    def test_cars_commission_rate(self):
        _run_close_command()
        sale = Sale.objects.get(listing=self.cars_listing)
        self.assertEqual(sale.commission_amount, Decimal('100000.00') * Decimal('0.035'))

    def test_goods_commission_rate(self):
        _run_close_command()
        sale = Sale.objects.get(listing=self.goods_listing)
        self.assertEqual(sale.commission_amount, Decimal('100000.00') * Decimal('0.030'))

    def test_different_rates_produce_different_amounts(self):
        _run_close_command()
        cars_sale  = Sale.objects.get(listing=self.cars_listing)
        goods_sale = Sale.objects.get(listing=self.goods_listing)
        self.assertEqual(cars_sale.final_price, goods_sale.final_price)
        self.assertGreater(cars_sale.commission_amount, goods_sale.commission_amount)


# ---------------------------------------------------------------------------
# Soft-close extension
# ---------------------------------------------------------------------------

class SoftCloseExtensionTest(APITestCase):
    """
    A bid within soft_close_window_seconds of auction_end must push the end
    out by that window.  A bid placed well outside the window must leave
    auction_end unchanged.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='goods', name='Commercial goods',
            listing_fee='100.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '43000001', 'seller_sc')
        self.bidder = _make_user(User, '43000002', 'bidder_sc')
        for u in (self.seller, self.bidder):
            Wallet.objects.create(user=u, balance='999999.00')
        self.bidder_token = Token.objects.create(user=self.bidder)

    def _live_listing(self, seconds_until_end):
        now = timezone.now()
        return Listing.objects.create(
            seller=self.seller, category=self.category,
            title=f'SC test {seconds_until_end}s', description='.',
            starting_price='1000.00', reserve_price='2000.00',
            min_increment='100.00', current_price='1000.00',
            auction_start=now - timezone.timedelta(hours=1),
            auction_end=now + timezone.timedelta(seconds=seconds_until_end),
            soft_close_window_seconds=120,
            listing_fee_paid=True, status=Listing.Status.LIVE,
        )

    def _place_bid(self, listing, amount_str):
        Deposit.objects.get_or_create(
            user=self.bidder, listing=listing,
            defaults={'amount_held': '1000.00'},
        )
        with _patch_view_ws():
            self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder_token.key}')
            return self.client.post(
                f'/api/listings/{listing.id}/place_bid/',
                {'amount': amount_str},
                format='json',
            )

    def test_bid_within_window_extends_auction(self):
        listing = self._live_listing(60)   # 60s < 120s window
        original_end = listing.auction_end

        response = self._place_bid(listing, '1100.00')
        self.assertEqual(response.status_code, 201, response.data)

        listing.refresh_from_db()
        self.assertGreater(listing.auction_end, original_end)

    def test_bid_outside_window_leaves_end_unchanged(self):
        listing = self._live_listing(300)  # 300s > 120s window
        original_end = listing.auction_end

        response = self._place_bid(listing, '1100.00')
        self.assertEqual(response.status_code, 201, response.data)

        listing.refresh_from_db()
        self.assertEqual(listing.auction_end, original_end)


# ---------------------------------------------------------------------------
# Second-chance money logic
# ---------------------------------------------------------------------------

class SecondChanceMoneyTest(APITestCase):
    """
    Accept path: Sale.final_price == runner-up amount,
                 Sale.commission_amount == final_price * category rate,
                 Sale.status == AWAITING_PAYMENT.
    Expire path: listing stays PENDING_SELLER_DECISION,
                 Sale.buyer is still the original top bidder.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='cars', name='Used cars',
            listing_fee='500.00', commission_rate='0.035',
        )
        self.seller  = _make_user(User, '44000001', 'seller_sc2')
        self.bidder1 = _make_user(User, '44000002', 'b1_sc2')   # top (3000)
        self.bidder2 = _make_user(User, '44000003', 'b2_sc2')   # runner-up (2000)
        for u in (self.seller, self.bidder1, self.bidder2):
            Wallet.objects.create(user=u, balance='50000.00')

        self.listing = Listing.objects.create(**_base_listing_kwargs(
            self.category, self.seller,
            reserve='10000.00', current_price='3000.00',
            status=Listing.Status.LIVE,
        ))
        Bid.objects.create(listing=self.listing, bidder=self.bidder1, amount='3000.00')
        Bid.objects.create(listing=self.listing, bidder=self.bidder2, amount='2000.00')
        Deposit.objects.create(user=self.bidder1, listing=self.listing, amount_held='300.00')
        Deposit.objects.create(user=self.bidder2, listing=self.listing, amount_held='200.00')

        self.seller_token  = Token.objects.create(user=self.seller)
        self.bidder2_token = Token.objects.create(user=self.bidder2)

        ws_patcher = mock.patch.multiple(
            'auctions.views',
            get_channel_layer=mock.MagicMock(return_value=mock.MagicMock()),
            async_to_sync=mock.MagicMock(return_value=lambda *a, **kw: None),
        )
        ws_patcher.start()
        self.addCleanup(ws_patcher.stop)

        _run_close_command()
        self.listing.refresh_from_db()

    def _offer(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.seller_token.key}')
        r = self.client.post(f'/api/listings/{self.listing.id}/offer_second_chance/')
        self.assertEqual(r.status_code, 200, r.data)

    def test_accept_final_price_is_runner_up_amount(self):
        self._offer()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')

        sale = self.listing.sale
        sale.refresh_from_db()
        self.assertEqual(sale.final_price, Decimal('2000.00'))

    def test_accept_commission_matches_category_rate(self):
        self._offer()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')

        sale = self.listing.sale
        sale.refresh_from_db()
        self.category.refresh_from_db()   # ensure commission_rate is Decimal, not raw string
        expected = Decimal('2000.00') * self.category.commission_rate
        self.assertEqual(sale.commission_amount, expected)

    def test_accept_sale_status_awaiting_payment(self):
        self._offer()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.bidder2_token.key}')
        self.client.post(f'/api/listings/{self.listing.id}/accept_second_chance/')

        sale = self.listing.sale
        sale.refresh_from_db()
        self.assertEqual(sale.status, Sale.Status.AWAITING_PAYMENT)
        self.assertEqual(sale.buyer, self.bidder2)

    def test_expired_offer_auto_closes_unsold(self):
        # If nobody takes the second-chance offer within its window, the
        # listing auto-resolves as unsold rather than sitting in
        # pending_seller_decision forever waiting on a seller who may
        # never come back to it.
        self._offer()
        sale = self.listing.sale
        sale.second_chance_deadline = timezone.now() - timezone.timedelta(minutes=1)
        sale.save(update_fields=['second_chance_deadline'])

        _run_close_command()   # triggers _expire_second_chance_offers
        self.listing.refresh_from_db()
        self.assertEqual(self.listing.status, Listing.Status.ENDED_UNSOLD)

    def test_expired_offer_releases_all_deposits(self):
        self._offer()
        sale = self.listing.sale
        sale.second_chance_deadline = timezone.now() - timezone.timedelta(minutes=1)
        sale.save(update_fields=['second_chance_deadline'])

        _run_close_command()
        for deposit in Deposit.objects.filter(listing=self.listing):
            self.assertEqual(deposit.status, Deposit.Status.RELEASED)

    def test_expired_offer_sale_buyer_unchanged(self):
        self._offer()
        sale = self.listing.sale
        sale.second_chance_deadline = timezone.now() - timezone.timedelta(minutes=1)
        sale.save(update_fields=['second_chance_deadline'])

        _run_close_command()
        sale.refresh_from_db()
        self.assertEqual(sale.buyer, self.bidder1)
        self.assertIsNone(sale.second_chance_deadline)


# ---------------------------------------------------------------------------
# Favorite idempotency
# ---------------------------------------------------------------------------

class FavoriteIdempotencyTest(APITestCase):
    """
    Favoriting twice must not create duplicate rows.
    Unfavoriting twice must not raise an error.
    """

    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='goods', name='Commercial goods',
            listing_fee='100.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '45000001', 'seller_fav')
        self.buyer  = _make_user(User, '45000002', 'buyer_fav')
        for u in (self.seller, self.buyer):
            Wallet.objects.create(user=u, balance='10000.00')

        self.listing = Listing.objects.create(
            seller=self.seller, category=self.category,
            title='Favorite test item', description='.',
            starting_price='1000.00', reserve_price='2000.00',
            min_increment='100.00',
            auction_start=timezone.now() - timezone.timedelta(hours=1),
            auction_end=timezone.now() + timezone.timedelta(hours=1),
            listing_fee_paid=True, status=Listing.Status.SCHEDULED,
        )
        self.buyer_token = Token.objects.create(user=self.buyer)

    def test_double_favorite_no_duplicate_row(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.buyer_token.key}')
        r1 = self.client.post(f'/api/listings/{self.listing.id}/favorite/')
        r2 = self.client.post(f'/api/listings/{self.listing.id}/favorite/')

        self.assertEqual(r1.status_code, 200)
        self.assertEqual(r2.status_code, 200)
        self.assertEqual(
            Favorite.objects.filter(user=self.buyer, listing=self.listing).count(), 1
        )

    def test_double_unfavorite_no_error(self):
        Favorite.objects.create(user=self.buyer, listing=self.listing)
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.buyer_token.key}')
        r1 = self.client.post(f'/api/listings/{self.listing.id}/unfavorite/')
        r2 = self.client.post(f'/api/listings/{self.listing.id}/unfavorite/')

        self.assertEqual(r1.status_code, 200)
        self.assertEqual(r2.status_code, 200)
        self.assertEqual(
            Favorite.objects.filter(user=self.buyer, listing=self.listing).count(), 0
        )


# ---------------------------------------------------------------------------
# Scheduled -> live transition
#
# Regression coverage for a real bug found manually while testing: nothing
# in the codebase ever set status to LIVE except the seed script (hardcoded
# on a few demo rows) and other tests' fixtures (constructing listings
# directly with status=LIVE). A real listing created through the sell flow
# reaches SCHEDULED after the fee is paid and then never moves again, so it
# could never actually be bid on. See auction_lifecycle.py.
# ---------------------------------------------------------------------------

class ScheduledAuctionAutoStartTest(APITestCase):
    def setUp(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        self.category = Category.objects.create(
            slug='goods', name='Commercial goods',
            listing_fee='100.00', commission_rate='0.030',
        )
        self.seller = _make_user(User, '46000001', 'seller_sas')

    def _make_listing(self, *, start_offset, end_offset, status=Listing.Status.SCHEDULED):
        return Listing.objects.create(
            seller=self.seller, category=self.category,
            title='Scheduled test item', description='.',
            starting_price='1000.00', reserve_price='2000.00',
            min_increment='100.00',
            auction_start=timezone.now() + start_offset,
            auction_end=timezone.now() + end_offset,
            listing_fee_paid=True, status=status,
        )

    def test_overdue_scheduled_listing_goes_live(self):
        listing = self._make_listing(
            start_offset=-timezone.timedelta(minutes=5),
            end_offset=timezone.timedelta(hours=1),
        )
        _run_close_command()
        listing.refresh_from_db()
        self.assertEqual(listing.status, Listing.Status.LIVE)

    def test_not_yet_started_listing_stays_scheduled(self):
        listing = self._make_listing(
            start_offset=timezone.timedelta(minutes=30),
            end_offset=timezone.timedelta(hours=2),
        )
        _run_close_command()
        listing.refresh_from_db()
        self.assertEqual(listing.status, Listing.Status.SCHEDULED)

    def test_listing_overdue_on_both_ends_starts_then_closes_in_one_pass(self):
        # e.g. the server was down across the whole auction window — start
        # and close should both happen in a single run() rather than
        # leaving it stuck LIVE (or worse, still SCHEDULED) until a second
        # run picks it up.
        listing = self._make_listing(
            start_offset=-timezone.timedelta(hours=2),
            end_offset=-timezone.timedelta(minutes=1),
        )
        _run_close_command()
        listing.refresh_from_db()
        self.assertIn(
            listing.status,
            [Listing.Status.ENDED_UNSOLD, Listing.Status.PENDING_SELLER_DECISION],
        )

    def test_listing_view_self_heals_without_the_management_command(self):
        """The whole point: a plain API read settles an overdue listing on
        its own, with no operator ever running close_expired_auctions."""
        listing = self._make_listing(
            start_offset=-timezone.timedelta(minutes=5),
            end_offset=timezone.timedelta(hours=1),
        )
        with _patch_view_ws():
            resp = self.client.get(f'/api/listings/{listing.id}/')
        self.assertEqual(resp.status_code, 200)
        listing.refresh_from_db()
        self.assertEqual(listing.status, Listing.Status.LIVE)
