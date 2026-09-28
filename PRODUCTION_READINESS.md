# Production Readiness Scorecard

This is the baseline for the Datafactor criteria supplied with the project.
“Ready” means the checkbox is complete **and** its verification command or
console control has been recorded.

| Area | Baseline | Current state | Exit criteria |
|---|---|---|---|
| Small, test-backed increments | Low | Earlier changes landed in small commits; keep new behavior paired with tests | Continue landing one behavior per commit/PR |
| Fresh clone install/build/test | Medium | Flutter lockfile and Functions lockfile are committed; CI runs tests, static checks, Android debug build, and Functions tests | Verify all checks on a clean clone and a signed staging build |
| Credentials | Critical risk | No Gemini secret is consumed by Flutter; Firebase client configuration values remain in generated config | Rotate historical provider secrets; verify Firebase API restrictions, quotas, and App Check |
| Test coverage | Medium | Auth, login, configuration, and integer-money model tests exist; Functions now has unit tests | Expand rules/emulator, screen, and payment contract coverage; raise coverage gate gradually |
| Firebase authorization | High risk | User profile is field-allowlisted; clients cannot write wallets or transaction ledgers; Storage ownership rules are checked in | Deploy both rulesets and pass Firebase Emulator Suite rules tests before production |
| Payment settlement | Critical risk | Client payment, withdrawal, and airtime services fail closed; callable debit uses integer minor units and requires App Check | Do not enable funded accounts until provider verification/webhooks, service fulfilment, idempotency, refunds, and reconciliation are implemented |
| AI service | High risk | Client fails closed | Deploy authenticated server-side Gemini proxy with quotas |
| Observability | High risk | Crash reporting, metrics, operational alerts, and transaction monitoring are not wired | Enable Crashlytics, structured backend logs, alerts, and payment reconciliation |
| Release controls | Medium risk | CI checks source quality and debug build | Add protected main, required checks, signed Android/iOS release builds |
| Currency correctness | High risk | Money is represented as integer minor units using the current ISO 4217 codes and precision values published by [SIX Group](https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml) on 2026-09-17 | Refresh the registry as ISO metadata changes; migrate legacy balances with reconciliation; only advertise currencies supported by each provider |
| Supply chain | Medium risk | Pub/Functions/action updates are monitored by Dependabot; CI audits npm high/critical advisories | Pin third-party Actions to reviewed commit SHAs and resolve remaining moderate transitive advisories |

## Required console and deployment actions

1. Rotate all credentials exposed in git history.
2. Create separate development, staging, and production Firebase projects.
3. Deploy `database.rules.json` and test it in the Firebase Emulator Suite.
4. Deploy `functions/` with `npm ci && npm run build`.
5. Configure Flutterwave secrets only in Functions Secret Manager.
6. Configure Gemini secrets only in Functions Secret Manager.
7. Enable App Check, Crashlytics, API restrictions, billing alerts, and quotas.
8. Complete KYC/AML, payment-provider, privacy, and incident-response review.
9. Reconcile legacy floating-point `/users/{uid}/balance` records and migrate them
   to per-currency `balanceMinor` wallets before any production debit path is
   enabled.
10. Configure scheduled Dependabot updates and keep npm, Pub, and GitHub Actions
    dependency PRs reviewed.

## Current limitations — do not treat as production approval

- The app currently displays and collects NGN in its Nigerian payment screens.
  The money value model can represent ISO 4217 currencies and exponent rules,
  but this does not mean Flutterwave or any other provider supports settlement
  in every currency, nor that all screens have a currency selector.
- No FX conversion, exchange-rate source, multi-currency settlement, refund
  processor, payment webhook, or reconciliation pipeline is implemented.
- The wallet debit callable is a narrow scaffold, not a complete financial
  service. It must not be used to debit customer funds until a server-owned,
  verified transaction/fulfilment workflow authorizes the debit.
- Firebase Emulator Suite tests for Realtime Database and Storage rules are
  still required. Checked-in rules are not deployed until an operator deploys
  them to the correct Firebase project.
- Firebase/Gemini credentials exposed in historical commits cannot be rotated
  by a source-code change; rotate them in the provider consoles and inspect
  their usage.
- The Firebase API keys in `firebase_options.dart` are client identifiers and
  cannot be treated as server secrets. Restrict APIs, enable App Check, and
  apply quota/billing alerts.
