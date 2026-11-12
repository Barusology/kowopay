# Security Audit — KowoPay

**Date:** 2026-11-12
**Scope:** Flutter client, Firebase Realtime Database, Firebase Storage, Cloud Functions, Firebase Hosting, Android/web configuration, repository and git history.

This audit followed the hardening pass applied to the client and adds the
server-side layer (rules + functions) that was previously missing. Nothing in
this report replaces a professional penetration test before handling real money.

---

## 1. Executive summary

The app previously relied entirely on client-side checks: any signed-in user
could write wallet balances, forge transactions, call paid AI APIs with a key
embedded in the binary, and reach an admin screen by navigating to it. That is
now fixed in two layers:

- **Firebase Rules** deny client writes to money fields, the ledger and
  notifications, and isolate every user to their own subtree.
- **Cloud Functions** own balance movement, AI access, admin claims and the
  payment webhook, all behind App Check-independent ID-token verification,
  server-side rate limits and strict input validation.

One **critical issue remains in git history**: a Gemini API key was committed
and pushed. It is gone from the current tree but must be rotated. History was
not rewritten because that requires explicit owner approval (see §6).

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| 1 | Critical | Gemini API key committed to history | **Action required: rotate key** |
| 2 | High | Client could write `balance` and `transactions` | Fixed |
| 3 | High | Unverified email addresses could use financial screens | Fixed |
| 4 | High | AI/payment keys and a fake withdrawal flow shipped in the client | Fixed |
| 5 | Medium | Admin console guarded by UI only | Fixed (claim + rules) |
| 6 | Medium | Web sessions persisted in `localStorage` | Fixed (`sessionStorage`) |
| 7 | Medium | Uploads trusted filename/MIME | Fixed (magic bytes + rules) |
| 8 | Medium | Webhook had no signature check or replay protection | Fixed |
| 9 | Medium | No rate limiting on auth/AI/money endpoints | Fixed (client + server) |
| 10 | Low | User-safe error handling and logging | Fixed (`SecureLog`, mapped errors) |
| 11 | Low | Missing HTTP security headers | Fixed (`firebase.json`) |
| 12 | Low | Android backups and cleartext traffic allowed | Fixed |
| 13 | Low | Unused packages, dead screen, stray tracked files | Fixed |
| — | Info | Firebase API keys present in client config | Expected; restrict in Cloud Console |

---

## 2. Repository and secrets

- **No `.env` file has ever been tracked.** `git ls-files` returns no secrets.
- `.gitignore` now blocks `.env`, `.env.*` (except examples), `functions/.env*`,
  service-account JSON, keystores and `key.properties`.
- Stray artifacts removed: `Docker Desktop.lnk`, a duplicate
  `android/app/google-services (4).json`, and the unused
  `lib/screens/tabs/history_tab.dart`.
- Current-tree secret scan: no Gemini, Flutterwave secret or webhook hash is
  present. The only `AIza…` values are Firebase client API keys, which are
  public identifiers (see §5).
- `GEMINI_API_KEY`, `FLUTTERWAVE_SECRET_KEY` and `FLUTTERWAVE_SECRET_HASH` are
  read only inside Cloud Functions via Firebase secrets/params.

### Exposed key in history — rotate now

A Google AI Studio key beginning `AIzaSyBog1…` was committed in
`lib/providers/core_providers.dart` and appears in commits `398681b` and
`49e8b29`. Treat it as compromised:

1. Revoke it in Google AI Studio / Google Cloud Console.
2. Create a new key with the Generative Language API restricted to this project.
3. Store it with `firebase functions:secrets:set GEMINI_API_KEY`.
4. Redeploy `aiAdvice`.

Anyone with a clone can still read the old key, which is why rotation — not a
history rewrite — is the required first step.

---

## 3. Client hardening

| Area | Control |
|------|---------|
| Authentication | Firebase Auth email/password; hashing and credential storage are handled by Firebase, not by app code |
| Email verification | `main.dart` blocks every screen behind `emailVerified`; `VerifyEmailScreen` has a 60 s resend cooldown |
| Token storage | Web uses `Persistence.SESSION` (dies with the tab); mobile uses Android Keystore / iOS Keychain via the Firebase SDK |
| Session checks | ID token is force-refreshed when the app resumes; revoked/disabled accounts are signed out |
| Admin | `adminRoleProvider` reads the force-refreshed `admin` custom claim; the admin screen also degrades to “access denied” on rules errors |
| Input validation | `Validators` + `InputSanitizer` bound every form field (email, password strength, 10-digit NUBAN, NGN amounts, name, phone) |
| Path injection | Every UID and record key is regex-validated before being interpolated into a Firebase path |
| Uploads | Client sniffs JPEG/PNG/WebP magic bytes, caps at 5 MB, and rejects non-allow-listed hosts on the returned URL |
| XSS / redirects | No HTML is rendered; `mailto:`/`tel:` are scheme-allow-listed; images accept only HTTPS Firebase Storage hosts |
| Logging | `SecureLog` prints in debug only; user-facing errors are mapped to generic messages |
| Rate limits | Login lockout after 5 failures, deposit/airtime/withdraw throttles, AI message cap |
| Payments | Public Flutterwave key injected via `--dart-define`; wallet is credited only by the signed webhook |
| Money movement | Client has no balance/ledger write path — `WalletService` calls Cloud Functions |

Known browser limitation: a token in `sessionStorage` is still readable by a
successful XSS. The app eliminates HTML injection and ships a strict CSP to
reduce that risk. App Check is recommended as the next step.

---

## 4. Server-side enforcement

### `database.rules.json`

- Default deny at the root; all users are confined to `users/{their-uid}`.
- Only an admin custom claim can read the `/users` list.
- Writable profile fields: `name`, `phone`, `photoUrl` (validated host/length),
  plus one-time `email`, `balance = 0` and `createdAt` initialisation.
- `balance` cannot be changed after initialisation; `transactions` cannot be
  written by clients; `notifications` allow only flipping `read`.
- `rateLimits` and `webhookEvents` are server-only.

### `storage.rules`

- `profile_images/{uid}/avatar` only: owner-only read/write/delete,
  `image/(jpeg|png|webp)`, maximum 5 MB.
- All other paths denied.

### `functions/index.js`

| Function | Enforcement |
|----------|-------------|
| `aiAdvice` | Signed-in + verified email, 20 calls/hour, 500-char input, server-held Gemini key, system prompt blocks prompt-injection and credential requests, provider errors are not leaked |
| `purchaseAirtime` | Verified email, 10/hour, carrier allow-list, phone regex, amount ₦50–₦50,000, atomic debit + ledger + notification |
| `requestWithdrawal` | Verified email, 3/hour, 10-digit NUBAN, bank-code regex, amount ₦500–₦500,000, atomic debit, payout marked `pending` |
| `flutterwaveWebhook` | `verif-hash` compared in constant time, GET rejected, NGN + successful status + amount bounds, optional provider re-verification, idempotent credit keyed by transaction id, account matched by verified email |
| `setAdminClaim` | Existing `admin` claim required; one-time self-bootstrap via `BOOTSTRAP_ADMIN_EMAIL`; demotion revokes refresh tokens |

Bootstrap procedure for the first admin:

```bash
# functions/.env (never commit)
BOOTSTRAP_ADMIN_EMAIL=you@yourdomain.com
firebase deploy --only functions
# Sign in with that account, then call setAdminClaim for your own uid.
# Remove BOOTSTRAP_ADMIN_EMAIL and redeploy immediately after.
```

---

## 5. Platform configuration

- `firebase.json`: CSP, HSTS, `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Permissions-Policy`, COOP; SPA rewrite; static asset
  caching with `index.html` set to `no-cache`.
- `AndroidManifest.xml`: `allowBackup=false`, `usesCleartextTraffic=false`,
  `INTERNET` permission declared for release builds.
- **Firebase API keys** in `firebase_options.dart`, `google-services.json` and
  `GoogleService-Info.plist` are project identifiers, not secrets. Restrict each
  key in Google Cloud Console to the required APIs (Identity Toolkit,
  Realtime Database, Storage, Cloud Functions) and, for the browser key, to the
  app's domains. Rules are the real protection.
- Debug mode is off in release (`kReleaseMode`); DevicePreview is excluded from
  release and web builds; ads use test IDs until production IDs are injected.

---

## 6. History rewrite decision

The leaked key is still reachable in the two commits listed above. A rewrite
(`git filter-repo` + force-push) would break clones and open PRs and could
destroy collaborators' work, so it was **not** performed. Rotation removes the
value of the leaked key without that risk. If a rewrite is still required:

1. Rotate the key first.
2. Freeze pushes and back up the repository.
3. Run `git filter-repo --replace-text` and force-push with `--force-with-lease`.
4. Ask every collaborator to re-clone.
5. Re-scan history before making the repository public again.

---

## 7. Residual risks and next steps

1. **Enable MFA** in Firebase Authentication (Identity Platform). For
   high-value actions, enforce a second factor by checking
   `auth.token.firebase.sign_in_second_factor` in callables.
2. **Enable App Check** (reCAPTCHA Enterprise on web, Play Integrity/App Attest
   on mobile) and require it in callables and database rules.
3. **Payout and airtime fulfilment**: withdrawals are debited and marked
   `pending`; a provider payout call and reconciliation job are still required
   before real funds are promised.
4. **Webhook**: set `FLUTTERWAVE_SECRET_HASH` and `FLUTTERWAVE_SECRET_KEY` before
   accepting live payments; keep the webhook endpoint on the deployed function
   URL, not a custom proxy that strips headers.
5. **CSP**: verify Flutter web (CanvasKit/wasm), Firebase Auth and Flutterwave
   checkout still load after deployment; tighten any directive that was opened
   for compatibility.
6. **Dependency hygiene**: run `flutter pub outdated` each release, keep the
   Flutter SDK patched, and enable Dependabot for `functions/`.
7. **Monitoring**: alert on repeated `permission-denied`, `resource-exhausted`
   and webhook verification failures; review `webhookEvents` for anomalies.
8. **Data protection**: define retention for ledger and notification records,
   and add account deletion that removes `users/{uid}` and the avatar object.

---

## 8. Deploy checklist

```bash
# 1. Secrets (one-time)
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set FLUTTERWAVE_SECRET_HASH
firebase functions:secrets:set FLUTTERWAVE_SECRET_KEY

# 2. Server
firebase deploy --only database,storage,functions

# 3. Web
flutter build web --release --dart-define-from-file=.env
firebase deploy --only hosting

# 4. Verify
firebase emulators:start --only database
flutter test
```

Verification performed for this audit:

- `flutter analyze` — no issues.
- `flutter test` — 13/13 passing.
- `node --check functions/index.js` — clean.
- JSON configs parse.
- Current-tree secret scan — no private keys.

Rules should also be exercised in the Firebase Emulator with an unverified
user, a verified user and an admin claim before going live.
