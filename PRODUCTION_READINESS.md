# Production Readiness Scorecard

This is the baseline for the Datafactor criteria supplied with the project.
“Ready” means the checkbox is complete **and** its verification command or
console control has been recorded.

| Area | Baseline | Current state | Exit criteria |
|---|---|---|---|
| Small, test-backed increments | Low | Improved with focused commits `94205c2`, `dba03df`, and `8f09e60` | Continue landing one behavior per commit/PR |
| Fresh clone install/build/test | High risk | Install and tests work locally; release build is now CI-gated | `flutter pub get`, `flutter test --coverage`, and release build pass from a clean clone |
| Credentials | Critical risk | Gemini removed from client; Firebase client config is restricted/documented | Rotate historical keys; verify provider quotas and restrictions |
| Test coverage | High risk | 9 tests, approximately 37% line coverage | Reach 65% before beta and 80% before general release |
| Firebase authorization | Critical risk | Rules deny balance/transaction writes | Deploy rules and pass Firebase Emulator rules tests |
| Payment settlement | Critical risk | Client remains test-mode only | Deploy server-side Flutterwave creation, webhook verification, idempotency, and reconciliation |
| AI service | High risk | Client fails closed | Deploy authenticated server-side Gemini proxy with quotas |
| Observability | High risk | No production monitoring wired | Enable Crashlytics, structured backend logs, alerts, and payment reconciliation |
| Release controls | Medium risk | CI checks source quality and debug build | Add protected main, required checks, signed Android/iOS release builds |

## Required console and deployment actions

1. Rotate all credentials exposed in git history.
2. Create separate development, staging, and production Firebase projects.
3. Deploy `database.rules.json` and test it in the Firebase Emulator Suite.
4. Deploy `functions/` with `npm ci && npm run build`.
5. Configure Flutterwave secrets only in Functions Secret Manager.
6. Configure Gemini secrets only in Functions Secret Manager.
7. Enable App Check, Crashlytics, API restrictions, billing alerts, and quotas.
8. Complete KYC/AML, payment-provider, privacy, and incident-response review.
