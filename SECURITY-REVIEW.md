# Security Review

## Findings

| # | Severity | File | Lines | Vulnerability | Confidence |
|---|----------|------|-------|---------------|------------|
| 1 | HIGH | `lib/providers/core_providers.dart` (resolved) | 1-20 | Gemini API credential was committed in application source and could be extracted from released builds. | 10/10 |
| 2 | HIGH | `lib/services/payment_service.dart` (resolved) | 59-68 | Withdrawal returned success without contacting Flutterwave, creating a false-success payment flow. | 10/10 |
| 3 | HIGH | `lib/screens/airtime_screen.dart` and `lib/services/database_service.dart` (mitigated) | 47-83 | A mobile client can write balances and transaction records directly; Firebase Rules and a trusted server-side function must enforce authorization and payment settlement. | 9/10 |
| 4 | MEDIUM | `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` | platform config | Firebase client API keys are shipped in the app. These identify the Firebase project and are not secrets, but the project must use restrictive API keys, Firebase Security Rules, and App Check. | 10/10 |

## Remediation completed

- Gemini is no longer initialized from the client; it must be accessed through
  an authenticated server-side endpoint.
- Flutterwave test credentials and redirect URLs come from `--dart-define`
  values rather than committed Dart constants.
- Missing runtime configuration fails explicitly.
- Balance deduction and audit logging now happen in one Realtime Database
  transaction.
- The fake withdrawal success path now fails explicitly until a trusted backend
  integration is available.
- CI now includes repository secret scanning.
- CI now enforces targeted formatting, warnings-free analysis, and Flutter tests.
- The previously committed Gemini credential should be revoked and rotated.

## Remaining production work

Move payment settlement, withdrawals, and balance mutation to authenticated
Cloud Functions or another trusted backend. Realtime Database Rules should
prevent clients from writing balances and should validate transaction ownership.
