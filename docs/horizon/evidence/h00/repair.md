# H00 repair — exact protected inventory and SDK discovery

Date: 2026-10-30 UTC
Scope: Correct the independent-review `SPEC_FAIL` without changing product source, workflow, credentials, containers, databases, tunnels, or live services.

## Corrected protected inventory entry

`RESEARCH_RELEASE.md` was recomputed from the repository with `sha256sum` and `wc -c`. The verified value is:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `RESEARCH_RELEASE.md` | `dd7b73c5c46d794cd6f57146887333c7336670b461686a40a36df2c1d6c0717b` | 4247 |

This replaces only the erroneous `dd7bbf6c...` value in `preflight.md`; `RESEARCH_RELEASE.md` itself was not modified.

## Fresh inventory verification

The verifier compared generated SHA-256 and byte counts against all 13 protected pre-evidence paths, then checked the scheduler snapshot, JavaScript syntax through stdin, and whitespace. Exit code: `0`.

```text
PASS inventory[1] backend/src/utils/scheduler.js sha256=26b5f6aaaf21a3d45bdc9f63d5795b0d49fdca358ca8b4a0f32e53db4536ffce bytes=1805
PASS inventory[2] N8N_REBUILD_PROMPT.md sha256=b2ac4b3475f87c153d777ef319334a5e91fb0ea9514858ce37a66e69906dec1c bytes=5835
PASS inventory[3] RESEARCH_RELEASE.md sha256=dd7b73c5c46d794cd6f57146887333c7336670b461686a40a36df2c1d6c0717b bytes=4247
PASS inventory[4] backend/scripts/test-research-workflow.cjs sha256=56725b711cca1ac144c1a6f44031dcc8302b857d4d6cba46a69e927286230faa bytes=3267
PASS inventory[5] n8n-workflow.json sha256=bed7bb0c76b7bf9d64b5a1a39c01f08a7cee1606f9121a7cce44b8a83dab9c63 bytes=50808
PASS inventory[6] docs/horizon/CONTRACTS.md sha256=aae104555a4f5791be1d8a5df3053dbf296145d8a398ae6f3014440c2f95980a bytes=23332
PASS inventory[7] docs/horizon/ORCHESTRATOR.md sha256=02ab7d9bf2fc08412d924a95da960c72cf4ac4518cfddca121519a83eb207137 bytes=7323
PASS inventory[8] docs/horizon/README.md sha256=84bbf6c9f5bf2a15b08cce63365a211bfa65b64453144d4326d71ee23740a295 bytes=3350
PASS inventory[9] docs/horizon/SOURCES.md sha256=4476365e93750c2bd9dc6eb3efcee0289661f65cc4176932b980ef09e1d49e80 bytes=4192
PASS inventory[10] docs/horizon/SPEC.md sha256=331e81cfbcafe2a5241484a9c47990030c69dcf3bf1de1c279331158ac8aa0e9 bytes=23583
PASS inventory[11] docs/horizon/TASKS.md sha256=76a611199fce7f2349baeabbf33e6d420b96152907dccab88b1256a230c1da15 bytes=34430
PASS inventory[12] docs/horizon/task-graph.json sha256=447b067747044879fd050bcbcfaad05375d7d093c5af49687e59acf9722c41e8 bytes=60142
PASS inventory[13] docs/horizon/validation.md sha256=71bce7e87d51787754d58ccd8f604f3436b67ea50e3d3dd080189ba9ac534388 bytes=3742
PASS inventory-count=13
PASS scheduler baseline byte-for-byte match
PASS scheduler baseline syntax via stdin
PASS git diff whitespace checks
```

The protected scheduler source remains byte-for-byte equal to `docs/horizon/evidence/h00/scheduler.js.baseline`. The repair did not alter either scheduler file.

## Second preflight: read-only SDK discovery

Discovery used no install, download, image pull, or container command.

```text
ABSENT PATH flutter
ABSENT PATH dart
ABSENT PATH sdkmanager
ABSENT PATH avdmanager
ABSENT PATH adb
ABSENT standard /opt/flutter/bin/flutter
ABSENT standard /opt/flutter/bin/dart
ABSENT standard /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager
ABSENT standard /opt/android-sdk/platform-tools/adb
ABSENT standard /usr/local/flutter/bin/flutter
ABSENT standard /usr/local/flutter/bin/dart
ABSENT standard /usr/local/bin/flutter
ABSENT standard /usr/local/bin/dart
ABSENT standard /usr/local/android-sdk/cmdline-tools/latest/bin/sdkmanager
ABSENT standard /usr/local/android-sdk/platform-tools/adb
ABSENT standard /home/ubuntu/flutter/bin/flutter
ABSENT standard /home/ubuntu/flutter/bin/dart
ABSENT standard /home/ubuntu/development/flutter/bin/flutter
ABSENT standard /home/ubuntu/development/flutter/bin/dart
ABSENT standard /home/ubuntu/Android/Sdk/cmdline-tools/latest/bin/sdkmanager
ABSENT standard /home/ubuntu/Android/Sdk/platform-tools/adb
ABSENT CI .github
ABSENT CI .gitlab-ci.yml
ABSENT CI azure-pipelines.yml
PASS H00 repair verification (toolchain outcome: no approved reusable SDK path found)
```

The project recipe `frontend/Dockerfile` uses `ghcr.io/cirruslabs/flutter:stable`. It is not an approved reusable toolchain because the image is unpinned and this card forbids image pulls and container lifecycle. Environment provisioning of a Flutter SDK compatible with `frontend/pubspec.lock` remains the explicit blocker for Flutter/Dart/device validation.

## Verification command

```text
sha256sum <each protected path>
wc -c <each protected path>
cmp -s backend/src/utils/scheduler.js docs/horizon/evidence/h00/scheduler.js.baseline
node --check < docs/horizon/evidence/h00/scheduler.js.baseline
git diff --check
git diff --check -- backend/src/utils/scheduler.js
command -v flutter dart sdkmanager avdmanager adb
```
