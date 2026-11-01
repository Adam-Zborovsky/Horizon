# H00 preflight — exact baseline and toolchain

Date: 2026-10-30 UTC
Repository: `/home/ubuntu/apps/Horizon`

## Repository baseline

- Repository root: `/home/ubuntu/apps/Horizon`
- Branch: `main`
- HEAD: `9fbb26b5519889e0816720530dd60c204dda2bf2`
- No nested `AGENTS.md`, `CLAUDE.md`, or `.cursorrules` was present at the repository root.
- No source, workflow, profile, credential, database, container, tunnel, or live endpoint was changed during this preflight.

### Protected pre-existing work

The following paths were dirty before H00 evidence was written. They are protected: no reset, clean, checkout, commit, overwrite, or live application action was performed.

| Git status | Path | SHA-256 | Bytes |
|---|---|---|---:|
| modified | `backend/src/utils/scheduler.js` | `26b5f6aaaf21a3d45bdc9f63d5795b0d49fdca358ca8b4a0f32e53db4536ffce` | 1805 |
| untracked | `N8N_REBUILD_PROMPT.md` | `b2ac4b3475f87c153d777ef319334a5e91fb0ea9514858ce37a66e69906dec1c` | 5835 |
| untracked | `RESEARCH_RELEASE.md` | `dd7b73c5c46d794cd6f57146887333c7336670b461686a40a36df2c1d6c0717b` | 4247 |
| untracked | `backend/scripts/test-research-workflow.cjs` | `56725b711cca1ac144c1a6f44031dcc8302b857d4d6cba46a69e927286230faa` | 3267 |
| untracked | `n8n-workflow.json` | `bed7bb0c76b7bf9d64b5a1a39c01f08a7cee1606f9121a7cce44b8a83dab9c63` | 50808 |
| untracked | `docs/horizon/CONTRACTS.md` | `aae104555a4f5791be1d8a5df3053dbf296145d8a398ae6f3014440c2f95980a` | 23332 |
| untracked | `docs/horizon/ORCHESTRATOR.md` | `02ab7d9bf2fc08412d924a95da960c72cf4ac4518cfddca121519a83eb207137` | 7323 |
| untracked | `docs/horizon/README.md` | `84bbf6c9f5bf2a15b08cce63365a211bfa65b64453144d4326d71ee23740a295` | 3350 |
| untracked | `docs/horizon/SOURCES.md` | `4476365e93750c2bd9dc6eb3efcee0289661f65cc4176932b980ef09e1d49e80` | 4192 |
| untracked | `docs/horizon/SPEC.md` | `331e81cfbcafe2a5241484a9c47990030c69dcf3bf1de1c279331158ac8aa0e9` | 23583 |
| untracked | `docs/horizon/TASKS.md` | `76a611199fce7f2349baeabbf33e6d420b96152907dccab88b1256a230c1da15` | 34430 |
| untracked | `docs/horizon/task-graph.json` | `447b067747044879fd050bcbcfaad05375d7d093c5af49687e59acf9722c41e8` | 60142 |
| untracked | `docs/horizon/validation.md` | `71bce7e87d51787754d58ccd8f604f3436b67ea50e3d3dd080189ba9ac534388` | 3742 |

`backend/src/utils/scheduler.js` differs from `HEAD` (`8` added lines, `5` removed lines). `git diff --check -- backend/src/utils/scheduler.js` exited `0`. Its inspected source was safe to preserve and is stored byte-for-byte as `docs/horizon/evidence/h00/scheduler.js.baseline`; the file is not a replacement for the working copy.

## Toolchain and safe baseline checks

| Check | Actual result | Gate |
|---|---|---|
| Host Node | `v22.22.2` | Host differs from deployment runtime; do not treat host-only Node results as deployment validation. |
| Host npm | `10.9.7` | Available. |
| Backend deployment image | `backend/Dockerfile:1` is `node:18-alpine` | Run backend acceptance on Node 18-compatible tooling/CI before approval. |
| Backend test script | `npm test --prefix backend` exited `1`: `Error: no test specified` | Existing package test script is intentionally non-testable; H01 must add/run its named Node test file. |
| Planned backend test glob | `node --test backend/test/*.test.cjs` exited `0`, TAP reported `0` tests | No backend test files currently exist; this is not a green suite. |
| Flutter SDK | `flutter --version` exited `127`: `flutter: command not found` | BLOCKER for Flutter analyze/test/build and mobile/web evidence. Do not install an arbitrary SDK. |
| Dart SDK | `dart --version` exited `127`: `dart: command not found` | Same Flutter toolchain gate. |
| Flutter devices | `flutter devices` exited `127`: `flutter: command not found` | No device/emulator evidence available. |
| Android environment | `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `JAVA_HOME` unset | Android build/device capability unavailable in this environment. |
| Flutter lock | `frontend/pubspec.lock` resolves `fl_chart` `1.1.1`; SDK constraints are Dart `>=3.11.0 <4.0.0`, Flutter `>=3.38.4` | H02 must use versioned locked package source after an approved Flutter SDK is supplied. |
| Frontend build image | `frontend/Dockerfile:2` uses `ghcr.io/cirruslabs/flutter:stable` | Image is unpinned; its actual SDK must be inspected/reconciled with the lock constraints before build acceptance. |

### Read-only SDK discovery repair

The initial PATH result alone was insufficient. A second read-only search checked PATH commands plus conventional Flutter/Dart/Android executable locations under `/opt`, `/usr/local`, and `/home/ubuntu` development paths. `flutter`, `dart`, `sdkmanager`, `avdmanager`, and `adb` are absent on PATH. No executable was present at any checked conventional path: `/opt/flutter/bin/{flutter,dart}`, `/opt/android-sdk/{cmdline-tools/latest/bin/sdkmanager,platform-tools/adb}`, `/usr/local/flutter/bin/{flutter,dart}`, `/usr/local/bin/{flutter,dart}`, `/usr/local/android-sdk/{cmdline-tools/latest/bin/sdkmanager,platform-tools/adb}`, `/home/ubuntu/{flutter,development/flutter}/bin/{flutter,dart}`, or `/home/ubuntu/Android/Sdk/{cmdline-tools/latest/bin/sdkmanager,platform-tools/adb}`. The conventional directories `/opt/flutter`, `/opt/android-sdk`, `/usr/local/flutter`, `/usr/local/android-sdk`, `/home/ubuntu/development`, `/home/ubuntu/dev`, `/home/ubuntu/src`, `/home/ubuntu/flutter`, and `/home/ubuntu/Android/Sdk` are absent.

There is no repository CI recipe (`.github/`, `.gitlab-ci.yml`, and `azure-pipelines.yml` are absent). The only project build recipe found is `frontend/Dockerfile`, which builds with the unpinned `ghcr.io/cirruslabs/flutter:stable` image. Image pull/inspection and container lifecycle are outside this worker card, so it is not an approved reusable SDK path. Result: no approved reusable Flutter/Dart/Android SDK exists in this environment; provisioning a version satisfying the lock constraints remains an explicit environment blocker. No install, download, image pull, or container action occurred. Full command output is retained in `docs/horizon/evidence/h00/repair.md`.

Commands executed without live calls:

```text
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1 --untracked-files=all
node --version
npm --version
flutter --version
dart --version
flutter devices
npm test --prefix backend
node --test backend/test/*.test.cjs
sha256sum <protected paths>
wc -c <protected paths>
git diff --numstat -- backend/src/utils/scheduler.js
git diff --check -- backend/src/utils/scheduler.js
```

## Workflow and live-operation gate

`n8n-workflow.json` is a protected, untracked local export. It was not parsed, copied into this evidence, compared to a live workflow, published, or modified. Live workflow identity/version comparison requires primary-controlled read access using existing approved credentials. H00 neither acquired credentials nor initiated that access.

Provider credentials, scoped automation credential provisioning, live workflow publication, migration, database/volume work, deployment, tunnels/DNS, paid model/data calls, and license acceptance remain primary/admin-only gates.

## File ownership and locks

- H00 owns only this preflight evidence and `docs/horizon/evidence/h00/` baseline artifacts.
- H01 owns canonical contract schemas and offline fixtures under its declared new paths.
- H10 exclusively owns `n8n-workflow.json`, `backend/src/utils/scheduler.js`, and `backend/scripts/test-research-workflow.cjs`; its preflight inputs must match the protected hashes above before editing.
- H11 owns new Flutter domain/generated outputs and serializes generation. No worker hand-edits generated files.
- H15 is the sole integrator for shared routers, manifests, existing Flutter models/screens, `frontend/pubspec.yaml`, and `frontend/pubspec.lock`.
- No package may edit another package's allowlisted file; contract changes require dependent fixtures/tasks to be updated before source work resumes.

## Dependency and approval gates

1. H01 can begin using the frozen version-1 contract and offline fixtures; its tests must be real Node tests, not `npm test`.
2. H02/H11/H13/H14/H15/H17 require a Flutter/Dart toolchain satisfying the lock constraints. H02 also requires an actual mobile/emulator or device for mobile interaction acceptance.
3. Retain existing `fl_chart` for H02. Any renderer replacement requires documented H02 failure plus Adam approval. Syncfusion additionally requires explicit license approval; no new dependency is preapproved.
4. Live workflow identity/version and all production operations are pending primary-controlled read/approval. Local exports and source files are not proof of published workflow state.

## Result

H00 preflight is complete as evidence only. Backend baseline verification is constrained by a non-test package script and zero existing Node test files. Flutter/mobile/web verification is blocked by absent SDKs and device tooling. No unavailable capability is claimed as passed.
