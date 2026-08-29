# Mazad — Project Report

**Date:** 2026-08-18  
**Stack:** Django 5 · Django REST Framework · Django Channels (WebSocket) · Flutter 3  
**Repo layout:** `mazad_backend/` (Python/Django) · `mazad_mobile/` (Flutter)

---

## 1. Executive Summary

Mazad is a live-auction marketplace built for the Mauritanian market (currency: MRU). Sellers list physical goods, land, and vehicles; registered bidders place real-money bids during a timed auction window. The platform handles the full lifecycle: listing creation → deposit → live bidding with soft-close → auction close → second-chance offer → sale → delivery → dispute resolution.

The backend exposes a REST + WebSocket API consumed by a Flutter mobile app. Localization (English, French, Arabic with RTL support) is built into the mobile client. The entire project was developed as a portfolio/proof-of-concept; it is demo-ready but not yet production-hardened.

---

## 2. Architecture

### Backend (`mazad_backend/`)

```
mazad_backend/
├── mazad_backend/          # Django project settings, ASGI, routing
│   ├── settings.py
│   ├── asgi.py             # Channels integration (HTTP + WebSocket)
│   └── urls.py
└── auctions/               # Single Django app — all domain logic lives here
    ├── models.py           # All ORM models
    ├── views.py            # DRF ViewSets + APIViews (~720 lines)
    ├── serializers.py      # Input validation + output shaping
    ├── permissions.py      # IsOwnerOrReadOnly
    ├── consumers.py        # Django Channels WebSocket consumer
    ├── notifications_service.py  # notify() — DB + WS + FCM
    ├── push_service.py     # FCM (Firebase Cloud Messaging)
    └── management/commands/
        ├── close_expired_auctions.py   # Cron-driven auction lifecycle
        └── seed_demo_data.py           # Demo data seeding (DEBUG only)
```

**Key design decisions:**

- **Single-app Django structure.** All domain models are in `auctions`. This was a deliberate simplicity tradeoff for a solo project — no need for cross-app imports.
- **REST + WebSocket dual API.** HTTP (DRF Token auth) handles CRUD and actions; WebSocket (Channels) pushes real-time bid updates and notifications to connected clients. The two paths are independent — WebSocket failure never blocks an HTTP response.
- **`select_for_update()` inside `transaction.atomic()` for bids.** Two simultaneous bids on the same listing are serialized at the DB level. The second bid waits, then re-validates against the updated price.
- **Notification fan-out:** `notify()` in `notifications_service.py` writes a `Notification` DB row, then best-effort pushes via WebSocket and FCM (errors are caught and logged, never surfaced to the caller).
- **Management command for auction close.** `close_expired_auctions` is designed to be called by cron every minute. It is idempotent — re-running on already-closed listings is a no-op because the command re-checks status inside the lock.

### Mobile (`mazad_mobile/`)

```
mazad_mobile/lib/
├── core/
│   ├── app.dart                    # MaterialApp + Locale + Theme wiring
│   ├── config/app_config.dart      # API host config
│   ├── locale/locale_controller.dart
│   ├── theme/                      # Colors, typography, theme controller
│   └── presentation/nav_shell.dart # Bottom navigation shell
├── l10n/                           # ARB files + generated AppLocalizations
│   ├── app_en.arb
│   ├── app_fr.arb
│   └── app_ar.arb
└── features/
    ├── auth/           # Login, registration, AuthController
    ├── listings/       # Browse feed, listing detail
    ├── bidding/        # Live auction screen (WebSocket)
    ├── favorites/      # Favorites list + FavoriteButton
    ├── wallet/         # Wallet balance + deposit creation
    ├── orders/         # Order tracking (sale status)
    ├── addresses/      # Address book (CRUD)
    ├── notifications/  # Notification list + unread badge
    ├── disputes/       # Report dispute form + my-disputes list
    ├── kyc/            # KYC submission form + status
    ├── profile/        # Profile tab (theme, language, account)
    ├── support/        # FAQ + contact form
    └── onboarding/     # First-launch onboarding slides
```

**Key mobile design decisions:**

- **`AuthController extends ChangeNotifier`** — single source of truth for auth state, token, bidder number. Passed down the widget tree and listened to with `AnimatedBuilder`.
- **Repository pattern** — each feature has a `*Repository` class that owns HTTP calls. The repository is injected into the screen widget, making screens testable in isolation.
- **WebSocket in `LiveAuctionScreen`** — connects on `initState`, handles `bid_placed` and `auction_closed` events, disconnects on `dispose`. Reconnects on error with exponential backoff.
- **Locale + Theme controllers** — `LocaleController` and `ThemeController` both extend `ValueNotifier<T>`, persisted to `SharedPreferences`, injected via `InheritedNotifier`.

---

## 3. Feature List

### Implemented (backend + mobile)

| Feature | Backend | Mobile |
|---|---|---|
| Phone + password auth (register/login) | ✓ | ✓ |
| Listing browse with category filter | ✓ | ✓ |
| Listing detail view | ✓ | ✓ |
| Live bidding (REST place_bid + WS real-time) | ✓ | ✓ |
| Deposit creation (bid ceiling enforcement) | ✓ | ✓ |
| Wallet balance view | ✓ | ✓ |
| Soft-close (2-min extension on late bids) | ✓ | ✓ |
| Auction close management command | ✓ | n/a |
| Second-chance offer flow | ✓ | ✓ |
| Favorites (toggle + list) | ✓ | ✓ |
| Notification list + real-time push | ✓ | ✓ |
| FCM device token registration | ✓ | ✓ |
| Address book (CRUD) | ✓ | ✓ |
| Sale tracking (shipped/delivered) | ✓ | ✓ |
| Dispute reporting + my-disputes list | ✓ | ✓ |
| KYC submission + status | ✓ | ✓ |
| My bids list | ✓ | ✓ |
| My listings list | ✓ | ✓ |
| Listing image upload (seller, post-publish) | ✓ | ✓ |
| Mark notification read / mark all read | ✓ | ✓ |
| Language selector (EN / FR / AR) | n/a | ✓ |
| Dark mode toggle | n/a | ✓ |
| Demo data seed command | ✓ | n/a |
| Onboarding flow | n/a | ✓ |

### Backend-only (no mobile UI yet)

- Admin listing approval workflow
- KYC review (admin action)
- Dispute resolution (admin action)
- Merchant subscription management
- Featured placement management
- Buyer default / ListingBan enforcement
- `confirm_payment`, `mark_shipped`, `confirm_received` endpoints (stubs — mobile order tracking screen reads data but doesn't trigger them yet)

---

## 4. Business Rules

### Auction lifecycle

```
DRAFT → PENDING_PAYMENT → SCHEDULED → LIVE → {ENDED_SOLD | ENDED_UNSOLD | PENDING_SELLER_DECISION}
                                                                       ↓
                                                            (seller decides)
                                                    offer_second_chance → runner-up accepts → ENDED_SOLD
                                                                       → runner-up expires  → (seller calls end_unsold)
                                                    end_unsold          → ENDED_UNSOLD
```

### Deposit & bid ceiling

- A bidder must lock a deposit on a specific listing before bidding.
- `bid_ceiling = amount_held × multiplier` (multiplier defaults to 10, flat rate per business decision).
- A bid `amount > bid_ceiling` is rejected at the API layer.
- Multiple deposits on the same listing are additive (`amount_held` accumulates).
- Deposits are released on `end_unsold` or when a bidder is outbid at auction close. The winning bidder's deposit stays `ACTIVE` until `mark_paid()` is called.
- A defaulted buyer's deposit is forfeited (100% to Mazad, no seller split) and the buyer is banned from that listing.

### Reserve price

- Every listing has a mandatory reserve price (enforced at API level, not nullable).
- `is_reserve_met() = current_price >= reserve_price`.
- Reserve price is hidden from buyers in API responses (`to_representation` strips it for non-seller, non-staff users).
- If reserve is met at close → `ended_sold`. If not → `pending_seller_decision`.

### Commission

- `commission_amount = final_price × category.commission_rate`
- Default rates: Cars 3.5% · Land 2.5% · Goods 3.0% (configurable per Category row).
- Stored on the `Sale` row at creation time so rate changes don't retroactively affect existing sales.

### Soft close

- When a valid bid is placed within `soft_close_window_seconds` (default 120 s) of `auction_end`, the auction is extended: `new_auction_end = bid_time + soft_close_window_seconds`.
- Extension is unlimited — a flurry of last-second bids continues extending.

### Second-chance flow

- Triggered by seller calling `offer_second_chance` on a `PENDING_SELLER_DECISION` listing.
- Runner-up is the second-highest unique bidder by their max bid amount.
- Runner-up has `second_chance_deadline = now + 10 minutes` to accept.
- On accept: `Sale.buyer = runner_up`, `Sale.final_price = runner_up's max bid`, `Sale.commission_amount` recalculated, `Sale.status = AWAITING_PAYMENT`, listing → `ENDED_SOLD`.
- On expiry (cron): `second_chance_deadline` is cleared; listing remains `PENDING_SELLER_DECISION` until the seller explicitly calls `end_unsold`.

### Verification tiers

| Tier | Required for |
|---|---|
| `unverified` | Browsing only |
| `phone_verified` | Bidding on Cars / Goods |
| `id_verified` | Bidding on Land, creating Land listings |

---

## 5. Testing

**Test file:** `mazad_backend/auctions/tests.py`  
**Framework:** Django `APITestCase` (DRF)  
**WebSocket isolation:** `mock.patch` on `get_channel_layer` and `async_to_sync` in the command and view modules.

### Test classes

| Class | What it covers |
|---|---|
| `DepositReleaseOnEndUnsoldTest` | `end_unsold` releases all ACTIVE deposits |
| `PendingSellerDecisionFlowTest` | Full second-chance lifecycle via real close command: provisional Sale creation, `offer_second_chance`, `accept_second_chance`, deposit release, forbidden non-seller access |
| `DepositBidCeilingTest` | Bid at exactly the ceiling succeeds; one unit above is rejected with a clear error |
| `ReservePriceEnforcementTest` | At-reserve → `ended_sold`; below-reserve → `pending_seller_decision`; reserve hidden from buyers, visible to sellers |
| `CommissionCalculationTest` | Per-category commission rates produce correct amounts; Cars (3.5%) and Goods (3.0%) differ on identical final prices |
| `SoftCloseExtensionTest` | Bid within window extends `auction_end`; bid outside window leaves it unchanged |
| `SecondChanceMoneyTest` | Accept path: `final_price == runner_up_amount`, commission correct, status `AWAITING_PAYMENT`; expire path: listing stays `PENDING_SELLER_DECISION`, `sale.buyer` unchanged |
| `FavoriteIdempotencyTest` | Double-favorite creates one row; double-unfavorite leaves zero rows, no errors |

**Run:** `python manage.py test auctions.tests --verbosity=2`  
**Result (as of 2026-08-18):** 30 tests, 0 failures, 0 errors.

---

## 6. Known Limitations

### Not production-ready

- **Payment integration is a stub.** `pay_listing_fee`, `confirm_payment` endpoints return 200 without any real payment processing. Sedad (Mauritanian payment gateway) integration is the intended next step.
- **FCM credentials not configured.** `push_service.py` requires Firebase credentials. In the current demo setup, push delivery silently no-ops when credentials are absent.
- **No rate limiting.** The bid endpoint has no per-user throttle. A bad actor could spam bids.
- **Local filesystem image storage only.** Listing images, KYC documents, and dispute evidence are written to `MEDIA_ROOT` on the local disk. This is fine for a single-server demo but does not scale — files are lost on server restart in ephemeral environments and are not replicated across instances. Object storage (S3/MinIO) is the production path (see Next Steps).
- **`settings.DEBUG = True` in demo config.** Must be changed and `ALLOWED_HOSTS` / `SECRET_KEY` set before any public deployment.
- **SQLite in development.** The `close_expired_auctions` command uses `select_for_update()` which SQLite does not enforce — concurrent writes in production require PostgreSQL.

### Business logic gaps

- **Buyer default auto-detection is not automated.** There is no cron job that detects when `Sale.status == AWAITING_PAYMENT` has aged past a deadline and auto-calls `mark_defaulted()`. This must be triggered manually or by a future cron command.
- **No global strike / ban system.** `User.default_count` is tracked but never enforced (e.g., suspending accounts after N defaults). Intentional for now per original design decision.
- **`cancel` listing action not exposed via API.** The `CANCELLED` status exists in the model but there is no endpoint for sellers or admins to cancel a listing post-SCHEDULED.
- **Land KYC gate is model-level only.** The serializer validates `requires_id_verification` on listing creation, but there is no re-check if a user's tier is downgraded after listing.
- **No pagination on most list endpoints.** Notifications have page/page_size params; favorites and bids do not. Large datasets will return everything in one response.

### Mobile gaps

- **`confirm_payment`, `mark_shipped`, `confirm_received` have no UI triggers.** The order tracking screen reads delivery state but the action buttons are not wired to the API yet.
- **Listing image upload is post-publish only.** Sellers add photos after paying the listing fee. Images cannot be edited once the listing goes live (by design — changing photos mid-auction would be misleading to bidders).
- **KYC image upload uses the device camera only.** Gallery picker is not implemented.
- **WebSocket reconnection uses simple exponential backoff** with no upper bound. On a poor connection this could hold a large number of retries.
- **No offline support.** Every screen shows a connectivity error state but does not cache any data locally.

---

## 7. Next Steps

### Immediate (before any real users)

1. **Wire Sedad payment gateway** to `pay_listing_fee` and `confirm_payment` endpoints.
2. **Switch to PostgreSQL** and run `select_for_update()` tests under actual concurrency.
3. **Configure Firebase** credentials and test end-to-end push delivery.
4. **Set `DEBUG=False`**, configure `ALLOWED_HOSTS`, rotate `SECRET_KEY`, add HTTPS.
5. **Add `mark_defaulted` cron** — detect stale `AWAITING_PAYMENT` sales and auto-forfeit after the grace period.

### Near-term feature work

6. **Mobile: Complete order action buttons** — confirm payment, mark shipped, confirm received.
7. **Mobile: Listing creation flow** — the backend `CREATE /api/listings/` endpoint exists; the mobile sell screen is a placeholder.
8. **Admin dashboard** — KYC review, dispute resolution, featured placement management.
9. **Merchant subscription** — `MerchantSubscription` model exists; no enrollment flow.
10. **Add pagination** to favorites, my-bids, my-disputes, and notification list endpoints.

### Infrastructure

11. **Separate cron worker** from the web process (Celery Beat or a simple crontab) for `close_expired_auctions`.
12. **Object storage (S3 / MinIO)** for listing images, KYC documents, and dispute evidence.
13. **Rate limiting** on bid and auth endpoints (DRF throttles or nginx).
14. **Monitoring** — error tracking (Sentry), uptime checks, and a latency alert on the bid endpoint.
