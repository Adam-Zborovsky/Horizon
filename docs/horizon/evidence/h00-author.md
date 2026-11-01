# H00 author evidence

- Author package: H00 — Exact baseline and toolchain preflight.
- Changed paths: `docs/horizon/evidence/preflight.md`, `docs/horizon/evidence/h00-author.md`, `docs/horizon/evidence/h00/repair.md`, `docs/horizon/evidence/h00/scheduler.js.baseline`.
- No source, workflow, profile, credential, runtime, database, container, tunnel, or live API path was changed.
- Evidence: `preflight.md` records the exact branch/HEAD, protected dirty/untracked inventory with hashes and byte counts, Node/deployment-runtime mismatch, actual Flutter/Dart/device absence, lock resolution, safe test results, ownership locks, and primary/admin gates.
- Commands and exit codes: `npm test --prefix backend` exited `1` because the package script is `echo "Error: no test specified" && exit 1`; `node --test backend/test/*.test.cjs` exited `0` with zero tests; `flutter --version`, `dart --version`, and `flutter devices` each exited `127` because no executable is on PATH; `git diff --check -- backend/src/utils/scheduler.js` exited `0`.
- Limitations: Flutter/Dart/Android/device capabilities are unavailable. Live workflow identity/version cannot be verified without primary-controlled credential use; none was acquired or read. The frontend build image is unpinned (`flutter:stable`).
- Next ready package: H01, limited to its declared executable contract and offline fixture paths. H02 and later Flutter work remain gated on an approved SDK/device capability.

## Repair after independent specification review

- Corrected the `RESEARCH_RELEASE.md` inventory SHA-256 from a fresh programmatic computation to `dd7b73c5c46d794cd6f57146887333c7336670b461686a40a36df2c1d6c0717b`; its verified size remains `4247` bytes.
- Re-verified all 13 protected inventory entries programmatically: every SHA-256 and byte count matches, including the protected scheduler snapshot check and whitespace checks.
- Completed the required read-only SDK discovery beyond PATH. No approved reusable Flutter/Dart/Android executable or repository CI recipe exists; `frontend/Dockerfile` is not usable as evidence because it references an unpinned image and no image operation is authorized.
- Durable verification output and exact searched paths are in `docs/horizon/evidence/h00/repair.md`. No product source, workflow, credential, database, container, tunnel, or live API path was changed by this repair.
