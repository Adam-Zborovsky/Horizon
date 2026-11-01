// H17 — device-level research journey integration test (SOURCE ONLY).
//
// Exercises the FULL user journey through the real widget tree, driving the
// accepted H15B stock detail flow (StockDetailScreen + _PositionResearchSection
// + H14 ResearchPanel + H12 PositionEditor) against a hermetic scripted
// backend transport. Mirrors the backend e2e suite
// (backend/test/research-end-to-end.test.cjs) stage-for-stage at the UI layer:
//
//   candidate -> queue research run -> owned transition -> cost edit ->
//   limited assessment (visible gaps) -> failed/stalled run honesty +
//   prior-success vs latest-attempt separation -> no-tracked-position truth.
//
// Contract basis: docs/horizon/CONTRACTS.md §1-§2 (position identity +
// economics), §5 (assessment/recommendation), §8 (run lifecycle), §9 (API
// surface). Wire shapes are hand-built from the traced canonical backend wire
// (research.routes.js latest/run envelopes, position.routes.js PATCH envelope)
// and parsed through the strict H11 models — nothing invents prices, candles,
// metrics or evidence. The stock fixture carries no observed history so the
// chart slot renders its truthful unavailable state while panels stay fully
// functional (panels never wait for chart completion).
//
// EXECUTION STATUS: DEFERRED_TO_DEV_PC. There is no Dart/Flutter SDK on the
// authoring host (`dart --version` / `flutter --version` -> command not
// found), so this file is AUTHORED, never executed, and no runtime PASS is
// claimed from source inspection. It must be run on the development PC after
// the mandatory generator pass (`dart run build_runner build
// --delete-conflicting-outputs` — the H11 position/research .freezed.dart /
// .g.dart parts do not exist before generation) AND after adding the
// `integration_test` SDK package to dev_dependencies (it is not yet listed in
// pubspec.yaml; see docs/horizon/DEV_PC_HANDOFF.md):
//
//   flutter test integration_test/research_journey_test.dart
//
// On-device equivalents: `flutter drive --driver=test_driver/integration_test.dart
// --target=integration_test/research_journey_test.dart -d <device>`.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

import 'package:horizon/src/features/positions/position_repository.dart';
import 'package:horizon/src/features/stock/stock_detail_screen.dart';
import 'package:horizon/src/features/stock/stock_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fixtures — backend wire shapes (traced, never invented). The wire objects
// mirror the accepted H15B integration test (frontend/test/
// research_panel_integration_test.dart, controller-verified) and the backend
// e2e suite; the journey adds the candidate/limited/failed stages the device
// flow must render truthfully.
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

Map<String, dynamic> _claim(
  String text, {
  String type = 'observed',
  List<String> evidenceIds = const ['ev-1'],
  List<String> metricIds = const [],
}) =>
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

Map<String, dynamic> _positionContextJson(
  String state, {
  String? averageCost = '152.25',
  String? quantity = '10',
}) {
  final context = <String, dynamic>{
    'position_id': 'pos-1',
    'instrument_id': 'instr-1',
    'state': state,
    'revision': 7,
  };
  if (state == 'owned') {
    if (averageCost != null) {
      context['average_cost'] = {'amount': averageCost, 'currency': 'USD'};
    }
    if (quantity != null) context['quantity'] = quantity;
    context['opened_on'] = '2026-01-15';
    // hasCost && hasQuantity-derived; never authoritative for comparable P/L
    // (H09 review N1 guard carried from H14).
    context['economics_status'] =
        (averageCost != null && quantity != null) ? 'available' : 'partial';
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
  List<String> missingData = const <String>[],
}) {
  final changes = withChanges
      ? {
          'previous_assessment_id': 'ass-0',
          'previous_session_as_of': '2026-10-29',
          'missing_report_sessions': <String>[],
          'thesis_changes': [
            {
              'component': 'Cloud revenue growth thesis',
              'status': 'unchanged',
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
    'missing_data': missingData,
    'next_review': null,
    'versions': {'pipeline': 'h09-core-1'},
  };
}

/// Position wire object (nested instrument identity object; null economics for
/// the unknown-economics scenario — never zeros).
Map<String, dynamic> _positionJson({
  String state = 'owned',
  bool withEconomics = true,
  int revision = 7,
  String? averageCost = '152.25',
}) {
  return {
    'id': 'pos-1',
    'instrument': _instrumentJson,
    'state': state,
    'average_cost':
        (withEconomics && averageCost != null)
            ? {'amount': averageCost, 'currency': 'USD'}
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

/// Full run wire object — owner_id_internal is present on the real run wire
/// (toPublicRunView strips only lease_nonce), which is exactly why the H11
/// ResearchRun.fromJson parse reconciles here.
Map<String, dynamic> _runJson({
  String id = 'run-2',
  String status = 'queued',
  String? errorCode,
}) {
  final queued = status == 'queued';
  final failed = status == 'failed';
  final stalled = status == 'stalled';
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
    'finished_at': (failed || stalled) ? '2026-10-30T20:10:00.000Z' : null,
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

Map<String, dynamic> _latestAttemptJson({
  String status = 'failed',
  String? errorCode = 'PIPELINE_VALIDATION_FAILED',
}) =>
    {
      'run_id': 'run-2',
      'status': status,
      'stage': 'synthesis',
      'started_at': '2026-10-30T22:00:00.000Z',
      'finished_at': '2026-10-30T22:10:00.000Z',
      'error_code': errorCode,
      'deadline_at': '2026-10-30T22:30:00.000Z',
    };

// ---------------------------------------------------------------------------
// Fake stock repository (the screen's stock list input) and scripted transport.
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

/// Records every request so tests assert the exact wire contracts the wiring
/// emits (PATCH envelope, Idempotency-Key header, Bearer token). Mutable
/// fields let a single test script a multi-stage journey across successive
/// loads.
class _JourneyTransport {
  /// The single position returned by GET /positions.
  Map<String, dynamic>? positionWire;

  /// Latest-state response body for GET /research/positions/pos-1/latest.
  Map<String, dynamic>? latestWire;

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
  _JourneyTransport transport,
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
              tokenProvider: () async => _JourneyTransport._token,
            ),
          ),
          researchWireProvider.overrideWithValue(
            ResearchWire(
              client: client,
              tokenProvider: () async => _JourneyTransport._token,
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // AuthRepository reads SharedPreferences for the token; the transport
    // never sees it leave the fake token provider, and no real credentials
    // are involved anywhere in this suite.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('journey: candidate -> queue run -> owned -> cost edit renders '
      'each stage honestly without inventing economics or P/L',
      (tester) async {
    final transport = _JourneyTransport();
    // Stage 1 — candidate (backend A3): no executed economics, candidate
    // recommendation only.
    transport.positionWire = _positionJson(state: 'candidate', withEconomics: false);
    transport.latestWire = _latestWire(
      assessment: _assessmentJson(state: 'candidate', action: 'buy'),
    );
    await _pumpScreen(tester, transport);

    expect(find.bySemanticsLabel(RegExp('^Candidate position:')), findsOneWidget);
    // The panel's own economics card reports no purchase, never zeros.
    expect(find.textContaining('No recorded purchase'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Recommended action:')), findsOneWidget);

    // Stage 2 — queue a research run (backend A2/A3): Idempotency-Key header
    // sent, queued run surfaced, no assessment fabricated while pending.
    await tester.ensureVisible(find.text('RUN RESEARCH'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('RUN RESEARCH'));
    await tester.pump(const Duration(milliseconds: 400));

    final posts = transport.calls('POST', '/research/positions/pos-1/runs');
    expect(posts, hasLength(1));
    final key = posts.single.headers['Idempotency-Key'];
    expect(key, isNotNull);
    expect(key, isNotEmpty);

    // Stage 3 — owned transition + cost edit (backend A4): switch the backend
    // to an owned position with economics; thesis/recommendation unchanged,
    // comparable P/L explicitly NOT derived.
    transport.positionWire = _positionJson(state: 'owned');
    transport.latestWire = _latestWire(
      assessment: _assessmentJson(state: 'owned', action: 'hold'),
      lastSuccess: _lastSuccessJson(),
    );
    // Re-trigger a load by editing (the section reloads after a save).
    await tester.ensureVisible(find.text('Edit position'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Edit position'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Save position'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Save position'));
    await tester.pump(const Duration(milliseconds: 400));

    // The PATCH envelope matches the accepted position.routes.js contract.
    final patches = transport.calls('PATCH', '/positions/pos-1');
    expect(patches, hasLength(1));
    final body = jsonDecode(patches.single.body) as Map<String, dynamic>;
    expect(body['expected_revision'], 7);
    expect(body['changes'], isA<Map<String, dynamic>>());
    expect((body['changes'] as Map<String, dynamic>), contains('instrument'));

    // Owned economics rendered, comparable P/L never fabricated (H09 N1).
    expect(find.bySemanticsLabel('Owned position'), findsOneWidget);
    expect(find.textContaining('Comparable profit and loss is not shown'),
        findsOneWidget);
  });

  testWidgets('limited assessment renders the explicit limited marker with '
      'visible gaps (backend C4)', (tester) async {
    final transport = _JourneyTransport()
      ..positionWire = _positionJson(state: 'owned')
      ..latestWire = _latestWire(
        assessment: _assessmentJson(
          state: 'owned',
          action: 'hold',
          status: 'limited',
          missingData: const <String>[
            'Earnings transcript unavailable for this session',
          ],
        ),
        lastSuccess: _lastSuccessJson()..['status'] = 'limited',
        latestAttempt: _latestAttemptJson(status: 'limited', errorCode: null),
      );
    await _pumpScreen(tester, transport);

    expect(find.text('Limited report'), findsOneWidget);
    // Visible gap surfaced, not hidden.
    expect(find.textContaining('Earnings transcript unavailable'),
        findsOneWidget);
  });

  testWidgets('failed/stalled attempt never hides the prior success; error '
      'code is reported separately (backend C6/C7)', (tester) async {
    final transport = _JourneyTransport()
      ..positionWire = _positionJson(state: 'owned')
      ..latestWire = _latestWire(
        assessment: _assessmentJson(state: 'owned', action: 'hold'),
        lastSuccess: _lastSuccessJson(),
        latestAttempt: _latestAttemptJson(
          status: 'failed',
          errorCode: 'PIPELINE_VALIDATION_FAILED',
        ),
      );
    await _pumpScreen(tester, transport);

    // Prior success still grounds the panel...
    expect(find.text('Recommendation'), findsOneWidget);
    // ...and both run-state rows are distinct and truthful.
    expect(find.textContaining('Last successful report'), findsOneWidget);
    expect(find.textContaining('Latest attempt'), findsOneWidget);
    expect(find.textContaining('PIPELINE_VALIDATION_FAILED'), findsOneWidget);
  });

  testWidgets('no-result state renders the honest empty panel and no invented '
      'instrument identity (backend D1 boundary)', (tester) async {
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
}
