# H14 — Author delivery: direct recommendation and multi-horizon research panels

- Task: t_5f43465d (H14), role flutter-research-worker, phase core_source
- Author: worker profile (roster worker/zai/glm-5.3-flash per controller release note 2026-11-01)
- Date: 2026-11-01
- Baseline: branch `main`, dirty/untracked baseline preserved; HEAD unchanged at
  `9fbb26b5519889e0816720530dd60c204dda2bf2`; no branch change, no commits, no
  generated files, no lockfile edits, no new dependency, no secrets.

## 1. Changed and new files (exactly the package allowlist)

| Path | Status | SHA-256 |
|---|---|---|
| `frontend/lib/src/features/research/widgets/research_panel.dart` | NEW | `82653c03b1cddd4f7f8240f2930f955dc0d6a17d04627d845b1e1abe73c01506` |
| `frontend/lib/src/features/research/widgets/outlook_panel.dart` | NEW | `05f0dc545d4ce9d337e42a46f6a2aa357e32d27befa0cbed376cb1b4e0f177e9` |
| `frontend/lib/src/features/research/widgets/evidence_sheet.dart` | NEW | `b9c6fdfbf74aa25e95e46730f1e986babcf7da13df8db7a6feee380acafe85d5` |
| `frontend/test/research_panel_test.dart` | NEW | `9d6fb84af755a1420cabb9bbf56143c04960d6277855481151b690c79352ed4d` |
| `docs/horizon/evidence/h14-author.md` | NEW (this file) | — |

No existing file was modified. `git status --short` after the work shows the
same pre-existing dirty/untracked baseline plus only the four files above
(verified by reading status before and after; all other entries predate this run).

## 2. Actual commands and results on this host

Red/green TDD execution requires a Dart/Flutter SDK, which this host does not
have (AMENDMENT-2026-10-30 splits execution to the development PC):

```
$ which dart flutter
/usr/bin/bash: line 5: dart: command not found
$ dart --version
/usr/bin/bash: line 5: dart: command not found
```

(executed 2026-11-01 in `/home/ubuntu/apps/Horizon/frontend`; exit code 127 for
the dart invocation). Therefore:

- The test file was **authored first** as the executable specification
  (13 `testWidgets` cases across 6 groups), then the three widget files were
  implemented against it — red-first by construction, but the actual red/green
  run could not be performed here and is **DEFERRED_TO_DEV_PC, never claimed
  as PASS**.
- Static self-checks actually performed here (documented, not Dart-analysis
  equivalents):
  - Brace/paren/bracket balance of all four files via a Python tokenizer that
    understands Dart line/block comments and string literals: all four files
    BALANCED (an earlier naive line-regex check produced false imbalances;
    superseded by the tokenizer run).
  - Cross-check of every fixture string against the strict H11 model
    constructors (`ResearchAssessment.fromJson`, `ResearchRun.fromJson`,
    `EvidenceItem.fromJson`) invariants: outlook triple with contract
    month-end clamping targets (`2026-10-30` → `2026-11-30`/`2026-12-30`/
    `2027-01-30`), evaluation-session bounds, projection identity binding,
    state/action compatibility, position-context identity match, candidate
    no-economics rule, run lifecycle rules (queued/running/failed), evidence
    required fields.

## 3. Required development-PC execution (deferred, not passed)

```
cd frontend
dart run build_runner build --delete-conflicting-outputs   # mandatory first: H11 freezed models (research_models.freezed.dart, *.g.dart) do not exist on disk yet
flutter analyze
flutter test test/research_panel_test.dart
```

Note for the PC agent: `research_models.dart` and `research_repository.dart`
declare `part '…freezed.dart'` / `part '…g.dart'` parts that are not checked in;
generation is H11-owned and mandatory before any H14 widget code compiles.

## 4. Contract mappings (acceptance → implementation)

1. **"No vague placeholder replaces an evidence-backed recommendation;
   insufficient evidence remains a valid explicit conclusion."**
   - `recommendation.action` renders its contract label verbatim
     (`recommendationActionLabel`, CONTRACTS §5 enum); `insufficient_evidence`
     renders as the action itself plus the assessment's `missing_data` entries —
     an explicit conclusion, not a silent gap (tests: "insufficient evidence is
     an explicit valid conclusion", "limited status surfaces its banner").
   - Null assessment + live run renders only honest run state
     (status/stage/error code from the typed `ResearchRun`); nothing is
     fabricated (tests: "no assessment with a live run shows honest run status
     only", "failed run surfaces its error code").
   - Claim lists render `None recorded` when empty; empty-case silence is never
     substituted for missing support.

2. **"All displayed numbers resolve to validated metrics; date/currency/
   uncertainty labels readable and accessible."**
   - Every displayed value comes from the typed H11 models: `MoneyAmount`
     decimal-string cost, decimal quantity, `NumericProjection` finite bounds
     (`toStringAsFixed(2)` formatting only — no arithmetic performed in the
     renderer), fact values with unit/currency/basis.
   - Dates are rendered verbatim from contract fields with distinct labels:
     report generated/session as of; outlook target date vs evaluation session;
     evidence Published/Retrieved/Available/Reporting period as separate
     labeled rows (CONTRACTS §4 fields are never conflated).
   - `evidence_quality` and `predictive_uncertainty` render under their own
     labels.
   - Action badge, outlook direction and the horizon selector carry Semantics
     labels; state is never color-only.

3. **Package steps**
   - Candidate vs owned: state-driven economics section — candidate shows
     "No recorded purchase"; owned shows "Your recorded inputs (not advice)"
     with cost/quantity; legacy asks for classification. Tests cover both.
   - Decision-first panel: action/headline/rationale/countercase/invalidators +
     "What changed since the previous report" (changes_since_previous: prior
     session, missing report sessions, thesis component changes).
   - Business vs price distinction: three separate thesis sections — "Business
     assessment", "Price and technical assessment", "Valuation assessment" —
     each with its summary and claims.
   - Source/freshness/run status/snapshot links: `EvidenceSheet` renders source
     name + vetted URL (open delegated via `onOpenSource(Uri)`, no fetching in
     the widget), freshness rows, headline-only marking, facts;
     `ClaimList` renders claim type chips and evidence-ID chips delegated via
     `onOpenEvidence(String)`; the panel exposes the immutable evidence
     snapshot id via `onViewSnapshot(String)`; run status renders when a run is
     provided.
   - Independent 1/2/3-month tabs: `OutlookPanel` owns a local TabController,
     initial tab = recommendation horizon; switching tabs never mutates other
     tabs or any chart state. The selector is captioned "Research horizon
     selector — outlook targets below are independent of the chart history
     range controls" (tests assert both phrases).
   - Projections: null → the contract message "No quantified projection for
     this assessment" verbatim; present → kind framing ("Conditional scenario —
     not observed prices…", volatility reference, calibrated forecast), ordered
     bounds with currency, method/version, limitations. Core fixtures keep
     `numeric_projection: null` (H07A-held backend behavior); one test covers a
     bounded conditional scenario.
   - Standalone delivery: no shared detail screen, no global theme, no pubspec
     change; each widget file carries its own palette class defaulting to the
     app's Obsidian/gold values (same constants as H12/H13).

## 5. H09 review N1 constraint (controller addendum 2026-11-01) — honored

Backend `agent_runtime.js` `composePositionContext` derives
`position_context.economics_status` from hasCost&&hasQuantity only; the
authoritative comparable-P/L gate is the additive top-level `economics.status`
object, which the strict H11 model does not parse (unknown additive fields are
dropped). Renderer decision: **no comparable P/L is displayed at all**. Owned
positions show recorded cost/quantity labeled as user data plus the note that
comparable P/L requires matching currency and compatible price basis. The owned
fixture deliberately carries `economics_status: 'available'` and the tests
assert no "Profit / loss" or "P/L" presentation ever appears from it. Surfacing
the `economics` object in the typed model is H11-owner/H15B work;
`agent_runtime.js` was not touched (not in the write allowlist; held scoped
repair owns the naming-collision fix).

## 6. Wire-trace findings for downstream lanes (traced, not assumed)

Actual backend wire (`backend/src/features/research/research.routes.js`,
`research.service.js:803-835`) vs H11 repository assumptions (H11 review
A1/A2, preserved pending):

| Endpoint | Actual wire | H11 model expectation | Status |
|---|---|---|---|
| `GET /research/positions/:id/latest` | `{position_id, latest_assessment, run_state:{last_success:{run_id,status,assessment_id,evidence_snapshot_id,finished_at}, latest_attempt:{run_id,status,stage,started_at,finished_at,error_code,deadline_at}}}` | `ResearchLatest` parses `{assessment, run}` | **MISMATCH** — A1 confirmed wrong against the now-existing route. H14 widgets do not consume `ResearchLatest`; they take the typed `ResearchAssessment?` + full `ResearchRun?` directly. Reconciliation is H11-owner/H15B work. |
| `POST /research/positions/:id/runs` (202) | `{run, idempotent_replay}` | direct body object | **MISMATCH** — A2 unwrap needed. |
| `GET /research/runs/:runId` | `{run}` | direct body object | **MISMATCH** — same unwrap. |
| `GET /research/evidence/:evidenceId` | **no route exists in research.routes.js** (router exposes only latest/assessments/POST runs/GET run) | `getEvidence` expects `{evidence}` object | **MISSING ROUTE** — H14 `EvidenceSheet` is data-driven and unaffected, but the H11 repository method has no backend yet. |

Also traced: `toPublicAssessmentView` strips only `owner_id_internal`; the
additive `economics` object survives on the wire (schema passthrough), so the
typed-model extension path in §5 is viable for the owning lane.

## 7. Limitations

- No Flutter/Dart execution on this host: analyze/test/a11y/runtime are
  DEFERRED_TO_DEV_PC (§3). Source-only acceptance; not runtime approval.
- Fixture provenance: all fixture JSON is hand-built contract-shaped data
  (dates, plain-text claims, the observed-basis string); no invented prices,
  metrics, candles, source claims or verification output. The single projection
  fixture uses arbitrary bounded scenario numbers explicitly labeled a
  conditional scenario, mirroring the contract's own example semantics.
- TabBarView page lifecycle (lazy build) is relied on for "tab independence"
  assertions; if the PC run shows kept-alive pages, the assertion targets are
  per-tab `ValueKey('outlook-horizon-N')` scoped views — adjust finders, not
  widget behavior, only with reviewer agreement.
- `EvidenceSheet` renders a supplied `List<EvidenceItem>`; assembling it from
  the repository is H15B integration (and blocked on the missing evidence
  route above).
- The brace-balance tokenizer is a host-side static check, not a Dart parser;
  it cannot catch type errors, lint violations or behavioral failures.
