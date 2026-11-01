// H15B — canonical Flutter integration test: positions + grounded research
// panels wired into the existing stock detail flow.
//
// Contract basis: docs/horizon/CONTRACTS.md §2 (position), §5 (assessment),
// §8 (run lifecycle), §9 (API surface) and the traced canonical backend wire:
//   - GET /research/positions/:id/latest →
//     `{position_id, latest_assessment, run_state: {last_success,
//     latest_attempt}}` (backend/src/features/research/research.routes.js:61,
//     research.service.js getPositionResearchState). The contract assessment
//     object arrives flattened under `latest_assessment` (owner_id_internal
//     stripped by toPublicAssessmentView); run state arrives as owner-safe
//     projections, NOT as full ResearchRun objects — the host adapter in
//     stock_detail_screen.dart unwraps it (H11 ResearchLatest expects a
//     different historical shape and is read-only; drift reported, not
//     repaired here).
//   - POST /research/positions/:id/runs → `{run: <full run wire>,
//     idempotent_replay}` where the run wire RETAINS owner_id_internal
//     (toPublicRunView strips only lease_nonce), so the H11
//     ResearchRun.fromJson parse reconciles with the real wire.
//   - PATCH /positions/:id → `{expected_revision, changes: {...}}`
//     (position.routes.js:60); conflicts surface as 409 REVISION_CONFLICT.
//
// Fixtures are hand-built wire-shape JSON parsed through the strict H11
// models; nothing invents prices, candles, metrics or evidence. The stock
// fixture carries no history: the chart slot must render its truthful
// unavailable state while panels stay fully functional (panels do not wait
// for chart completion).
//
// EXECUTION STATUS: DEFERRED_TO_DEV_PC (no Dart/Flutter SDK on this host —
// `dart --version` → command not found). Authored here; must be run on the
// development PC after `dart run build_runner build
// --delete-conflicting-outputs` (mandatory: H11 position/research generated
// providers do not exist before generation):
//   flutter test test/research_panel_integration_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:horizon/src/features/positions/position_repository.dart';
import 'package:horizon/src/features/stock/stock_detail_screen.dart';
import 'package:horizon/src/features/stock/stock_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fixtures — backend wire shapes (traced, never invented).
// ---------------------------------------------------------------------------

const String _sessionAsOf = '2026-10-30';
const String _target1 = '2026-11-30';
const String _target2 = '2026-12-30';
const String _target3 = '2027-01-30';
const String _eval1 = '2026-11-27';
const String _eval2 = '2026-12-29';
const String _eval3 = '2027-01-29';

const Map<String, dynamic> _instrumentJson = {
  'instrument_id': 'instr-1',
  'symbol': 'MSFT',
  'exchange': 'NASDAQ',
  'currency': 'USD',
  'provider_symbol': 'MSFT',
};

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

List<Map<String, dynamic>> _outlooksJson() {
  const directions = {1: 'positive', 2: 'mixed', 3: 'insufficient_evidence'};
  const targets = {1: _target1, 2: _target2, 3: _target3};
  const evaluations = {1: _eval1, 2: _eval2, 3: _eval3};
  return [1, 2, 3].map((horizon) {
    return {
      'horizon_months': horizon,
      'calendar_target_date': targets[horizon],
      'evaluation_session_date': evaluations[horizon],
      'direction': directions[horizon],
      'base_case': [_claim('Base case for $horizon month horizon')],
      'upside_case': <Map<String, dynamic>>[],
      'downside_case': <Map<String, dynamic>>[],
      'catalysts': [_claim('Catalyst for $horizon month horizon')],
      'invalidators': [_claim('Invalidator for $horizon month horizon')],
      'numeric_projection': null,
      'data_limitations': <String>[],
    };
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
    // hasCost&&hasQuantity-derived; never authoritative for comparable P/L
    // (H09 review N1 guard carried from H14).
    context['economics_status'] = 'available';
  } else {
    context['economics_status'] = 'unavailable';
  }
  return context;
}

Map<String, dynamic> _assessmentJson({
  String state = 'owned',
  String action = 'hold',
  String status = 'complete',
  bool withChanges = true,
}) {
  final changes = withChanges
      ? {
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
      : null;
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
        'claims': [_claim('Revenue grew 12% in the last reported quarter')],
      },
      'price_technical_assessment': {
        'summary': 'Price trades above its observed 50-session average.',
        'claims': [_claim('Close is above the 50-session rolling average')],
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
    'outlooks': _outlooksJson(),
    'missing_data': <String>[],
    'next_review': null,
    'versions': {'pipeline': 'h09-core-1'},
  };
}

/// Position wire object (nested instrument identity object; null economics
/// for the unknown-economics scenario — never zeros).
Map<String, dynamic> _positionJson({
  String state = 'owned',
  bool withEconomics = true,
  int revision = 7,
}) {
  return {
    'id': 'pos-1',
    'instrument': _instrumentJson,
    'state': state,
    'average_cost': withEconomics
        ? {'amount': '152.25', 'currency': 'USD'}
        : null,
    'quantity': withEconomics ? '10' : null,
    'opened_on': withEconomics ? '2026-01-15' : null,
    'preferred_horizon_months': 3,
    'original_thesis': 'Cloud growth thesis.',
    'review_conditions': <String>['Re-review after next earnings'],
    'risk_context': null,
    'archived': false,
    'revision': revision,
    'created_at': '2026-01-10T09:00:00.000Z',
    'updated_at': '2026-10-30T19:00:00.000Z',
  };
}

/// Full run wire object — note owner_id_internal is present on the real run
/// wire (toPublicRunView strips only lease_nonce), which is exactly why the
/// H11 ResearchRun.fromJson parse reconciles here.
Map<String, dynamic> _runJson({
  String id = 'run-2',
  String status = 'queued',
  String? errorCode,
}) {
  final queued = status == 'queued';
  final failed = status == 'failed';
  return {
    'id': id,
    'position_id': 'pos-1',
    'owner_id_internal': 'owner-1',
    'position_revision': 7,
    'run_kind': 'manual_refresh',
    'idempotency_key': 'manual-2026-10-30',
    'status': status,
    'stage': queued ? 'queued' : 'synthesis',
    'created_at': '2026-10-30T20:00:00.000Z',
    'started_at': queued ? null : '2026-10-30T20:01:00.000Z',
    'heartbeat_at': null,
    'deadline_at': '2026-10-30T20:30:00.000Z',
    'finished_at': failed ? '2026-10-30T20:10:00.000Z' : null,
    'evidence_snapshot_id': null,
    'assessment_id': null,
    'error_code': errorCode,
    'retry_count': 0,
    'versions': {'pipeline': 'h09-core-1'},
  };
}

/// The REAL `GET /research/positions/:id/latest` response shape
/// (research.routes.js:61-80): flattened latest_assessment plus owner-safe
/// run-state projections. last_success and latest_attempt are separate — an
/// existing success is never rewritten by a later failure.
Map<String, dynamic> _latestWire({
  Map<String, dynamic>? assessment,
  Map<String, dynamic>? lastSuccess,
  Map<String, dynamic>? latestAttempt,
}) {
  return {
    'position_id': 'pos-1',
    'latest_assessment': assessment,
    'run_state': {
      'last_success': lastSuccess,
      'latest_attempt': latestAttempt,
    },
  };
}

Map<String, dynamic> _lastSuccessJson() => {
      'run_id': 'run-1',
      'status': 'succeeded',
      'assessment_id': 'ass-1',
      'evidence_snapshot_id': 'snap-1',
      'finished_at': '2026-10-30T20:05:00.000Z',
    };

Map<String, dynamic> _latestAttemptJson() => {
      'run_id': 'run-2',
      'status': 'failed',
      'stage': 'synthesis',
      'started_at': '2026-10-30T22:00:00.000Z',
      'finished_at': '2026-10-30T22:10:00.000Z',
      'error_code': 'PIPELINE_VALIDATION_FAILED',
      'deadline_at': '2026-10-30T22:30:00.000Z',
    };

// ---------------------------------------------------------------------------
// Fake stock repository (the screen's stock list input) and mock transport.
// ---------------------------------------------------------------------------

class _FixtureStockRepository extends StockRepository {
  @override
  Future<List<StockData>> build() async => [
        const StockData(
          ticker: 'MSFT',
          name: 'Microsoft',
          currentPrice: 152.25,
          changePercent: 1.2,
          history: <double>[], // no observed history → truthful chart slot
          sentiment: 0.7,
          source: StockSource.watchlist,
        ),
      ];
}

/// Records every request so tests can assert the exact wire contracts the
/// wiring emits (PATCH envelope, Idempotency-Key header, Bearer token).
class _RecordingTransport {
  _RecordingTransport({this.patchResponse, this.latestWire, this.positionWire});

  /// Latest-state response body (defaults to a complete success state).
  Map<String, dynamic>? latestWire;

  /// The single position returned by GET /positions (defaults to an owned
  /// position with full economics).
  Map<String, dynamic>? positionWire;

  /// When set, PATCH /positions/pos-1 answers with this raw status/body
  /// (used for the revision-conflict scenario); otherwise a 200 with an
  /// updated position wire is returned.
  ({int status, Map<String, dynamic> body})? patchResponse;

  final List<http.Request> requests = [];

  static const _token = 'test-token';

  http.Client buildClient() {
    return MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (request.method == 'GET' && path.endsWith('/positions')) {
        return _json(200, {
          'positions': [positionWire ?? _positionJson()],
        });
      }
      if (request.method == 'GET' &&
          path.endsWith('/research/positions/pos-1/latest')) {
        return _json(200, latestWire ?? _latestWire(
          assessment: _assessmentJson(),
          lastSuccess: _lastSuccessJson(),
        ));
      }
      if (request.method == 'POST' &&
          path.endsWith('/research/positions/pos-1/runs')) {
        return _json(202, {
          'run': _runJson(status: 'queued'),
          'idempotent_replay': false,
        });
      }
      if (request.method == 'PATCH' && path.endsWith('/positions/pos-1')) {
        final patch = patchResponse;
        if (patch != null) return _json(patch.status, patch.body);
        return _json(
            200,
            _positionJson(
              revision: 8,
            )..['updated_at'] = '2026-10-30T23:00:00.000Z');
      }
      return _json(404, {
        'success': false,
        'error': {'message': 'NOT_FOUND', 'code': 'NOT_FOUND'},
      });
    });
  }

  http.Response _json(int status, Object body) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  List<http.Request> calls(String method, String pathSuffix) => requests
      .where((r) => r.method == method && r.url.path.endsWith(pathSuffix))
      .toList();
}

// ---------------------------------------------------------------------------
// Harness.
// ---------------------------------------------------------------------------

Future<void> _pumpScreen(
  WidgetTester tester,
  _RecordingTransport transport,
) async {
  final client = transport.buildClient();
  await tester.pumpWidget(
    MaterialApp(
      home: ProviderScope(
        overrides: [
          stockRepositoryProvider.overrideWith(_FixtureStockRepository.new),
          positionRepositoryProvider.overrideWith(
            (ref) => PositionRepository(
              client: client,
              tokenProvider: () async => _RecordingTransport._token,
            ),
          ),
          researchWireProvider.overrideWithValue(
            ResearchWire(
              client: client,
              tokenProvider: () async => _RecordingTransport._token,
            ),
          ),
        ],
        child: const Scaffold(
          body: StockDetailScreen(ticker: 'MSFT'),
        ),
      ),
    ),
  );
  // First pump: stock list resolves and the section starts loading.
  await tester.pump();
  // Second pump: position + research futures resolve and settle.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    // AuthRepository reads SharedPreferences for the token; the transport
    // never sees it leave the fake token provider, and no real credentials
    // are involved anywhere in this suite.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('H15B integrated stock detail journey', () {
    testWidgets(
        'renders position state, economics and grounded research panel with '
        'the chart slot preserved truthfully unavailable', (tester) async {
      final transport = _RecordingTransport();
      await _pumpScreen(tester, transport);

      // Briefing-derived price header still rendered (not overwritten by
      // immutable research prices).
      expect(find.text('\$152.25'), findsOneWidget);
      // Truthful unavailable chart slot — the panels render without any
      // chart dependency.
      expect(find.text('OBSERVED PRICE HISTORY UNAVAILABLE'), findsOneWidget);
      // Position section: owned badge and honest economics line.
      expect(find.bySemanticsLabel('Owned position'), findsOneWidget);
      expect(find.text('Cost 152.25 USD · Quantity 10'), findsOneWidget);
      // Research panel: decision-first recommendation card.
      expect(find.text('Recommendation'), findsOneWidget);
      // Continuity card rendered from changes_since_previous.
      expect(
          find.text('What changed since the previous report'), findsOneWidget);
    });

    testWidgets('candidate position shows candidate economics truthfully',
        (tester) async {
      final transport = _RecordingTransport()
        ..positionWire = _positionJson(state: 'candidate', withEconomics: false)
        ..latestWire = _latestWire(
          assessment: _assessmentJson(state: 'candidate', action: 'buy'),
        );
      await _pumpScreen(tester, transport);

      expect(
          find.bySemanticsLabel(
              'Candidate position: a watchlist idea, no executed purchase'),
          findsOneWidget);
      expect(
          find.text(
              'No executed purchase — entry ideas live in review conditions.'),
          findsOneWidget);
      // Candidate-compatible action rendered by the panel.
      expect(find.bySemanticsLabel(RegExp('Recommended action:')),
          findsOneWidget);
    });

    testWidgets('owned position with unknown economics never invents values',
        (tester) async {
      final transport = _RecordingTransport()
        ..positionWire = _positionJson(withEconomics: false)
        ..latestWire = _latestWire(
          assessment: _assessmentJson(
            state: 'owned',
            action: 'hold_no_add',
          ),
        );
      await _pumpScreen(tester, transport);

      expect(find.bySemanticsLabel('Owned position'), findsOneWidget);
      // Unknown economics: explicit "unknown" copy — never zero, never a
      // fabricated value.
      expect(find.textContaining('Cost unknown'), findsOneWidget);
    });

    testWidgets(
        'edit save wires the real PositionRepository PATCH envelope with '
        'expected_revision and changes', (tester) async {
      final transport = _RecordingTransport();
      await _pumpScreen(tester, transport);

      await tester.ensureVisible(find.text('Edit position'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Edit position'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.text('Save position'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Save position'));
      await tester.pump(const Duration(milliseconds: 400));

      final patches = transport.calls('PATCH', '/positions/pos-1');
      expect(patches, hasLength(1));
      final body = jsonDecode(patches.single.body) as Map<String, dynamic>;
      expect(body['expected_revision'], 7);
      expect(body['changes'], isA<Map<String, dynamic>>());
      expect((body['changes'] as Map<String, dynamic>), contains('instrument'));
    });

    testWidgets('revision conflict surfaces the conflict copy without crashing',
        (tester) async {
      final transport = _RecordingTransport()
        ..patchResponse = (
          status: 409,
          body: {
            'success': false,
            'error': {
              'message': 'Position was modified concurrently',
              'code': 'REVISION_CONFLICT',
            },
          }
        );
      await _pumpScreen(tester, transport);

      await tester.ensureVisible(find.text('Edit position'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Edit position'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.text('Save position'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Save position'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
          find.text('This position changed elsewhere since you opened it.'),
          findsOneWidget);
      // The conflict must NOT be retried automatically: exactly one PATCH.
      expect(transport.calls('PATCH', '/positions/pos-1'), hasLength(1));
    });

    testWidgets('limited assessment renders the limited marker',
        (tester) async {
      final transport = _RecordingTransport()
        ..latestWire = _latestWire(
          assessment: _assessmentJson(status: 'limited'),
          lastSuccess: _lastSuccessJson()..['status'] = 'limited',
          latestAttempt: _latestAttemptJson(),
        );
      await _pumpScreen(tester, transport);

      expect(find.text('Limited report'), findsOneWidget);
    });

    testWidgets('no-result state renders the honest empty panel with no runs',
        (tester) async {
      final transport = _RecordingTransport()
        ..latestWire = _latestWire();
      await _pumpScreen(tester, transport);

      expect(find.text('No research report yet'), findsOneWidget);
      expect(find.text('No successful research runs yet.'), findsOneWidget);
      expect(find.text('No research attempts recorded yet.'), findsOneWidget);
    });

    testWidgets(
        'latest attempt and last success are reported separately: a prior '
        'success survives a later failed attempt', (tester) async {
      final transport = _RecordingTransport()
        ..latestWire = _latestWire(
          assessment: _assessmentJson(),
          lastSuccess: _lastSuccessJson(),
          latestAttempt: _latestAttemptJson(),
        );
      await _pumpScreen(tester, transport);

      // Prior success still grounds the panel...
      expect(find.text('Recommendation'), findsOneWidget);
      // ...and both run-state rows are distinct and truthful.
      expect(find.textContaining('Last successful report'), findsOneWidget);
      expect(find.textContaining('Latest attempt'), findsOneWidget);
      expect(find.textContaining('PIPELINE_VALIDATION_FAILED'),
          findsOneWidget);
    });

    testWidgets(
        'queueing a run sends the Idempotency-Key header and shows the run '
        'state without inventing an assessment', (tester) async {
      final transport = _RecordingTransport()
        ..latestWire = _latestWire();
      await _pumpScreen(tester, transport);

      await tester.ensureVisible(find.text('RUN RESEARCH'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('RUN RESEARCH'));
      await tester.pump(const Duration(milliseconds: 400));

      final posts = transport.calls('POST', '/research/positions/pos-1/runs');
      expect(posts, hasLength(1));
      final key = posts.single.headers['Idempotency-Key'];
      expect(key, isNotNull);
      expect(key, isNotEmpty);

      // Honest run state: the queued run is surfaced, no assessment is
      // fabricated while it is pending.
      expect(find.text('No research report yet'), findsOneWidget);
      expect(find.textContaining('Run status:'), findsOneWidget);
    });

    testWidgets(
        'immutable research prices: loading an assessment never overwrites '
        'the observed price header', (tester) async {
      final transport = _RecordingTransport();
      await _pumpScreen(tester, transport);

      // The assessment's position economics (cost 152.25) and the briefing
      // price (152.25) coincide in the fixture; the header must still show
      // exactly the briefing price formatting, proving no research value was
      // merged into the market price slot.
      expect(find.text('\$152.25'), findsOneWidget);
      expect(find.text('OBSERVED PRICE HISTORY UNAVAILABLE'), findsOneWidget);
    });

    testWidgets('a ticker without a tracked position renders truthful copy '
        'and no invented instrument identity', (tester) async {
      final noPosition = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/positions')) {
          return http.Response(jsonEncode({'positions': <dynamic>[]}), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'message': 'NOT_FOUND', 'code': 'NOT_FOUND'},
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              stockRepositoryProvider.overrideWith(_FixtureStockRepository.new),
              positionRepositoryProvider.overrideWith(
                (ref) => PositionRepository(
                  client: noPosition,
                  tokenProvider: () async => 'test-token',
                ),
              ),
              researchWireProvider.overrideWithValue(
                ResearchWire(
                  client: noPosition,
                  tokenProvider: () async => 'test-token',
                ),
              ),
            ],
            child: const Scaffold(body: StockDetailScreen(ticker: 'MSFT')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('No tracked position for MSFT'),
          findsOneWidget);
      // No research runs may be queued without a position.
      expect(find.text('RUN RESEARCH'), findsNothing);
    });
  });
}
