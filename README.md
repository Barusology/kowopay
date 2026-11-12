# KowoPay

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20DB-FFCA28?style=for-the-badge&logo=firebase)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)
![Flutterwave](https://img.shields.io/badge/Payments-Flutterwave-0B4F6C?style=for-the-badge)
![AI](https://img.shields.io/badge/AI-Gemini%20Assistant-8A2BE2?style=for-the-badge)

</div>

KowoPay is a modern fintech mobile experience designed to make digital finance feel simpler, faster, and more trustworthy. Built with Flutter and powered by Firebase, the app brings together wallet management, bill payments, airtime purchases, deposits, withdrawals, and customer support in one clean mobile interface.

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
- Deposit and withdrawal flows
- Airtime top-up and bill payments
- AI-powered support assistant
- Profile, settings, and help screens
- Insurance and financial service awareness screens
- Firebase-backed authentication and data handling
- Flutterwave-ready payment integration
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
- Dart
- Firebase Auth
- Firebase Realtime Database
- Firebase Storage
- Cloud Functions for Firebase
- Firebase Security Rules
- Riverpod
- SharedPreferences
- Flutterwave
- Google Mobile Ads
- URL Launcher and image picker

## Project Structure

```text
.
├── android/                 # Android project files
├── ios/                     # iOS project files
├── lib/
│   ├── config/              # Build-time configuration (no secrets)
│   ├── providers/           # State management providers
│   ├── screens/             # UI flows and screens
│   ├── services/            # Firebase and business logic services
│   ├── theme/               # White + purple design system
│   ├── utils/               # Validators, sanitizers, rate limits, logging
│   ├── widgets/             # Shared cinematic UI components
│   ├── main.dart            # App entry point and auth gate
│   └── routes.dart          # Route configuration
├── functions/               # Cloud Functions (money, AI, webhook, admin)
├── test/                    # Automated tests
├── web/                     # Web support files
├── windows/                 # Windows project files
├── linux/                   # Linux project files
├── macos/                   # macOS project files
├── database.rules.json      # Realtime Database access rules
├── storage.rules            # Storage access rules
├── firebase.json            # Hosting headers, rules and functions config
├── pubspec.yaml             # Dependencies and metadata
├── SECURITY.md              # Security audit and deployment checklist
└── README.md
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

### Firebase Setup

1. Create a Firebase project in the Firebase Console.
2. Add Android and iOS apps to your project.
3. Download and place the required config files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Update `firebase_options.dart` to match your Firebase configuration.

### Run the App

Copy the example configuration and fill in the public client values:

```bash
cp .env.example .env
flutter run --dart-define-from-file=.env
```

For a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

### Cloud Functions

```bash
cd functions
npm install
cd ..
cp functions/.env.example functions/.env   # fill in secrets locally
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set FLUTTERWAVE_SECRET_HASH
firebase functions:secrets:set FLUTTERWAVE_SECRET_KEY
firebase deploy --only database,storage,functions
```

Wallet credits, withdrawals, airtime, AI advice and admin claims run only on
the server. See [SECURITY.md](SECURITY.md) for the full threat model, the key
rotation that is still required, and the production checklist.

## Build & Deployment

### Android

```bash
flutter build apk --dart-define-from-file=.env
```

### iOS

```bash
flutter build ios --dart-define-from-file=.env
```

### Web

```bash
flutter build web --release --dart-define-from-file=.env
firebase deploy --only hosting
```

## Security & Configuration Notes

- No secret is committed. Payment/AI secret keys live in Cloud Functions
  secrets; the Flutterwave public key and redirect URL are injected at build
  time.
- Users can only read their own database subtree. Balance, ledger and
  notifications are server-written.
- Admin access requires the `admin` custom claim, enforced by both the UI and
  the database rules.
- Email verification is required before any financial screen is reachable.
- HTTP security headers (CSP, HSTS, X-Frame-Options, Permissions-Policy) are
  configured in `firebase.json`.
- Rotate the historical Gemini key referenced in SECURITY.md before any public
  release.

## Contributing

Contributions are welcome. If you want to improve KowoPay, fork the repo and submit a pull request with a clear summary of your changes.

## License

This project is intended for development, testing, and deployment under the applicable project licensing and third-party service policies. Please review relevant terms before production release.

## Repository

- GitHub: https://github.com/Barusology/kowopay

## Status

KowoPay is an active fintech prototype ready for iteration, user testing, and production hardening.
