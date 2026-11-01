# H11 — Repair: research_repository getLatest wire drift (latest_assessment / run_state)

Task: t_fa26099c · Author: worker (zai glm-5.3-flash) · 2026-11-01 · Workspace `/home/ubuntu/apps/Horizon` (branch main, source-only, no commit/push)

## 1. Defect

The Flutter client's `getLatest` modeled `GET /api/v1/research/positions/:id/latest` as an
assumed envelope `{latest: {assessment, run}}` (`research_models.dart` pre-repair:
`ResearchLatest.fromJson` read `json['assessment']` and `json['run']`).

The real backend wire (canonical side, CONTRACTS §2/§9) is a **top-level object** —
`backend/src/features/research/research.routes.js:67-74`:

```js
res.status(200).json({
  position_id: state.position_id,
  latest_assessment: toPublicAssessmentView(state.latest_assessment),
  run_state: {
    last_success: state.last_success,
    latest_attempt: state.latest_attempt,
  },
});
```

Live-verified behavioral consequence (corrects the card's "throws" description): since the
real response IS a top-level map, `_requireObject(decoded, 'latest')` passed, and the old
`ResearchLatest.fromJson` silently returned `ResearchLatest(assessment: null, run: null)`
on every successful call — the primary research-state read path always rendered the empty
state. No key named `latest` exists anywhere on the wire.

## 2. Root cause of the drift (H15B run-251 finding, resolved)

The card's handoff asserted `run_state.last_success/latest_attempt` "carry run views
(toPublicRunView …)". Source inspection shows they do **not**: the routes file wraps only
`queueRun`/`getRun` payloads in `toPublicRunView`. For `/latest`, the service returns
projections — `backend/src/features/research/research.service.js:813-832`:

- `last_success` (`research.service.js:816-822`): `{run_id, status, assessment_id, evidence_snapshot_id, finished_at}` or null
- `latest_attempt` (`research.service.js:823-831`): `{run_id, status, stage, started_at, finished_at, error_code, deadline_at}` or null

These are partial projections — no `owner_id_internal`, `position_revision`,
`idempotency_key`, `created_at`, `deadline_at`, `retry_count` — so `ResearchRun.fromJson`
could never parse them. The backend is canonical; the client mirrors the projections.

## 3. Fix

- `frontend/lib/src/features/research/research_models.dart:1444-1533` — `ResearchLatest`
  reshaped to the real wire (`positionId`, `latestAssessment`, `lastSuccess`,
  `latestAttempt`); two new projection models `ResearchLastSuccess` (models:1484) and
  `ResearchLatestAttempt` (models:1509) with per-field parsing via the shared contract
  helpers (`requireOpaqueId`, `RunStatus.parse`, `optionalOpaqueId`,
  `optionalBoundedText`, `optionalUtcTimestamp`, `requireUtcTimestamp`). `run_state` is
  required to be an object (models:1461-1463); absent/null entries inside it yield null
  fields, never throws (CONTRACTS §9).
- `frontend/lib/src/features/research/research_repository.dart:63-73` — `getLatest`
  doc comment corrected; `_requireObject` label changed `'latest'` → `'latest state'`
  (error text only). Parsing call remains `_requireObject(decoded)` + `ResearchLatest.fromJson`
  — the top-level object is now the modeled shape.
- A model tweak was required (allowlisted): the run_state entries are not `ResearchRun`
  wire-compatible, so repository-side parsing alone could not reconcile the wire.

### Per-field wire trace (routes → repository → model)

| Wire field (source line) | Client parse (file:line) | Model field |
|---|---|---|
| `position_id` (routes:68; service:814) | models:1456 `requireOpaqueId` | `ResearchLatest.positionId` |
| `latest_assessment` (routes:69; service:815 `#assessmentView`+`toPublicAssessmentView` strips `owner_id_internal`) | models:1457-1458 `_optionalObject` → `ResearchAssessment.fromJson` (models:1459-1460) | `ResearchLatest.latestAssessment` (nullable) |
| `run_state` (routes:70) | models:1461-1463 required object | container |
| `run_state.last_success` (routes:71; service:816-822) | models:1467-1469 → `ResearchLastSuccess.fromJson` (models:1493) | `ResearchLatest.lastSuccess` (nullable) |
| ↳ `run_id` (service:817) | models:1495 `requireOpaqueId` | `ResearchLastSuccess.runId` |
| ↳ `status` (service:818) | models:1496 `RunStatus.parse` | `ResearchLastSuccess.status` |
| ↳ `assessment_id` (service:819) | models:1497 `optionalOpaqueId` | `ResearchLastSuccess.assessmentId` |
| ↳ `evidence_snapshot_id` (service:820) | models:1498 `optionalOpaqueId` | `ResearchLastSuccess.evidenceSnapshotId` |
| ↳ `finished_at` (service:821) | models:1499 `optionalUtcTimestamp` | `ResearchLastSuccess.finishedAt` |
| `run_state.latest_attempt` (routes:72; service:823-831) | models:1470-1472 → `ResearchLatestAttempt.fromJson` (models:1520) | `ResearchLatest.latestAttempt` (nullable) |
| ↳ `run_id` (service:824) | models:1522 `requireOpaqueId` | `ResearchLatestAttempt.runId` |
| ↳ `status` (service:825) | models:1523 `RunStatus.parse` | `ResearchLatestAttempt.status` |
| ↳ `stage` (service:826) | models:1524 `optionalBoundedText(80)` | `ResearchLatestAttempt.stage` |
| ↳ `started_at` (service:827) | models:1525 `optionalUtcTimestamp` | `ResearchLatestAttempt.startedAt` |
| ↳ `finished_at` (service:828) | models:1526 `optionalUtcTimestamp` | `ResearchLatestAttempt.finishedAt` |
| ↳ `error_code` (service:829) | models:1527 `optionalBoundedText(120)` | `ResearchLatestAttempt.errorCode` |
| ↳ `deadline_at` (service:830) | models:1528 `requireUtcTimestamp` | `ResearchLatestAttempt.deadlineAt` |

`last_success` and `latest_attempt` are kept as **separate truthful states** — distinct
models, distinct fields, never collapsed (service comment research.service.js:811-812: an
existing success is never rewritten by a later failure).

### queueRun / getRun — UNCHANGED (verified correct)

| Endpoint | Wire envelope (source) | Client parse | Verdict |
|---|---|---|---|
| `POST /positions/:id/runs` | `{ run: toPublicRunView(run), idempotent_replay }` (routes:118) | `ResearchRun.fromJson(_requireObject(decoded, 'run'))` (research_repository.dart:103) | matches — untouched |
| `GET /runs/:runId` | `{ run: toPublicRunView(run) }` (routes:130) | `ResearchRun.fromJson(_requireObject(decoded, 'run'))` (research_repository.dart:112) | matches — untouched |

Full run views from these endpoints carry `owner_id_internal` (`toPublicRunView` strips
only `lease_nonce`, routes:35-40); `ResearchRun.fromJson` (models:1310-1311) already
tolerates this — no change made, per the accepted H15B review trace.

## 4. Empty state (CONTRACTS §9)

Absent/null `latest_assessment` and null `run_state.last_success` / `latest_attempt`
yield null fields, not throws. Covered at model level and repository level:
`research_models_test.dart` 'ResearchLatest empty state yields null fields, not throws'
and 'getLatest parses the canonical top-level wire: …'.

## 5. Test fixtures updated (canonical wire, not assumed)

`frontend/test/research_models_test.dart`:
- Repository group 'ResearchRepository — run queueing and pagination': the stale
  `{assessment: null, run: null}` fixture replaced with the canonical top-level wire
  (empty state) plus a populated-state case asserting `last_success` (run-0001,
  succeeded) and `latest_attempt` (run-0002, failed) remain distinct.
- Model group 'Research models — claims, outlooks, overlays, run states': three new
  cases — canonical populated wire, empty state, and drift rejection (the old assumed
  `{assessment, run}` envelope now throws `ContractFormatException` because `run_state`
  is absent).

## 6. Allowlist compliance

Files changed (exactly the allowlist; verified via `git status` — the other modified /
untracked paths in the working tree pre-date this run and belong to other tasks; no
backend file touched):

1. `frontend/lib/src/features/research/research_repository.dart`
2. `frontend/lib/src/features/research/research_models.dart`
3. `frontend/test/research_models_test.dart`
4. `docs/horizon/evidence/h11-repair-latestwire.md` (this file)

## 7. Deferred execution — DEFERRED_TO_DEV_PC

No Flutter/Dart SDK on this server; executed honestly and recorded:

```
$ command -v dart   → dart: command not found
$ command -v flutter → flutter: command not found
```

No Dart test was executed and **no test is claimed PASSED**. Deferred to the dev PC:

- `flutter test test/research_models_test.dart` (frontend/)
- `dart run build_runner build --delete-conflicting-outputs` — REQUIRED: the freezed
  generated file (`research_models.freezed.dart`) is absent from this workspace and the
  `ResearchLatest`/`ResearchLastSuccess`/`ResearchLatestAttempt` shapes changed.
- `git diff --check` on the dev PC checkout (run here: clean).

Static checks done here: zero remaining references to the old `.assessment`/`.run`
fields of `ResearchLatest` across `frontend/lib` (grep verified); imports in the test
file already cover `RunStatus` and the research models/repository.

## 8. SHA-256 of changed files

```
2d1717e1d023f04e908bec4c99ec00bec0c298872c380621333413326866c52b  frontend/lib/src/features/research/research_repository.dart
e115eebf6299089b1396e819343df2cdb1b8a1f9ac53ab6242bdd9e6f3f16711  frontend/lib/src/features/research/research_models.dart
a8a9daa3f056c32f63593320d10ea21c0158dc8d337c021635d52dee44a585c2  frontend/test/research_models_test.dart
```

This evidence file is self-referential and cannot contain its own final hash; its
authoritative SHA-256 is recorded in the task handoff comment. Reviewer: recompute all
hashes on disk.
