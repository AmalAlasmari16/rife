# رِفق · Rifq — Flutter mobile app

> برعاية تليق بطفلك

SaaS childcare-management platform for nurseries in Saudi Arabia. Multi-tenant,
Arabic-first (RTL), AI-assisted daily reports, three subscription tiers.

This directory holds the Flutter (iOS + Android) client. The web/React
prototype in `../frontend` is kept for reference only.

---

## Build status (per the spec's build order)

| # | Step                                        | Status      |
|---|---------------------------------------------|-------------|
| 1 | Project structure + Firebase + pubspec      | ✅ done     |
| 2 | Authentication + role-based routing         | ✅ done     |
| 3 | Subscription system (plans, paywall)        | ✅ done     |
| 4 | Super-admin dashboard                       | ✅ done     |
| 5 | Nursery admin (children, classrooms, staff) | ✅ done     |
| 6 | Teacher (attendance, daily log, AI report)  | ✅ done     |
| 7 | Parent (dashboard, reports, messaging)      | ✅ done     |
| 8 | QR check-in / check-out                     | ✅ done     |
| 9 | Billing module                              | ✅ done     |
|10 | Push notifications                          | ⏳ pending  |
|11 | Digital enrollment                          | ⏳ pending  |

---

## Folder layout

```
lib/
├─ core/
│  ├─ constants/        # app + Firestore paths
│  ├─ theme/            # colors + Material 3 theme
│  ├─ utils/            # date helpers (Hijri + Gregorian)
│  └─ subscription/     # SubscriptionPlan + AccessControl (pure Dart)
├─ data/
│  ├─ firebase_services/  # Firebase bootstrap + options
│  ├─ models/             # AppUser, Nursery, Invite, ...
│  └─ repositories/       # Auth, User, Nursery, Invite, ...
├─ presentation/
│  ├─ router/           # go_router config + named routes
│  ├─ screens/
│  │  ├─ auth/          # welcome, login, register, invite, OTP
│  │  ├─ home/          # role-specific placeholders
│  │  ├─ subscription/  # step 3
│  │  ├─ super_admin/   # step 4
│  │  ├─ admin/         # step 5
│  │  ├─ teacher/       # step 6
│  │  └─ parent/        # step 7
│  └─ widgets/
├─ providers/           # Riverpod providers (barrel)
├─ app.dart             # MaterialApp + RTL + theme
└─ main.dart            # bootstraps Firebase, dotenv, intl, runs the app
```

---

## First-time setup

1. **Install Flutter** 3.22+ and run `flutter doctor`.
2. **Get dependencies** — from this directory:
   ```bash
   flutter pub get
   ```
3. **Generate the Flutter platform shells** (the `ios/`, `android/`, `macos/`,
   `linux/`, `windows/`, `web/` folders are not committed to keep the diff
   small). Run once:
   ```bash
   flutter create --platforms=android,ios --org sa.rifq --project-name rifq .
   ```
4. **Wire Firebase** — install the FlutterFire CLI and run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=rifq-prod
   ```
   That rewrites `lib/data/firebase_services/firebase_options.dart` with real
   keys and drops `android/app/google-services.json` and
   `ios/Runner/GoogleService-Info.plist` into place. Both files are
   gitignored. Placeholders (`*.placeholder`) are committed as reminders.
5. **Secrets** — copy `.env.example` to `.env` and fill in:
   ```
   GEMINI_API_KEY=...
   ```
   The Gemini key is only used by the AI daily-report feature (step 6).
6. **Fonts** — drop `Tajawal-Regular.ttf`, `Tajawal-Medium.ttf`, and
   `Tajawal-Bold.ttf` into `assets/fonts/`. They are referenced by
   `pubspec.yaml` and the theme falls back to Google Fonts at runtime so
   missing files only affect offline first-launch typography.
7. **Run**:
   ```bash
   flutter run
   ```

You should see the رِفق splash screen with the tagline, rendered RTL on the
teal brand background. That confirms step 1 is wired correctly.

---

## Brand

- App name: **رِفق** (`Rifq`)
- Tagline: **برعاية تليق بطفلك**
- Primary: `#2E7D9B` (teal)
- Accent: `#F5A623` (orange)
- Typeface: Tajawal (Google Fonts)
- RTL Arabic only, light mode only

---

## Subscription model (reference)

| Plan       | SAR/mo | Max kids | Billing | AI reports | Branches |
|------------|-------:|---------:|:-------:|:----------:|:--------:|
| أساسي      |    199 |       30 |    ❌    |     ❌      |    ❌     |
| متوسط      |    399 |       80 |    ✅    |     ✅      |    ❌     |
| بريميوم    |    699 |        ∞ |    ✅    |     ✅      |    ✅     |

All plans include a 30-day free trial with full access. Enforced in
`lib/core/subscription/access_control.dart` (pure Dart, easily unit-tested)
and mirrored in Firestore security rules (added in step 3).
