# Closed testing clearance - 2026-11-14

Fresh automated results: 1,520 Flutter tests passed, zero skipped; formatting and
analysis passed. Production signed/obfuscated AAB built successfully (99.1 MB).

Artifact: `build/app/outputs/bundle/release/app-release.aab`
SHA-256: `877f1daba4666a6733891d26293aeee4e929bd01c4c91efe207fea1a0beea772`
Symbols: `build/symbols/clearance-20261114-205634/`
Version: `1.0.0+1`; target SDK: 36; package: `com.sparkbytekh.tilomnov`.

**Not full production clearance.** Highest used Play version code/upload-key match,
exact-artifact installation/upgrade, SMS/OAuth/push and call media on hardware remain
unverified. Backend uses mock checkout; ABA settlement is not implemented. Do not
interpret successful mock purchases as actual bank payment verification.

Backend evidence: `docs/full-flow-2026-11-14/PRODUCTION_CLEARANCE.md` in GenieBackend.
Build/test logs remain under `build/clearance-2026-11-14/` (ignored). No Play upload.
