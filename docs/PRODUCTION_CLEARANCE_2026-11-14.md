# Closed testing clearance - 2026-11-14

Fresh automated results: 1,520 Flutter tests passed, zero skipped; formatting and
analysis passed. Production signed/obfuscated AAB built successfully (99.1 MB).

Artifact: `build/app/outputs/bundle/release/app-release.aab`
SHA-256: `a962c20fd4a27a1f50a8bf854f071f2a8bb64e4249b804d5846097e210649cec`
Symbols: `build/symbols/1.0.0+2-clearance-20261114-210658/`
Version: `1.0.0+2`; target SDK: 36; package: `com.sparkbytekh.tilomnov`.

**Not full production clearance.** Highest used Play version code/upload-key match,
exact-artifact installation/upgrade, SMS/OAuth/push and call media on hardware remain
unverified. Backend uses mock checkout; ABA settlement is not implemented. Do not
interpret successful mock purchases as actual bank payment verification.

Backend evidence: `docs/full-flow-2026-11-14/PRODUCTION_CLEARANCE.md` in GenieBackend.
Build/test logs remain under `build/clearance-2026-11-14/` (ignored). No Play upload.
