// H14 — widget tests for the direct recommendation and multi-horizon research
// panels (research_panel.dart, outlook_panel.dart, evidence_sheet.dart).
//
// Contract basis: docs/horizon/CONTRACTS.md §5–§7, the accepted H11 typed
// domain (frontend/lib/src/features/research/research_models.dart) and the
// canonical backend wire (backend/src/features/research/research.routes.js,
// agent_runtime.js). Fixtures are hand-built wire-shape JSON parsed through
// the strict H11 model constructors; nothing here invents prices, metrics or
// evidence. numeric_projection is null in every core fixture except the one
// projection test, mirroring the H07A-held backend behavior.
//
// H09 review N1 guard (controller addendum 2026-11-01): position_context
// economics_status is hasCost&&hasQuantity-derived and NOT authoritative for
// comparable P/L. The owned fixture deliberately carries
// economics_status='available' and these tests assert the renderer never
// presents a comparable profit/loss figure from it.
//
// EXECUTION STATUS: DEFERRED_TO_DEV_PC (no Dart/Flutter SDK on this host, per
// AMENDMENT-2026-10-30; `dart --version` → command not found). Authored here;
// must be run on the development PC after `dart run build_runner build
// --delete-conflicting-outputs` (mandatory for the H11 freezed models):
//   flutter test test/research_panel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horizon/src/features/research/research_models.dart';
import 'package:horizon/src/features/research/widgets/evidence_sheet.dart';
import 'package:horizon/src/features/research/widgets/outlook_panel.dart';
import 'package:horizon/src/features/research/widgets/research_panel.dart';

// ---------------------------------------------------------------------------
// Fixture helpers — backend wire shapes parsed through the strict H11 models.
// ---------------------------------------------------------------------------

const String _sessionAsOf = '2026-10-30';
// Contract month arithmetic with month-end clamping (CONTRACTS §5).
const String _target1 = '2026-11-30';
const String _target2 = '2026-12-30';
const String _target3 = '2027-01-30';
// Distinct evaluation-session dates per horizon (H14 review finding 2): real
// exchange-session weekdays, each >= _sessionAsOf and <= its calendar target,
// so the target-date line and the evaluation-session line render different
// strings and findsOneWidget assertions stay meaningful.
const String _eval1 = '2026-11-27'; // Friday before the 2026-11-30 target
const String _eval2 = '2026-12-29'; // Tuesday before the 2026-12-30 target
const String _eval3 = '2027-01-29'; // Friday before the 2027-01-30 target

Map<String, dynamic> _claim(String text,
        {String type = 'observed',
        List<String> evidenceIds = const ['ev-1'],
        List<String> metricIds = const []}) =>
    {
      'text': text,
      'evidence_ids': evidenceIds,
      'metric_ids': metricIds,
      'claim_type': type,
    };

List<Map<String, dynamic>> _outlooksJson({
  Map<int, Map<String, dynamic>> overrides = const {},
}) {
  const directions = {1: 'positive', 2: 'mixed', 3: 'insufficient_evidence'};
  const targets = {1: _target1, 2: _target2, 3: _target3};
  const evaluationSessions = {1: _eval1, 2: _eval2, 3: _eval3};
  return [1, 2, 3].map((horizon) {
    final base = {
      'horizon_months': horizon,
      'calendar_target_date': targets[horizon],
      'evaluation_session_date': evaluationSessions[horizon],
      'direction': directions[horizon],
      'base_case': [_claim('Base case for $horizon month horizon')],
      'upside_case': <Map<String, dynamic>>[],
      'downside_case': <Map<String, dynamic>>[],
      'catalysts': [_claim('Catalyst for $horizon month horizon')],
      'invalidators': [_claim('Invalidator for $horizon month horizon')],
      'numeric_projection': null,
      'data_limitations': horizon == 1
          ? ['Projection data limited to 90 days of observed bars.']
          : <String>[],
    };
    final override = overrides[horizon];
    return override == null ? base : {...base, ...override};
  }).toList();
}

Map<String, dynamic> _positionContextJson(String state) {
  final context = <String, dynamic>{
    'position_id': 'pos-1',
    'instrument_id': 'instr-1',
    'state': state,
    'revision': 7,
  };
  if (state == 'owned') {
    context['average_cost'] = {'amount': '152.25', 'currency': 'USD'};
    context['quantity'] = '10';
    context['opened_on'] = '2026-01-15';
    // Deliberately 'available': per H09 N1 this is hasCost&&hasQuantity
    // derived and must NOT drive comparable P/L presentation.
    context['economics_status'] = 'available';
  } else if (state == 'legacy_unclassified') {
    context['economics_status'] = 'unavailable';
  } else {
    context['economics_status'] = 'unavailable';
  }
  return context;
}

Map<String, dynamic> _assessmentJson({
  String state = 'candidate',
  String action = 'buy',
  String status = 'complete',
  List<Map<String, dynamic>>? outlooks,
  List<String> missingData = const [],
  Map<String, dynamic>? changesSincePrevious,
}) {
  final changes = changesSincePrevious ??
      (status == 'complete'
          ? <String, dynamic>{
              'previous_assessment_id': 'ass-0',
              'previous_session_as_of': '2026-10-29',
              'missing_report_sessions': <String>[],
              'thesis_changes': [
                {
                  'component': 'Cloud revenue growth thesis',
                  'status': 'strengthened',
                  'reason': 'New filing confirms guidance.',
                  'evidence_ids': ['ev-2'],
                },
              ],
              'checkpoint_change_ids': <String>[],
            }
          : null);
  return {
    'id': 'ass-1',
    'contract_version': 1,
    'position_id': 'pos-1',
    'position_revision': 7,
    'instrument_id': 'instr-1',
    'run_id': 'run-1',
    'evidence_snapshot_id': 'snap-1',
    'generated_at': '2026-10-30T21:00:00.000Z',
    'session_as_of': _sessionAsOf,
    'status': status,
    'market_thesis': {
      'business_assessment': {
        'summary': 'Subscription revenue is growing on sourced filings.',
        'claims': [
          _claim('Revenue grew 12% in the last reported quarter',
              type: 'observed'),
        ],
      },
      'price_technical_assessment': {
        'summary': 'Price trades above its observed 50-session average.',
        'claims': [
          _claim('Close is above the 50-session rolling average',
              type: 'observed'),
        ],
      },
      'valuation_assessment': {
        'summary': 'Valuation metrics are within the observed range.',
        'claims': [
          _claim('Valuation is broadly consistent with recent quarters',
              type: 'interpretation'),
        ],
      },
      'rationale': [_claim('Growth and price trend both merit attention')],
      'counterevidence': [_claim('Headline-only news cannot confirm demand')],
    },
    'recommendation': {
      'action': action,
      'horizon_months': 1,
      'headline': 'Evidence backs a considered entry, not urgency.',
      'rationale': [_claim('Sourced filings back the growth case')],
      'countercase': [_claim('Valuation leaves little margin for error')],
      'invalidation_conditions': [
        _claim('A downgrade below the sourced guidance range'),
      ],
      'evidence_quality':
          'Three primary filings and one market-data source cover the thesis.',
      'predictive_uncertainty':
          'Two of three horizons rely on interpretation, not observation.',
    },
    'position_context': _positionContextJson(state),
    'changes_since_previous': changes,
    'checkpoints': <Map<String, dynamic>>[],
    'outlooks': outlooks ?? _outlooksJson(),
    'missing_data': missingData,
    'next_review': null,
    'versions': {'pipeline': 'h09-core-1'},
  };
}

ResearchAssessment _assessment(
  Map<String, dynamic> json,
) =>
    ResearchAssessment.fromJson(json);

Map<String, dynamic> _runJson({
  String status = 'running',
  String? errorCode,
}) {
  final running = status == 'running';
  final failed = status == 'failed';
  final queued = status == 'queued';
  return {
    'id': 'run-2',
    'position_id': 'pos-1',
    'owner_id_internal': 'owner-1',
    'position_revision': 7,
    'run_kind': 'manual_refresh',
    'idempotency_key': 'manual-2026-10-30',
    'status': status,
    'stage': running ? 'synthesis' : 'queued',
    'created_at': '2026-10-30T20:00:00.000Z',
    'started_at': queued ? null : '2026-10-30T20:01:00.000Z',
    'heartbeat_at': running ? '2026-10-30T20:05:00.000Z' : null,
    'deadline_at': '2026-10-30T20:30:00.000Z',
    'finished_at': failed ? '2026-10-30T20:10:00.000Z' : null,
    'evidence_snapshot_id': null,
    'assessment_id': null,
    'error_code': errorCode,
    'retry_count': 0,
    'versions': {'pipeline': 'h09-core-1'},
  };
}

EvidenceItem _newsHeadlineEvidence() => EvidenceItem.fromJson({
      'id': 'ev-9',
      'instrument_id': 'instr-1',
      'kind': 'news',
      'title': 'Company announces quarterly results',
      'source_url': 'https://example.com/news/msft-q1',
      'source_name': 'Example Financial Wire',
      'published_at': null,
      'retrieved_at': '2026-10-30T20:00:00.000Z',
      'available_at': null,
      'reporting_period': null,
      'excerpt': null,
      'source_locator': null,
      'facts': <Map<String, dynamic>>[],
      'coverage_status': 'headline_only',
    });

EvidenceItem _filingEvidence() => EvidenceItem.fromJson({
      'id': 'ev-1',
      'instrument_id': 'instr-1',
      'kind': 'filing',
      'title': 'Annual report filing',
      'source_url': 'https://example.com/filings/msft-annual',
      'source_name': 'Securities regulator',
      'published_at': '2026-10-15T16:00:00.000Z',
      'retrieved_at': '2026-10-30T20:00:00.000Z',
      'available_at': '2026-10-15T16:05:00.000Z',
      'reporting_period': {
        'start': '2026-01-01',
        'end': '2026-03-31',
        'label': 'Q1 2026',
      },
      'excerpt': 'Subscription revenue increased in the reported period.',
      'source_locator': 'accession 0000-1234, page 14, section 2',
      'facts': [
        {
          'id': 'fact-1',
          'label': 'Revenue',
          'value': 61.9,
          'unit': 'billion',
          'currency': 'USD',
          'basis': 'GAAP',
          'reporting_period': {
            'start': '2026-01-01',
            'end': '2026-03-31',
            'label': 'Q1 2026',
          },
        },
      ],
      'coverage_status': 'available',
    });

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

// ---------------------------------------------------------------------------
// ResearchPanel — candidate versus owned actions, explicit insufficient
// evidence, limited results, business versus price distinction, N1 P/L guard.
// ---------------------------------------------------------------------------

void main() {
  group('ResearchPanel — candidate versus owned actions', () {
    testWidgets('candidate shows candidate action and no recorded economics',
        (tester) async {
      final assessment = _assessment(_assessmentJson(
        state: 'candidate',
        action: 'buy',
      ));
      await tester.pumpWidget(_host(ResearchPanel(assessment: assessment)));
      await tester.pump();

      expect(find.text('Buy'), findsOneWidget);
      // Business versus price distinction is explicit (CONTRACTS §5).
      expect(find.text('Business assessment'), findsOneWidget);
      expect(find.text('Price and technical assessment'), findsOneWidget);
      expect(find.text('Valuation assessment'), findsOneWidget);
      // Candidate records carry no executed economics; nothing fabricated.
      expect(find.textContaining('152.25'), findsNothing);
      expect(find.text('No recorded purchase'), findsOneWidget);
    });

    testWidgets('owned shows owned action and recorded inputs, never P/L',
        (tester) async {
      final assessment = _assessment(_assessmentJson(
        state: 'owned',
        action: 'hold_no_add',
      ));
      await tester.pumpWidget(_host(ResearchPanel(assessment: assessment)));
      await tester.pump();

      expect(find.text('Hold — do not add'), findsOneWidget);
      expect(find.textContaining('152.25'), findsOneWidget);
      expect(find.textContaining('USD'), findsWidgets);
      expect(find.textContaining('10'), findsWidgets);
      // H09 N1 guard: economics_status='available' must never render as
      // comparable P/L available.
      expect(find.textContaining('Profit / loss'), findsNothing);
      expect(find.textContaining('P/L'), findsNothing);
    });

    testWidgets('insufficient evidence is an explicit valid conclusion',
        (tester) async {
      final assessment = _assessment(_assessmentJson(
        state: 'candidate',
        action: 'insufficient_evidence',
        missingData: [
          'No sourced financial filings were available for this session.',
        ],
      ));
      await tester.pumpWidget(_host(ResearchPanel(assessment: assessment)));
      await tester.pump();

      expect(find.text('Insufficient evidence'), findsOneWidget);
      expect(
          find.text(
              'No sourced financial filings were available for this session.'),
          findsOneWidget);
      // No vague placeholder replaces an evidence-backed recommendation.
      expect(find.text('Buy'), findsNothing);
      expect(find.text('Wait'), findsNothing);
    });
  });

  group('ResearchPanel — status, run state and links', () {
    testWidgets('limited status surfaces its banner and missing data',
        (tester) async {
      final assessment = _assessment(_assessmentJson(
        status: 'limited',
        missingData: ['News coverage was headline-only for this session.'],
      ));
      await tester.pumpWidget(_host(ResearchPanel(assessment: assessment)));
      await tester.pump();

      expect(find.text('Limited report'), findsOneWidget);
      expect(find.text('News coverage was headline-only for this session.'),
          findsOneWidget);

      final complete = _assessment(_assessmentJson(status: 'complete'));
      await tester.pumpWidget(_host(ResearchPanel(assessment: complete)));
      await tester.pump();
      expect(find.text('Limited report'), findsNothing);
    });

    testWidgets('no assessment with a live run shows honest run status only',
        (tester) async {
      await tester.pumpWidget(_host(ResearchPanel(
        assessment: null,
        run: ResearchRun.fromJson(_runJson(status: 'running')),
      )));
      await tester.pump();

      expect(find.text('No research report yet'), findsOneWidget);
      expect(find.textContaining('Running'), findsOneWidget);
      expect(find.textContaining('synthesis'), findsOneWidget);
      // No invented assessment content.
      expect(find.text('Buy'), findsNothing);
    });

    testWidgets('failed run surfaces its error code, never a fake result',
        (tester) async {
      await tester.pumpWidget(_host(ResearchPanel(
        assessment: null,
        run: ResearchRun.fromJson(
            _runJson(status: 'failed', errorCode: 'MODEL_TIMEOUT')),
      )));
      await tester.pump();

      expect(find.text('No research report yet'), findsOneWidget);
      expect(find.textContaining('MODEL_TIMEOUT'), findsOneWidget);
    });

    testWidgets('snapshot link exposes the evidence snapshot id via callback',
        (tester) async {
      final assessment = _assessment(_assessmentJson());
      String? openedSnapshot;
      await tester.pumpWidget(_host(ResearchPanel(
        assessment: assessment,
        onViewSnapshot: (snapshotId) => openedSnapshot = snapshotId,
      )));
      await tester.pump();

      expect(find.textContaining('snap-1'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('snap-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('snap-1'));
      expect(openedSnapshot, 'snap-1');
    });
  });

  group('ResearchPanel — continuity and economics labels', () {
    testWidgets('what changed section shows prior session and thesis change',
        (tester) async {
      final assessment = _assessment(_assessmentJson());
      await tester.pumpWidget(_host(ResearchPanel(assessment: assessment)));
      await tester.pump();

      expect(find.text('What changed since the previous report'), findsOneWidget);
      expect(find.textContaining('2026-10-29'), findsOneWidget);
      expect(find.textContaining('Cloud revenue growth thesis'), findsOneWidget);
      expect(find.textContaining('strengthened'), findsOneWidget);
    });

    testWidgets('owned recorded inputs are labeled user data, not support',
        (tester) async {
      final assessment = _assessment(_assessmentJson(
        state: 'owned',
        action: 'hold_no_add',
      ));
      await tester.pumpWidget(_host(ResearchPanel(assessment: assessment)));
      await tester.pump();

      expect(find.textContaining('Your recorded'), findsOneWidget);
      // The cost basis must not be presented as market support or fair value.
      expect(find.textContaining('support'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // OutlookPanel — independent 1/2/3-month tabs, projections, limitations.
  // -------------------------------------------------------------------------

  group('OutlookPanel — independent horizons', () {
    testWidgets('three tabs exist and are independent', (tester) async {
      final assessment = _assessment(_assessmentJson());
      await tester.pumpWidget(_host(OutlookPanel(assessment: assessment)));
      await tester.pump();

      expect(find.text('1 month'), findsOneWidget);
      expect(find.text('2 months'), findsOneWidget);
      expect(find.text('3 months'), findsOneWidget);
      // The selector is labeled as a research horizon, never a chart range.
      expect(find.textContaining('Research horizon'), findsWidgets);
      expect(find.textContaining('chart history range'), findsOneWidget);

      // Default tab follows the recommendation horizon (1 month here). The
      // target-date and evaluation-session lines render distinct strings, so
      // each findsOneWidget below asserts exactly one widget.
      expect(find.textContaining(_target1), findsOneWidget);
      expect(find.textContaining(_eval1), findsOneWidget);
      expect(find.textContaining(_target3), findsNothing);

      await tester.tap(find.text('3 months'));
      await tester.pumpAndSettle();
      expect(find.textContaining(_target3), findsOneWidget);
      expect(find.textContaining(_eval3), findsOneWidget);
      expect(find.textContaining('Insufficient evidence'), findsWidgets);

      // Tab independence: returning to 1 month restores its own content.
      await tester.tap(find.text('1 month'));
      await tester.pumpAndSettle();
      expect(find.textContaining(_target1), findsOneWidget);
      expect(find.textContaining(_eval1), findsOneWidget);
      expect(find.textContaining(_target3), findsNothing);
    });

    testWidgets('missing quantified projection is explicit, never invented',
        (tester) async {
      final assessment = _assessment(_assessmentJson());
      await tester.pumpWidget(_host(OutlookPanel(assessment: assessment)));
      await tester.pump();

      expect(find.text('No quantified projection for this assessment'),
          findsOneWidget);
      expect(find.textContaining('Conditional scenario'), findsNothing);
      expect(find.textContaining('Volatility reference'), findsNothing);
    });

    testWidgets('conditional scenario projection is labeled and bounded',
        (tester) async {
      final outlooks = _outlooksJson(overrides: {
        1: {
          'numeric_projection': {
            'id': 'proj-1',
            'assessment_id': 'ass-1',
            'instrument_id': 'instr-1',
            'evidence_snapshot_id': 'snap-1',
            'anchor_time': '2026-10-30T21:00:00.000Z',
            'anchor_price_metric_id': 'metric-1',
            // Must equal the horizon-1 evaluation_session_date: the H11 model
            // rejects a projection whose target session differs from its
            // outlook's evaluation session (research_models.dart).
            'target_session_date': _eval1,
            'kind': 'conditional_scenario',
            'method': 'analyst scenario arithmetic',
            'method_version': '1',
            'input_metric_ids': ['metric-1'],
            'assumption_ids': ['assumption-1'],
            'lower': 95.0,
            'central': 105.0,
            'upper': 115.0,
            'currency': 'USD',
            'adjustment_basis': 'raw provider OHLCV',
            'calibration': null,
            'valid_until': null,
            'limitations': ['Conditional scenario, not a probability interval.'],
          },
        },
      });
      final assessment = _assessment(_assessmentJson(outlooks: outlooks));
      await tester.pumpWidget(_host(OutlookPanel(assessment: assessment)));
      await tester.pump();

      // Scenario framing and the not-observed-prices boundary are visible.
      expect(find.textContaining('Conditional scenario'), findsWidgets);
      expect(find.textContaining('not observed prices'), findsWidgets);
      expect(find.textContaining('95.00'), findsOneWidget);
      expect(find.textContaining('105.00'), findsOneWidget);
      expect(find.textContaining('115.00'), findsOneWidget);
      expect(find.textContaining('USD'), findsWidgets);
      expect(
          find.textContaining('not a probability interval'), findsWidgets);
    });

    testWidgets('data limitations render on their horizon', (tester) async {
      final assessment = _assessment(_assessmentJson());
      await tester.pumpWidget(_host(OutlookPanel(assessment: assessment)));
      await tester.pump();

      expect(
          find.textContaining('90 days of observed bars'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // EvidenceSheet — source links, freshness labels, headline-only honesty.
  // -------------------------------------------------------------------------

  group('EvidenceSheet', () {
    testWidgets('source link, freshness labels and headline-only marking',
        (tester) async {
      Uri? opened;
      await tester.pumpWidget(_host(EvidenceSheet(
        items: [_newsHeadlineEvidence(), _filingEvidence()],
        onOpenSource: (url) => opened = url,
      )));
      await tester.pump();

      // Source identity and vetted URL are visible and tappable.
      expect(find.textContaining('Example Financial Wire'), findsOneWidget);
      expect(find.textContaining('Securities regulator'), findsOneWidget);
      expect(find.text('https://example.com/news/msft-q1'), findsOneWidget);
      await tester.tap(find.text('https://example.com/news/msft-q1'));
      expect(opened, Uri.parse('https://example.com/news/msft-q1'));

      // Headline-only news is explicitly not a verified article.
      expect(find.textContaining('Headline only'), findsOneWidget);

      // Freshness labels distinguish publication, retrieval and
      // availability (CONTRACTS §4).
      expect(find.textContaining('Published'), findsWidgets);
      expect(find.textContaining('Retrieved'), findsWidgets);
      expect(find.textContaining('Available'), findsWidgets);
      // Reporting period is its own concept, not publication time.
      expect(find.textContaining('Q1 2026'), findsWidgets);
      // Filing fact carries unit, currency and basis.
      expect(find.textContaining('Revenue'), findsOneWidget);
      expect(find.textContaining('61.9'), findsOneWidget);
      expect(find.textContaining('GAAP'), findsOneWidget);
      expect(find.textContaining('accession 0000-1234'), findsOneWidget);
    });

    testWidgets('claim list exposes its evidence references via callback',
        (tester) async {
      final assessment = _assessment(_assessmentJson());
      String? openedEvidence;
      await tester.pumpWidget(_host(ResearchPanel(
        assessment: assessment,
        onOpenEvidence: (evidenceId) => openedEvidence = evidenceId,
      )));
      await tester.pump();

      // Rationale claims render with their evidence references.
      final chip = find.textContaining('ev-1');
      expect(chip, findsWidgets);
      await tester.tap(chip.first);
      expect(openedEvidence, 'ev-1');
    });
  });
}
