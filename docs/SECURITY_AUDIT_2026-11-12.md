# Flutter security findings and fix plan — 2026-11-12

The complete backend-and-frontend assessment is in [the security audit](../../genie-backend/docs/SECURITY_AUDIT_2026-11-12.md). It includes evidence, severity, backend interactions, dependency checks, deployment questions and a phased fix plan.

The Flutter working tree was reviewed at HEAD `bb7c8d516de9ce065503ac28c7320c700555254f`, including existing uncommitted changes. Application code was not changed by the audit.

| Priority | Finding | Smallest complete fix |
| --- | --- | --- |
| High — F03 | Late responses can repopulate a cleared API cache or save one account's profile under the next account's persistent key. Both paths were reproduced. | Capture account/session generation before requests; bind cache keys and persistent writes to it; discard responses after a session change. Reach profile, chat, feed, owned listings and favourites. Clearing once at logout is insufficient. |
| Medium — F04 | Saved chat previews contain base64-readable message text and attachment keys in SharedPreferences. | Stop persisting full message envelopes/keys there; if offline previews are retained, encrypt them using an account-scoped key in secure storage. Purge obsolete plaintext copies during upgrade/logout. |
| Medium — F05/F06 | Backend first-password and publisher-contact contracts expose security/privacy gaps that Flutter UI restrictions do not prevent. | Restrict first-password creation server-side, preserve protected password change, and show only explicitly published contacts. Update related models/empty states/localizations after the backend contract is fixed. |
| High release risk — F07 | The backend can simulate a successful payment under a production default, while `PaymentCheckout` drops `isSimulation`. | Fail closed server-side and preserve explicit simulation state through receipts/outcomes/admin income. The unfinished live adapter must not be presented as a working bank integration. |

F03 can display another account's private data and misidentify the account in the UI; it does not turn a fabricated/decoded role into a valid backend admin token. F04 requires access to app storage or a relevant backup; ordinary unrelated apps remain subject to OS sandboxing.

Additional source review covered token storage/renewal, admin link routing, attachment crypto/downloads, notification navigation, Android permissions/exported components/lock-screen calls, iOS ATS and associated domains, web scripts, and release signing configuration. Existing Android backup disabling, restricted loopback cleartext exceptions and secure token storage were observed. Real-device and deployed-provider behavior remain unverified.

Validation:

- Full existing Flutter suite: **1,454 passed, 36 failed**. Sampled failures include icon finders no longer matching the changed widgets; not all failures were diagnosed. [Failure names and paths](../../genie-backend/docs/security-audit-2026-11-12/validation-summary.json) are preserved. The suite is not green.
- [Four local diagnostic probes](security_audit_2026_11_12_test.dart): **all passed**, reproducing the cache leaks and readable saved chat content, with negative controls. A passing diagnostic means the bug is present, not fixed.
- OSV returned no advisory matches for 262 locked hosted Dart packages. Native Gradle/CocoaPods dependencies and CDN JavaScript were not included.
- A historical private-key file was found in Git history. Its fingerprint and context are documented as H03 in the main report; no key contents were reproduced or used. Current backend RS256 verification does not establish any current use for that old Ed25519 key.

Run the local probes from this repository:

```powershell
flutter test --no-pub docs/security_audit_2026_11_12_test.dart --reporter expanded
```

Fix F03 first, then F04 alongside the backend session/identity changes. Convert each probe into a no-leak/denial regression after implementing its repair. Keep the mandatory admin email-link step. Do not delete user history, rotate production credentials or change external services as part of this documentation task.

Not checked: real Android/iOS behavior, installed app contents, native dependency advisories, cloud restrictions or production exploitability. Credential use, external setup and irreversible actions still require confirmation.


## Remediation follow-up (2026-11-13)

See [implemented fixes, tests and release limits](SECURITY_REMEDIATION_2026-11-13.md). Original diagnostic results above remain historical, not current acceptance evidence.
