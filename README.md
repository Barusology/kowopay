# KowoPay

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20DB-FFCA28?style=for-the-badge&logo=firebase)
![Dart](https://img.shields.io/badge/Dart-3.8%2B-0175C2?style=for-the-badge&logo=dart)
![Flutterwave](https://img.shields.io/badge/Payments-Flutterwave-0B4F6C?style=for-the-badge)
![AI](https://img.shields.io/badge/AI-Gemini%20Assistant-8A2BE2?style=for-the-badge)

</div>

KowoPay is a Flutter/Firebase fintech prototype for exploring onboarding, wallet, and everyday-payment experiences. Payment, withdrawal, airtime, and AI features remain fail-closed until their authenticated, provider-verified production services are deployed. Do not use this prototype to hold or move customer funds.

<div align="center">

## Product Preview

[![Screenshot Placeholder](https://via.placeholder.com/1200x650/0B4F6C/ffffff?text=KowoPay+App+Preview)](https://github.com/Barusology/kowopay)

</div>

## Why KowoPay

KowoPay is built for users who want a secure and intuitive mobile finance experience without the friction of traditional banking apps. The product focuses on everyday financial activity, clear onboarding, trust-building UX, and modern payment capabilities.

## Feature Highlights

<div align="center">

![Onboarding](https://img.shields.io/badge/Onboarding-Secure%20Flow-34A853)
![Wallet](https://img.shields.io/badge/Wallet-Dashboard-1E90FF)
![Payments](https://img.shields.io/badge/Payments-Deposit%20%2B%20Withdraw-00B894)
![Utility](https://img.shields.io/badge/Airtime-Bill%20Pay-F39C12)
![Support](https://img.shields.io/badge/AI-Chat%20Assistant-8E44AD)
![Profile](https://img.shields.io/badge/Account-Settings%20%26%20Help-6C5CE7)

</div>

### Core Features

- Secure onboarding and login flow
- User wallet and account overview dashboard
- Deposit, withdrawal, airtime, and bill-payment UI (transactions disabled until trusted backend settlement is available)
- AI support UI (server-side model proxy and abuse controls still required)
- Profile, settings, and help screens
- Insurance and financial service awareness screens
- Firebase-backed authentication and data handling
- Firebase Functions payment boundary scaffold; no live payment-provider settlement
- Mobile-first UI for Android and iOS

## Screens Included

- Splash and onboarding
- Login and registration
- Home dashboard
- Deposit flow
- Withdraw flow
- Airtime purchases
- Bill payment flow
- AI chat assistant
- Profile and settings
- Support and help center
- Insurance-related experience

## Tech Stack

- Flutter
- Dart 3.8+
- Firebase Auth
- Firebase Realtime Database
- Firebase Storage
- Riverpod
- SharedPreferences
- Flutterwave
- Google Mobile Ads
- Google Generative AI
- URL Launcher and image picker

## Project Structure

```text
.
├── android/                 # Android project files
├── ios/                     # iOS project files
├── lib/
│   ├── models/              # App data models
│   ├── providers/           # State management providers
│   ├── screens/             # UI flows and screens
│   ├── services/            # Firebase and business logic services
│   ├── models/money.dart    # ISO 4217 currency and integer minor-unit model
│   ├── main.dart            # App entry point
│   ├── routes.dart          # Route configuration
│   └── ...
├── test/                    # Automated tests
├── web/                     # Web support files
├── windows/                 # Windows project files
├── linux/                   # Linux project files
├── macos/                   # macOS project files
├── pubspec.yaml             # Dependencies and metadata
├── analysis_options.yaml    # Linting rules
├── .gitignore
├── README.md
└── ...
```

## Quick Start

### Prerequisites

- Flutter SDK 3.x+
- Dart SDK
- Firebase project configured
- Android Studio / VS Code with Flutter tooling
- Xcode for iOS builds (macOS only)

### Installation

```bash
git clone https://github.com/Barusology/kowopay.git
cd kowopay
flutter pub get
```

Copy `.env.example` as a reference for Functions-only secrets. The Flutter
client intentionally has no payment or Gemini credentials.

### Firebase Setup

1. Create a Firebase project in the Firebase Console.
2. Add Android and iOS apps to your project.
3. Download and place the required config files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Update `firebase_options.dart` to match your Firebase configuration.

### Run the App

```bash
flutter run
```

For a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

### Test and coverage

```bash
flutter test --coverage
```

CI enforces formatting, static analysis, secret scanning, debug Android builds,
Functions compilation, and at least 35% line coverage.

## Build & Deployment

### Android

```bash
flutter build apk
```

### iOS

```bash
flutter build ios
```

### Web

```bash
flutter build web
```

## Security & Configuration Notes

This app integrates with external services and credentials. For production use, ensure that:

- Flutterwave secret credentials and Gemini keys are stored only in Firebase
  Functions Secret Manager.
- Payment and financial-advice flows remain disabled in the client until their
  authenticated server-side endpoints are deployed.
- All financial APIs and ledger entries use an ISO 4217 `currencyCode` plus
  integer `amountMinor`/`balanceMinor`; never use floating point for money
  arithmetic or infer a currency from a formatted display string.
- Currency representation supports ISO 4217 codes with the corresponding
  minor-unit precision. Payment-provider support and the current product UI
  remain narrower; currency representation alone does not enable a currency
  for settlement.
- Existing `/users/{uid}/balance` floating-point data is legacy read-only
  compatibility. Reconcile and migrate it to `/users/{uid}/wallets/{CODE}/balanceMinor`
  with an audited, idempotent migration before enabling any funded production
  wallet endpoint. Do not deploy a migration against production balances
  without a reviewed backup and reconciliation plan.
- Deploy and emulator-test both `database.rules.json` and `storage.rules`.
- The generic wallet debit callable requires Firebase App Check and is not a
  substitute for a verified provider payment, fulfilment, or settlement flow.
- Firebase config is environment-specific
- Payment provider credentials are not committed to source control
- Environment-specific builds are isolated from development settings

Firebase client API keys in `firebase_options.dart`, `google-services.json`, and
`GoogleService-Info.plist` identify the Firebase project and are expected in
client applications. They are not authorization secrets; protect the project
with Firebase Authentication, Security Rules, API restrictions, and App Check.
Rotate any credentials that were previously committed and review provider usage
and quotas after rotation. The app defaults Flutterwave to test mode and must
not be switched to live mode until server-side webhook/signature verification
and transaction settlement are implemented.

## Contributing

Contributions are welcome. If you want to improve KowoPay, fork the repo and submit a pull request with a clear summary of your changes.

## License

This project is intended for development, testing, and deployment under the applicable project licensing and third-party service policies. Please review relevant terms before production release.

## Repository

- GitHub: https://github.com/Barusology/kowopay

## Status

KowoPay is an active fintech prototype ready for iteration, user testing, and production hardening.
