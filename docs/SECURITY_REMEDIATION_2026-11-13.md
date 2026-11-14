# Flutter security remediation - 2026-11-13

**Implemented locally, not released.** See the [full security report and coordinated backend rollout](../../genie-backend/docs/SECURITY_REMEDIATION_2026-11-13.md).

- Session generations bind requests, cache writes, refresh/retry and repository results; old-account work cannot replay as a new account.
- Kept API copies are memory-only. Upgrade cleanup removes legacy profile/chat/listing/feed copies, preserving unrelated settings. Offline previews do not survive restart.
- Simulated checkout remains clearly marked through outcome and receipt UI; no real-payment/confirmation-email claim is made.
- Admin password login still requires the email-link second step. Release signing never falls back to debug signing. iOS tokens use device-only unlocked keychain accessibility.
- Existing widget regressions were repaired/updated to current artwork without reverting supplied UI work; corrupted emoji/separators were repaired.

Validation: **1,502 full-suite tests pass**, no skips/failures; analysis has no issues; source/test formatting passes. Final targeted security/auth/payment tests also pass. Evidence: `full_test_verified_2026_11_13.jsonl`, `analyze_security_2026_11_13.txt`, `format_security_2026_11_13.txt`, `security_tests_verified_2026_11_13.txt`. Permanent regressions are in `test/security/` and the relevant storage/network/payment tests. The old audit diagnostic entrypoint delegates to the repaired regression tests.

No signed release, physical-device, OS backup/restore, real bank/push/email/TURN or production-load validation ran. Production backend fixes, migrations and broker provisioning remain pending separate approval; client-only shipping is not full remediation.
