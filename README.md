# MAZAD

An online auction marketplace for Mauritania — cars, land, and general goods — with live bidding, deposit-backed bid ceilings, and a full second-chance/dispute/notification pipeline.

## Structure

- `mazad_backend/` — Django 6 + Django REST Framework + Channels (WebSockets over Redis) + PostgreSQL.
- `mazad_mobile/` — Flutter app (feature-folder architecture: `core/`, `features/<name>/{data,domain,presentation}`), English/French/Arabic with full RTL support.
- `PROJECT_REPORT.md` — full handoff document: architecture, feature matrix, business rules, test inventory, known limitations, and next steps. Start here.

## Backend setup

```bash
cd mazad_backend
python -m venv venv && source venv/bin/activate   # Python 3.12+
pip install -r requirements.txt
cp .env.example .env   # then edit with real values, or just rely on the dev defaults
python manage.py migrate
python manage.py test auctions   # 30 money-logic/regression tests
python manage.py runserver
```

Needs a local PostgreSQL (`mazad_db`) and Redis (for Channels) running — see `.env.example` for the settings that point at them.

To seed demo data (users, listings, bids, deposits, sales, disputes, notifications):

```bash
python manage.py seed_demo_data --i-know-what-im-doing --clear
```

## Mobile setup

```bash
cd mazad_mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

`lib/core/config/app_config.dart` points at `10.0.2.2:8000` (the Android emulator's alias for the host machine) by default — change it for a physical device or a deployed backend.

Push notifications need a real Firebase project: drop `google-services.json` into `android/app/` and `GoogleService-Info.plist` into `ios/Runner/` (both are gitignored — never commit them).

## Business rules (summary — see `PROJECT_REPORT.md` for the full reference)

- Bid ceiling = deposit held × multiplier (default 10x); reserve price is separate and hidden from buyers.
- Commission is per-category.
- A bid within the last N seconds (soft-close window) extends the auction.
- Below-reserve endings go to a 24h seller decision window, with an optional second-chance offer to the runner-up.
- Categories: Cars, Land, Goods. Land listings require ID verification.
- Currency: MRU.
