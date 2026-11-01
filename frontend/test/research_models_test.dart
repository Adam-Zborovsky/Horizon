// H11 — parser/serialization/error-state tests for the typed Flutter domain.
//
// Fixture provenance: every numeric value below is synthetic test data in the
// style of backend/test/fixtures/research (contract-version 1). Nothing here is
// observed market data, a user position, or a projection, and no credential,
// token, or password value appears in any fixture.
//
// Position fixtures encode the BACKEND wire exactly as emitted by
// backend/src/features/positions/position.service.js serialize() and accepted
// by position.routes.js: GET /positions returns {positions: [...]}, positions
// carry a nested `instrument` identity object, PATCH bodies are
// {expected_revision, changes: {...}}, and typed service errors surface as a
// flat {code, message} envelope.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:horizon/src/features/market/market_models.dart';
import 'package:horizon/src/features/market/market_repository.dart';
import 'package:horizon/src/features/positions/position_models.dart';
import 'package:horizon/src/features/positions/position_repository.dart';
import 'package:horizon/src/features/research/research_models.dart';
import 'package:horizon/src/features/research/research_repository.dart';

Map<String, dynamic> money(String amount, String currency) =>
    {'amount': amount, 'currency': currency};

Map<String, dynamic> ownedPositionFixture() => {
      'id': 'position-owned-0001',
      'instrument': instrumentFixture(),
      'state': 'owned',
      'average_cost': money('123.45', 'USD'),
      'quantity': '1.5',
      'opened_on': '2026-01-15',
      'preferred_horizon_months': 3,
      'original_thesis': 'User-authored thesis text.',
      'review_conditions': ['Reassess if guidance is cut.'],
      'risk_context': {
        'constraints': ['No more than one new position per quarter.'],
        'portfolio_context': null,
        'declared_at': '2026-01-15T10:00:00.000Z',
        'source': 'user_declared',
      },
      'archived': false,
      'revision': 4,
      'created_at': '2026-01-15T10:00:00.000Z',
      'updated_at': '2026-01-20T10:00:00.000Z',
    };

// Mirrors position.service.js planLegacyMigration/serialize() output for a
// legacy ticker: unresolved identity, null economics, nothing inferred.
Map<String, dynamic> legacyPositionFixture() => {
      'id': 'position-legacy-0001',
      'instrument': {
        'instrument_id': 'legacy-ticker-OLD',
        'symbol': 'OLD',
        'exchange': null,
        'currency': null,
        'provider_symbol': null,
      },
      'state': 'legacy_unclassified',
      'average_cost': null,
      'quantity': null,
      'opened_on': null,
      'archived': false,
      'revision': 1,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> barFixture({
  String time = '2026-03-06T14:30:00.000Z',
  String sessionDate = '2026-03-06',
  num open = 100,
  num high = 103,
  num low = 99,
  num close = 102,
  Object? volume = 1200,
  Object? adjustedClose,
  bool isFinal = true,
}) =>
    {
      'time': time,
      'session_date': sessionDate,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'adjusted_close': adjustedClose,
      'is_final': isFinal,
    };

Map<String, dynamic> instrumentFixture() => {
      'instrument_id': 'instrument-acme-1',
      'symbol': 'ACME',
      'exchange': 'XNYS',
      'currency': 'USD',
      'provider_symbol': 'ACME',
    };

const acmeInstrumentModel = PositionInstrument(
  instrumentId: 'instrument-acme-1',
  symbol: 'ACME',
  exchange: 'XNYS',
  currency: 'USD',
  providerSymbol: 'ACME',
);

/// Field-for-field mirror of position.service.js serialize() output for an
/// owned position: average_cost carries the stored `basis` key (create()
/// defaults it to 'raw_purchase'), absent original_thesis serializes as null
/// (H11 cross-lane empty-thesis repair — the wire never carries ''),
/// review_conditions is always a list. Used to prove the parser accepts the
/// exact wire the backend emits.
Map<String, dynamic> backendSerializedOwnedPosition() => {
      'id': 'position-owned-0002',
      'instrument': instrumentFixture(),
      'state': 'owned',
      'average_cost': {'amount': '123.45', 'currency': 'USD', 'basis': 'raw_purchase'},
      'quantity': '1.5',
      'opened_on': '2026-01-15',
      'preferred_horizon_months': 3,
      'original_thesis': null,
      'review_conditions': [],
      'risk_context': null,
      'archived': false,
      'revision': 1,
      'created_at': '2026-01-15T10:00:00.000Z',
      'updated_at': '2026-01-15T10:00:00.000Z',
      // Additive forward-compatible field must be ignored by the parser.
      'future_extension_field': {'ignored': true},
    };

Map<String, dynamic> historyResponseFixture({
  String dataStatus = 'available',
  bool isStale = false,
  String delayStatus = 'delayed',
  List<Map<String, dynamic>>? bars,
  String? unavailableReason,
  String? nextCursor,
  Map<String, dynamic>? instrument,
}) =>
    {
      'contract_version': 1,
      'instrument': instrument ?? instrumentFixture(),
      'snapshot_id': 'snapshot-0001',
      'range': '1M',
      'requested_resolution': '1d',
      'actual_resolution': '1d',
      'exchange_timezone': 'America/New_York',
      'session_mode': 'regular',
      'adjustment_basis': 'raw provider OHLCV',
      'as_of': '2026-03-06T20:00:00.000Z',
      'fetched_at': '2026-03-06T20:01:00.000Z',
      'data_status': dataStatus,
      'delay_status': delayStatus,
      'is_stale': isStale,
      'available_ranges': ['1D', '1M'],
      'bars': bars ?? [barFixture()],
      'warnings': [
        {'code': 'EXAMPLE_WARNING'},
      ],
      'next_cursor': nextCursor,
      if (unavailableReason != null) 'unavailable_reason': unavailableReason,
      // Additive forward-compatible field must be ignored by the parser.
      'future_extension_field': {'ignored': true},
    };

Map<String, dynamic> claimFixture(String text) => {
      'text': text,
      'evidence_ids': ['evidence-0001'],
      'metric_ids': ['metric-0001'],
      'claim_type': 'observed',
    };

Map<String, dynamic> outlookFixture({
  required int horizonMonths,
  required String sessionAsOf,
}) {
  // Month-end-clamped targets for session_as_of 2024-01-31.
  const targets = {1: '2024-02-29', 2: '2024-03-31', 3: '2024-04-30'};
  final target = targets[horizonMonths]!;
  return {
    'horizon_months': horizonMonths,
    'calendar_target_date': target,
    'evaluation_session_date': target,
      'direction': 'mixed',
      'base_case': [claimFixture('Base case claim.')],
      'upside_case': [claimFixture('Upside case claim.')],
      'downside_case': [claimFixture('Downside case claim.')],
      'catalysts': [claimFixture('Catalyst claim.')],
      'invalidators': [claimFixture('Invalidator claim.')],
      'numeric_projection': null,
      'data_limitations': ['Consensus estimates unavailable on the lean path.'],
  };
}

Map<String, dynamic> assessmentFixture({
  String state = 'owned',
  List<Map<String, dynamic>>? outlooks,
  String recommendationAction = 'hold',
}) =>
    {
      'id': 'assessment-0001',
      'contract_version': 1,
      'position_id': 'position-owned-0001',
      'position_revision': 4,
      'instrument_id': 'instrument-acme-1',
      'run_id': 'run-0001',
      'evidence_snapshot_id': 'snapshot-0001',
      'generated_at': '2026-03-06T20:00:00.000Z',
      'session_as_of': '2024-01-31',
      'status': 'complete',
      'market_thesis': {
        'business_assessment': {
          'summary': 'Business assessment summary.',
          'claims': [claimFixture('Business claim.')],
        },
        'price_technical_assessment': {
          'summary': 'Price technical summary.',
          'claims': [claimFixture('Technical claim.')],
        },
        'valuation_assessment': {
          'summary': 'Valuation summary.',
          'claims': [claimFixture('Valuation claim.')],
        },
        'rationale': [claimFixture('Rationale claim.')],
        'counterevidence': [claimFixture('Counterevidence claim.')],
      },
      'recommendation': {
        'action': recommendationAction,
        'horizon_months': 3,
        'headline': 'Direct recommendation headline.',
        'rationale': [claimFixture('Recommendation rationale.')],
        'countercase': [claimFixture('Recommendation countercase.')],
        'invalidation_conditions': [claimFixture('Invalidation condition.')],
        'evidence_quality': 'Limited coverage; primary sources retrieved.',
        'predictive_uncertainty':
            'High; single-session evidence with no calibrated model.',
      },
      'position_context': {
        'position_id': 'position-owned-0001',
        'instrument_id': 'instrument-acme-1',
        'state': state,
        'revision': 4,
        'economics_status': 'available',
      },
      'changes_since_previous': {
        'previous_assessment_id': 'assessment-0000',
        'previous_session_as_of': '2024-01-30',
        'missing_report_sessions': [],
        'thesis_changes': [
          {
            'component': 'business_assessment',
            'status': 'strengthened',
            'reason': 'New filing supports the prior conclusion.',
            'evidence_ids': ['evidence-0001'],
          },
        ],
        'checkpoint_change_ids': [],
      },
      'checkpoints': [
        {
          'id': 'checkpoint-0001',
          'instrument_id': 'instrument-acme-1',
          'kind': 'fixed_observed_level',
          'metric_id': null,
          'fixed_level': 150.0,
          'condition': 'Price closes below the observed 150.0 level.',
          'created_at': '2026-03-06T20:00:00.000Z',
          'updated_at': '2026-03-06T20:00:00.000Z',
          'status': 'active',
          'reason': 'Initial checkpoint from this assessment.',
          'source_assessment_id': 'assessment-0001',
        },
      ],
      'outlooks': outlooks ??
          [
            {
              ...outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
              'calendar_target_date': '2024-02-29',
              'evaluation_session_date': '2024-02-29',
            },
            outlookFixture(horizonMonths: 2, sessionAsOf: '2024-01-31'),
            outlookFixture(horizonMonths: 3, sessionAsOf: '2024-01-31'),
          ],
      'missing_data': ['Earnings call transcript unavailable.'],
      'next_review': '2026-03-13T20:00:00.000Z',
      'versions': {'contracts': '1', 'pipeline': 'fixed-bounded-v1'},
    };

Map<String, dynamic> runFixture({String status = 'succeeded'}) => {
      'id': 'run-0001',
      'position_id': 'position-owned-0001',
      'owner_id_internal': 'owner-0001',
      'position_revision': 4,
      'run_kind': 'deep_research',
      'idempotency_key': 'idempotency-0001',
      'status': status,
      'stage': 'delivery',
      'created_at': '2026-03-06T19:00:00.000Z',
      'started_at': '2026-03-06T19:00:01.000Z',
      'heartbeat_at': '2026-03-06T19:30:00.000Z',
      'deadline_at': '2026-03-06T21:00:00.000Z',
      'finished_at': '2026-03-06T20:00:00.000Z',
      'evidence_snapshot_id': 'snapshot-0001',
      'assessment_id': 'assessment-0001',
      'error_code': null,
      'retry_count': 0,
      'versions': {'contracts': '1'},
    };

http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

class RecordingClient extends http.BaseClient {
  RecordingClient(this.responder);

  final http.Response Function(http.BaseRequest request) responder;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = responder(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

/// In-flight client whose send blocks until [close]; models what the real
/// http IOClient does when a request is cancelled by closing the client.
class CancellationClient extends http.BaseClient {
  CancellationClient(this.payload);

  final Object payload;
  final Completer<void> gate = Completer<void>();
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await gate.future;
    if (closed) {
      throw http.ClientException('Client closed mid-flight', request.url);
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(payload))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  void close() {
    closed = true;
    if (!gate.isCompleted) gate.complete();
  }
}

void main() {
  group('Position models — strict parsing and legacy classification', () {
    test('parses a full owned position preserving decimal-string economics',
        () {
      final position = Position.fromJson(ownedPositionFixture());
      expect(position.id, 'position-owned-0001');
      expect(position.instrument.instrumentId, 'instrument-acme-1');
      expect(position.instrument.symbol, 'ACME');
      expect(position.instrument.exchange, 'XNYS');
      expect(position.instrument.currency, 'USD');
      expect(position.instrument.providerSymbol, 'ACME');
      expect(position.state, PositionState.owned);
      expect(position.averageCost?.amount, '123.45');
      expect(position.averageCost?.currency, 'USD');
      expect(position.quantity, '1.5');
      expect(position.openedOn, '2026-01-15');
      expect(position.preferredHorizonMonths, 3);
      expect(position.riskContext?.source, 'user_declared');
      expect(position.revision, 4);
    });

    test('parses the exact backend serialize() shape including stored basis',
        () {
      final position = Position.fromJson(backendSerializedOwnedPosition());
      expect(position.instrument.instrumentId, 'instrument-acme-1');
      expect(position.instrument.symbol, 'ACME');
      expect(position.averageCost?.amount, '123.45');
      expect(position.averageCost?.currency, 'USD');
      // H11 cross-lane empty-thesis repair: the repaired backend serialize()
      // emits null for a no-thesis position, never ''.
      expect(position.originalThesis, isNull);
      expect(position.reviewConditions, isEmpty);
      expect(position.riskContext, isNull);
      expect(position.revision, 1);
    });

    test('normalizes a legacy empty-string original_thesis to null', () {
      // Defensive normalization in optionalBoundedText: a producer still
      // emitting '' must parse to null instead of throwing
      // ContractFormatException (which the position editor does not catch).
      final legacy = backendSerializedOwnedPosition()
        ..['original_thesis'] = '';
      final position = Position.fromJson(legacy);
      expect(position.originalThesis, isNull);
    });

    test('rejects a malformed nested instrument identity object', () {
      final missingSymbol = ownedPositionFixture()
        ..['instrument'] = {
          'instrument_id': 'instrument-acme-1',
          'exchange': 'XNYS',
          'currency': 'USD',
          'provider_symbol': 'ACME',
        };
      expect(() => Position.fromJson(missingSymbol),
          throwsA(isA<ContractFormatException>()));

      final badCurrency = ownedPositionFixture()
        ..['instrument'] = {
          'instrument_id': 'instrument-acme-1',
          'symbol': 'ACME',
          'exchange': null,
          'currency': 'usd',
          'provider_symbol': null,
        };
      expect(() => Position.fromJson(badCurrency),
          throwsA(isA<ContractFormatException>()));
    });

    test('legacy_unclassified keeps null economics distinct from zero', () {
      final position = Position.fromJson(legacyPositionFixture());
      expect(position.state, PositionState.legacyUnclassified);
      expect(position.averageCost, isNull);
      expect(position.quantity, isNull);
      expect(position.openedOn, isNull);
    });

    test('candidate records reject executed economics or an opening date', () {
      final base = ownedPositionFixture()
        ..['id'] = 'position-candidate-0001'
        ..['state'] = 'candidate'
        ..remove('risk_context');
      for (final field in ['average_cost', 'quantity', 'opened_on']) {
        expect(
          () => Position.fromJson(base),
          throwsA(isA<ContractFormatException>()),
          reason: '$field must be rejected on a candidate record',
        );
      }
    });

    test('zero is not a valid missing economics value', () {
      final zeroQuantity = legacyPositionFixture()..['quantity'] = '0';
      expect(
        () => Position.fromJson(zeroQuantity),
        throwsA(isA<ContractFormatException>()),
      );
      final zeroCost = ownedPositionFixture()
        ..['average_cost'] = money('0', 'USD');
      expect(
        () => Position.fromJson(zeroCost),
        throwsA(isA<ContractFormatException>()),
      );
    });

    test('rejects malformed decimals, currencies, states and horizons', () {
      final badState = legacyPositionFixture()..['state'] = 'owned_soon';
      expect(() => Position.fromJson(badState),
          throwsA(isA<ContractFormatException>()));

      final badDecimal = ownedPositionFixture()..['quantity'] = '1e3';
      expect(() => Position.fromJson(badDecimal),
          throwsA(isA<ContractFormatException>()));

      final badCurrency = ownedPositionFixture()
        ..['average_cost'] = money('123.45', 'usd');
      expect(() => Position.fromJson(badCurrency),
          throwsA(isA<ContractFormatException>()));

      final badHorizon = legacyPositionFixture()
        ..['preferred_horizon_months'] = 4;
      expect(() => Position.fromJson(badHorizon),
          throwsA(isA<ContractFormatException>()));
    });

    test('preferred_horizon_months defaults to 3 when the user has not chosen',
        () {
      final position = Position.fromJson(legacyPositionFixture());
      expect(position.preferredHorizonMonths, 3);
    });

    test('write payload is strict: nested instrument, no owner fields, '
        'no expected_revision in the create body', () {
      const write = PositionWrite(
        instrument: acmeInstrumentModel,
        state: PositionState.owned,
        averageCost: MoneyAmount(amount: '123.45', currency: 'USD'),
        quantity: '1.5',
        expectedRevision: 4,
      );
      final json = write.toJson();
      expect(json.keys,
          unorderedEquals(['instrument', 'state', 'average_cost', 'quantity']));
      expect(json['instrument'], instrumentFixture());
      expect(json.containsKey('instrument_id'), isFalse,
          reason: 'the backend wire carries a nested instrument object');
      expect(json.containsKey('expected_revision'), isFalse,
          reason:
              'expected_revision is not an ALLOWED_FIELDS entry; create() '
              'rejects unknown fields, so it must only appear in the PATCH '
              'envelope, never the create body');
      expect(json.containsKey('owner_id_internal'), isFalse);
      expect(json['state'], 'owned');
      expect(
        () => const PositionWrite(
          instrument: acmeInstrumentModel,
          state: PositionState.candidate,
          quantity: '1.5',
        ).toJson(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Market bar and history models — unavailable vs zero, ordering', () {
    test('parses an observed-style bar preserving null volume vs zero volume',
        () {
      final bar = MarketBar.fromJson(barFixture(volume: null));
      expect(bar.volume, isNull, reason: 'unavailable volume stays null');
      final zeroVolume = MarketBar.fromJson(barFixture(volume: 0));
      expect(zeroVolume.volume, 0, reason: 'zero volume is preserved as zero');
      final adjusted = MarketBar.fromJson(barFixture(adjustedClose: 101.5));
      expect(adjusted.adjustedClose, 101.5);
    });

    test('rejects OHLC invariant violations and non-positive prices', () {
      expect(
        () => MarketBar.fromJson(barFixture(low: 102.5)),
        throwsA(isA<ContractFormatException>()),
        reason: 'low must be <= min(open, close)',
      );
      expect(
        () => MarketBar.fromJson(barFixture(high: 101)),
        throwsA(isA<ContractFormatException>()),
        reason: 'high must be >= max(open, close)',
      );
      expect(
        () => MarketBar.fromJson(barFixture(open: 0)),
        throwsA(isA<ContractFormatException>()),
      );
    });

    test('rejects non-integer volume and invalid timestamps', () {
      expect(() => MarketBar.fromJson(barFixture(volume: 12.5)),
          throwsA(isA<ContractFormatException>()));
      expect(
        () => MarketBar.fromJson(barFixture(time: '2026-03-06T25:30:00.000Z')),
        throwsA(isA<ContractFormatException>()),
      );
      expect(
        () => MarketBar.fromJson(barFixture(sessionDate: '2026-02-31')),
        throwsA(isA<ContractFormatException>()),
      );
    });

    test('history response parses with additive-field tolerance', () {
      final history = HistoryResponse.fromJson(historyResponseFixture());
      expect(history.contractVersion, 1);
      expect(history.range, MarketRange.oneMonth);
      expect(history.dataStatus, DataStatus.available);
      expect(history.delayStatus, DelayStatus.delayed);
      expect(history.bars, hasLength(1));
      expect(history.snapshotId, 'snapshot-0001');
    });

    test('unavailable history requires an empty result and machine reason',
        () {
      final unavailable = HistoryResponse.fromJson(historyResponseFixture(
        dataStatus: 'unavailable',
        bars: [],
        unavailableReason: 'UNSUPPORTED_RESOLUTION',
      ));
      expect(unavailable.dataStatus, DataStatus.unavailable);
      expect(unavailable.unavailableReason, 'UNSUPPORTED_RESOLUTION');

      expect(
        () => HistoryResponse.fromJson(historyResponseFixture(
          dataStatus: 'unavailable',
          bars: [],
        )),
        throwsA(isA<ContractFormatException>()),
        reason: 'unavailable without a reason is invalid',
      );
      expect(
        () => HistoryResponse.fromJson(historyResponseFixture(
          dataStatus: 'unavailable',
          unavailableReason: 'NO_VALID_BARS',
        )),
        throwsA(isA<ContractFormatException>()),
        reason: 'unavailable responses cannot carry bars',
      );
    });

    test('stale cache data cannot claim realtime delivery', () {
      expect(
        () => HistoryResponse.fromJson(historyResponseFixture(
          isStale: true,
          delayStatus: 'realtime',
        )),
        throwsA(isA<ContractFormatException>()),
      );
    });

    test('bars must be ascending and unique by session bucket', () {
      final descending = historyResponseFixture(bars: [
        barFixture(time: '2026-03-09T13:30:00.000Z', sessionDate: '2026-03-09'),
        barFixture(),
      ]);
      expect(() => HistoryResponse.fromJson(descending),
          throwsA(isA<ContractFormatException>()));

      final duplicated = historyResponseFixture(bars: [
        barFixture(),
        barFixture(),
      ]);
      expect(() => HistoryResponse.fromJson(duplicated),
          throwsA(isA<ContractFormatException>()));
    });

    test('unknown ranges and statuses are rejected, not repaired', () {
      final badRange = historyResponseFixture()..['range'] = '2Q';
      expect(() => HistoryResponse.fromJson(badRange),
          throwsA(isA<ContractFormatException>()));
      final badDelay = historyResponseFixture()..['delay_status'] = 'fast';
      expect(() => HistoryResponse.fromJson(badDelay),
          throwsA(isA<ContractFormatException>()));
    });
  });

  group('Research models — claims, outlooks, overlays, run states', () {
    test('full owned assessment parses with month-end clamped outlooks', () {
      final assessment = ResearchAssessment.fromJson(assessmentFixture());
      expect(assessment.status, AssessmentStatus.complete);
      expect(assessment.outlooks, hasLength(3));
      expect(assessment.outlooks[0].calendarTargetDate, '2024-02-29',
          reason: 'Jan 31 + 1 calendar month clamps to Feb 29 in a leap year');
      expect(assessment.outlooks[1].calendarTargetDate, '2024-03-31');
      expect(assessment.outlooks[2].calendarTargetDate, '2024-04-30');
      expect(assessment.recommendation.action, RecommendationAction.hold);
    });

    test('calendarTargetDate mirrors contract month-end clamping', () {
      expect(calendarTargetDate('2024-01-31', 1), '2024-02-29');
      expect(calendarTargetDate('2023-01-31', 1), '2023-02-28');
      expect(calendarTargetDate('2024-01-30', 1), '2024-02-29');
      expect(calendarTargetDate('2024-11-30', 2), '2025-01-30');
      expect(
        () => calendarTargetDate('9999-12-31', 1),
        throwsA(isA<RangeError>()),
        reason: 'Year overflow is rejected, never emitted as year 10000',
      );
      expect(() => calendarTargetDate('2024-01-31', 4),
          throwsA(isA<ArgumentError>()));
    });

    test('outlooks must contain exactly one 1, 2 and 3 month entry', () {
      final missing = assessmentFixture(
        outlooks: [
          outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
          outlookFixture(horizonMonths: 3, sessionAsOf: '2024-01-31'),
        ],
      );
      expect(() => ResearchAssessment.fromJson(missing),
          throwsA(isA<ContractFormatException>()));

      final duplicated = assessmentFixture(
        outlooks: [
          outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
          outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
          outlookFixture(horizonMonths: 3, sessionAsOf: '2024-01-31'),
        ],
      );
      expect(() => ResearchAssessment.fromJson(duplicated),
          throwsA(isA<ContractFormatException>()));
    });

    test('recommendation action must be compatible with the position state',
        () {
      final legacyWithBuy = assessmentFixture(
        state: 'legacy_unclassified',
        recommendationAction: 'buy',
      );
      expect(() => ResearchAssessment.fromJson(legacyWithBuy),
          throwsA(isA<ContractFormatException>()));

      final candidateWithAdd = assessmentFixture(
        state: 'candidate',
        recommendationAction: 'add',
      );
      expect(() => ResearchAssessment.fromJson(candidateWithAdd),
          throwsA(isA<ContractFormatException>()));
    });

    test('position context identity must match the assessment', () {
      final mismatched = assessmentFixture();
      (mismatched['position_context'] as Map<String, dynamic>)['position_id'] =
          'position-other-0001';
      expect(() => ResearchAssessment.fromJson(mismatched),
          throwsA(isA<ContractFormatException>()));
    });

    test('numeric projection bounds and kind rules are enforced', () {
      Map<String, dynamic> projectionFixture(Map<String, dynamic> overrides) =>
          {
            'id': 'projection-0001',
            'assessment_id': 'assessment-0001',
            'instrument_id': 'instrument-acme-1',
            'evidence_snapshot_id': 'snapshot-0001',
            'anchor_time': '2026-03-06T20:00:00.000Z',
            'anchor_price_metric_id': 'metric-0001',
            'target_session_date': '2024-02-29',
            'kind': 'conditional_scenario',
            'method': 'deterministic scenario math',
            'method_version': 'v1',
            'input_metric_ids': ['metric-0001'],
            'assumption_ids': ['assumption-0001'],
            'lower': 90.0,
            'central': 100.0,
            'upper': 110.0,
            'currency': 'USD',
            'adjustment_basis': 'raw provider OHLCV',
            'calibration': null,
            'valid_until': null,
            'limitations': ['Not calibrated probabilities.'],
            ...overrides,
          };

      final valid = Outlook.fromJson({
        ...outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
        'calendar_target_date': '2024-02-29',
        'evaluation_session_date': '2024-02-29',
        'numeric_projection': projectionFixture({}),
      });
      expect(valid.numericProjection?.central, 100.0);

      expect(
        () => Outlook.fromJson({
          ...outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
          'calendar_target_date': '2024-02-29',
          'evaluation_session_date': '2024-02-29',
          'numeric_projection':
              projectionFixture({'lower': 105.0, 'central': 100.0}),
        }),
        throwsA(isA<ContractFormatException>()),
        reason: 'lower cannot exceed central',
      );

      expect(
        () => Outlook.fromJson({
          ...outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
          'calendar_target_date': '2024-02-29',
          'evaluation_session_date': '2024-02-29',
          'numeric_projection': projectionFixture({
            'lower': null,
            'central': null,
            'upper': null,
          }),
        }),
        throwsA(isA<ContractFormatException>()),
        reason: 'at least one bound is required',
      );

      expect(
        () => Outlook.fromJson({
          ...outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
          'calendar_target_date': '2024-02-29',
          'evaluation_session_date': '2024-02-29',
          'numeric_projection':
              projectionFixture({'assumption_ids': <String>[]}),
        }),
        throwsA(isA<ContractFormatException>()),
        reason: 'conditional scenarios require explicit assumptions',
      );

      expect(
        () => Outlook.fromJson({
          ...outlookFixture(horizonMonths: 1, sessionAsOf: '2024-01-31'),
          'calendar_target_date': '2024-02-29',
          'evaluation_session_date': '2024-02-29',
          'numeric_projection':
              projectionFixture({'kind': 'calibrated_forecast'}),
        }),
        throwsA(isA<ContractFormatException>()),
        reason: 'calibrated forecasts require calibration evidence',
      );
    });

    test('checkpoint kind/exclusive-field rules are enforced', () {
      Map<String, dynamic> checkpointFixture(Map<String, dynamic> overrides) =>
          {
            'id': 'checkpoint-0001',
            'instrument_id': 'instrument-acme-1',
            'kind': 'fixed_observed_level',
            'metric_id': null,
            'fixed_level': 150.0,
            'condition': 'Price closes below the observed 150.0 level.',
            'created_at': '2026-03-06T20:00:00.000Z',
            'updated_at': '2026-03-06T20:00:00.000Z',
            'status': 'active',
            'reason': 'Initial checkpoint from this assessment.',
            'source_assessment_id': 'assessment-0001',
            ...overrides,
          };

      expect(Checkpoint.fromJson(checkpointFixture({})).fixedLevel, 150.0);
      expect(
        () => Checkpoint.fromJson(
            checkpointFixture({'kind': 'rolling_indicator'})),
        throwsA(isA<ContractFormatException>()),
        reason: 'rolling checkpoints require a metric reference',
      );
      expect(
        () => Checkpoint.fromJson(checkpointFixture({
          'kind': 'rolling_indicator',
          'metric_id': 'metric-0001',
        })),
        throwsA(isA<ContractFormatException>()),
        reason: 'rolling checkpoints cannot carry a fixed level',
      );
      expect(
        () => Checkpoint.fromJson(
            checkpointFixture({'kind': 'business_condition'})),
        throwsA(isA<ContractFormatException>()),
        reason: 'business conditions cannot carry a fixed level',
      );
      expect(
        () => Checkpoint.fromJson(checkpointFixture({
          'kind': 'business_condition',
          'metric_id': 'metric-0001',
        })),
        throwsA(isA<ContractFormatException>()),
      );
      expect(
        () => Checkpoint.fromJson(checkpointFixture({
          'updated_at': '2026-03-05T20:00:00.000Z',
        })),
        throwsA(isA<ContractFormatException>()),
        reason: 'update cannot precede creation',
      );
    });

    test('claims reject duplicate references', () {
      expect(
        () => Claim.fromJson({
          'text': 'Duplicate reference claim.',
          'evidence_ids': ['evidence-0001', 'evidence-0001'],
          'metric_ids': ['metric-0001'],
          'claim_type': 'observed',
        }),
        throwsA(isA<ContractFormatException>()),
      );
    });

    test('run state invariants are enforced', () {
      expect(ResearchRun.fromJson(runFixture()).status, RunStatus.succeeded);

      final queuedWithStart = runFixture(status: 'queued')
        ..['started_at'] = '2026-03-06T19:00:01.000Z';
      expect(() => ResearchRun.fromJson(queuedWithStart),
          throwsA(isA<ContractFormatException>()));

      final succeededWithoutAssessment = runFixture()
        ..['assessment_id'] = null;
      expect(() => ResearchRun.fromJson(succeededWithoutAssessment),
          throwsA(isA<ContractFormatException>()));

      final failedWithoutError = runFixture(status: 'failed')
        ..['error_code'] = null
        ..['assessment_id'] = null
        ..['evidence_snapshot_id'] = null;
      expect(() => ResearchRun.fromJson(failedWithoutError),
          throwsA(isA<ContractFormatException>()));

      final unknownStatus = runFixture()..['status'] = 'winning';
      expect(() => ResearchRun.fromJson(unknownStatus),
          throwsA(isA<ContractFormatException>()));
    });

    test('ResearchLatest parses the canonical top-level wire with separate '
        'run_state projections', () {
      // Canonical shape per backend/src/features/research/research.routes.js:67-74
      // and research.service.js:813-832 (projections, NOT full run views).
      final latest = ResearchLatest.fromJson({
        'position_id': 'position-owned-0001',
        'latest_assessment': assessmentFixture(),
        'run_state': {
          'last_success': {
            'run_id': 'run-0001',
            'status': 'succeeded',
            'assessment_id': 'assessment-0001',
            'evidence_snapshot_id': 'snapshot-0001',
            'finished_at': '2026-03-06T20:00:00.000Z',
          },
          'latest_attempt': {
            'run_id': 'run-0002',
            'status': 'running',
            'stage': 'delivery',
            'started_at': '2026-03-06T19:00:01.000Z',
            'finished_at': null,
            'error_code': null,
            'deadline_at': '2026-03-06T21:00:00.000Z',
          },
        },
      });
      expect(latest.positionId, 'position-owned-0001');
      expect(latest.latestAssessment!.id, 'assessment-0001');
      // last_success and latest_attempt stay SEPARATE truthful states: the
      // last successful run (run-0001) is not collapsed into the latest
      // attempt (run-0002, running).
      expect(latest.lastSuccess!.runId, 'run-0001');
      expect(latest.lastSuccess!.status, RunStatus.succeeded);
      expect(latest.lastSuccess!.assessmentId, 'assessment-0001');
      expect(latest.lastSuccess!.evidenceSnapshotId, 'snapshot-0001');
      expect(latest.latestAttempt!.runId, 'run-0002');
      expect(latest.latestAttempt!.status, RunStatus.running);
      expect(latest.latestAttempt!.stage, 'delivery');
      expect(latest.latestAttempt!.finishedAt, isNull);
      expect(latest.latestAttempt!.errorCode, isNull);
      expect(latest.latestAttempt!.deadlineAt, '2026-03-06T21:00:00.000Z');
    });

    test('ResearchLatest empty state yields null fields, not throws '
        '(CONTRACTS §9)', () {
      final latest = ResearchLatest.fromJson({
        'position_id': 'position-owned-0001',
        'latest_assessment': null,
        'run_state': {'last_success': null, 'latest_attempt': null},
      });
      expect(latest.latestAssessment, isNull);
      expect(latest.lastSuccess, isNull);
      expect(latest.latestAttempt, isNull);
    });

    test('ResearchLatest rejects shapes that drift from the real wire', () {
      // The pre-repair assumed envelope {assessment, run} has no run_state on
      // the real wire and must not silently parse as an empty state.
      expect(
        () => ResearchLatest.fromJson({'assessment': null, 'run': null}),
        throwsA(isA<ContractFormatException>()),
      );
      expect(
        () => ResearchLatest.fromJson({
          'position_id': 'position-owned-0001',
          'latest_assessment': 'not-an-object',
          'run_state': {'last_success': null, 'latest_attempt': null},
        }),
        throwsA(isA<ContractFormatException>()),
      );
      expect(
        () => ResearchLatest.fromJson({
          'position_id': 'position-owned-0001',
          'latest_assessment': null,
          'run_state': {
            'last_success': null,
            'latest_attempt': {'run_id': 'run-0002', 'status': 'winning'},
          },
        }),
        throwsA(isA<ContractFormatException>()),
      );
    });

    test('legacy_unclassified position-specific assessment requires revision',
        () {
      final legacy = assessmentFixture(state: 'legacy_unclassified');
      (legacy['recommendation'] as Map<String, dynamic>)['action'] =
          'insufficient_evidence';
      legacy['position_revision'] = null;
      (legacy['position_context'] as Map<String, dynamic>)['revision'] = null;
      expect(() => ResearchAssessment.fromJson(legacy),
          throwsA(isA<ContractFormatException>()));
    });
  });

  group('PositionRepository — auth, errors and write payloads', () {
    test('sends Bearer token and parses the {positions: [...]} envelope',
        () async {
      final client = RecordingClient(
        (_) => jsonResponse({'positions': [ownedPositionFixture()]}),
      );
      final repository = PositionRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      final positions = await repository.getPositions();
      expect(positions, hasLength(1));
      expect(positions.single.instrument.instrumentId, 'instrument-acme-1');
      expect(
        client.requests.single.headers['Authorization'],
        'Bearer fixture-token-not-a-secret',
      );
      expect(client.requests.single.url.path, endsWith('/positions'));
    });

    test('rejects non-{positions} envelopes instead of repairing them',
        () async {
      for (final body in [
        <String, dynamic>{'data': [ownedPositionFixture()]},
        <String, dynamic>[ownedPositionFixture()],
      ]) {
        final client = RecordingClient((_) => jsonResponse(body));
        final repository = PositionRepository(
          client: client,
          tokenProvider: () async => 'fixture-token-not-a-secret',
        );
        await expectLater(
          repository.getPositions(),
          throwsA(isA<ContractFormatException>()),
          reason:
              'GET /positions returns {positions: [...]}; any other shape is '
              'a contract drift, never repaired',
        );
        repository.close();
      }
    });

    test('Authorization header attached only when a token exists', () async {
      final client = RecordingClient(
        (_) => jsonResponse({'positions': [legacyPositionFixture()]}),
      );
      final repository = PositionRepository(
        client: client,
        tokenProvider: () async => null,
      );
      await repository.getPositions();
      expect(client.requests.single.headers
          .containsKey('Authorization'), isFalse);
    });

    test('maps non-2xx responses to typed ApiException with safe code',
        () async {
      final client = RecordingClient(
        (request) => jsonResponse({
          'success': false,
          'error': {'message': 'Request failed.', 'code': 'INVALID_PAYLOAD'},
        }, status: 422),
      );
      final repository = PositionRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      await expectLater(
        repository.getPositions(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.code, 'code', 'INVALID_PAYLOAD')),
      );
    });

    test('maps the position routes flat {code, message} error envelope',
        () async {
      final client = RecordingClient(
        (request) => jsonResponse({
          'code': 'REVISION_CONFLICT',
          'message': 'expected_revision 4 does not match current revision 6',
        }, status: 409),
      );
      final repository = PositionRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      await expectLater(
        repository.getPositions(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.code, 'code', 'REVISION_CONFLICT')
            .having((e) => e.message, 'message',
                'expected_revision 4 does not match current revision 6')),
      );
    });

    test('PATCH sends {expected_revision, changes} with backend field names',
        () async {
      final client = RecordingClient(
        (request) => jsonResponse(ownedPositionFixture()),
      );
      final repository = PositionRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      await repository.patchPosition(
        'position-owned-0001',
        const PositionWrite(
          instrument: acmeInstrumentModel,
          state: PositionState.owned,
          expectedRevision: 4,
        ),
      );

      final request = client.requests.single;
      expect(request.method, 'PATCH');
      expect(request.url.path, endsWith('/positions/position-owned-0001'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.keys, unorderedEquals(['expected_revision', 'changes']));
      expect(body['expected_revision'], 4);
      final changes = body['changes'] as Map<String, dynamic>;
      expect(changes.keys, unorderedEquals(['state', 'instrument']));
      expect(changes['state'], 'owned');
      expect(changes['instrument'], instrumentFixture(),
          reason:
              'changed-field names must match backend ALLOWED_FIELDS: '
              '`instrument` (the nested object), never `instrument_id`');
    });

    test('PATCH without expected_revision is rejected before any request',
        () async {
      final client = RecordingClient(
        (request) => jsonResponse(ownedPositionFixture()),
      );
      final repository = PositionRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      expect(
        () => repository.patchPosition(
          'position-owned-0001',
          const PositionWrite(
            instrument: acmeInstrumentModel,
            state: PositionState.owned,
          ),
        ),
        throwsArgumentError,
      );
      expect(client.requests, isEmpty);
    });

    test('addPosition posts a strict write payload to /positions', () async {
      final client = RecordingClient(
        (request) => jsonResponse(ownedPositionFixture(), status: 201),
      );
      final repository = PositionRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      await repository.addPosition(const PositionWrite(
        instrument: acmeInstrumentModel,
        state: PositionState.owned,
      ));

      final request = client.requests.single;
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('owner_id_internal'), isFalse);
      expect(body['instrument'], instrumentFixture(),
          reason:
              'create() validates input.instrument via validateInstrument(); '
              'a top-level instrument_id would be rejected as UNKNOWN_FIELD');
      expect(body.containsKey('instrument_id'), isFalse);
      expect(body.containsKey('expected_revision'), isFalse);
    });
  });

  group('MarketRepository — authenticated history requests', () {
    test('builds validated query parameters and parses the response',
        () async {
      final client = RecordingClient(
        (request) => jsonResponse(historyResponseFixture()),
      );
      final repository = MarketRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      final history = await repository.getHistory(
        instrumentId: 'instrument-acme-1',
        range: MarketRange.oneMonth,
        resolution: '1d',
        snapshotId: 'snapshot-0001',
      );
      expect(history.dataStatus, DataStatus.available);

      final request = client.requests.single;
      expect(request.url.path,
          endsWith('/market/instruments/instrument-acme-1/history'));
      expect(request.url.queryParameters['range'], '1M');
      expect(request.url.queryParameters['resolution'], '1d');
      expect(request.url.queryParameters['snapshot_id'], 'snapshot-0001');
      expect(
        request.headers['Authorization'],
        'Bearer fixture-token-not-a-secret',
      );
    });
  });

  group('ResearchRepository — run queueing and pagination', () {
    test('queueRun sends the required Idempotency-Key header', () async {
      final client = RecordingClient(
        (request) => jsonResponse(runFixture(), status: 202),
      );
      final repository = ResearchRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      final run = await repository.queueRun(
        'position-owned-0001',
        idempotencyKey: 'fixture-idempotency-key',
      );
      expect(run.status, RunStatus.succeeded);

      final request = client.requests.single;
      expect(request.headers['Idempotency-Key'], 'fixture-idempotency-key');
      expect(request.url.path, endsWith('/research/positions/position-owned-0001/runs'));
    });

    test('getLatest parses the canonical top-level wire: nullable assessment '
        'and separate run_state projections', () async {
      // Canonical empty state per research.routes.js:67-74: null
      // latest_assessment and null run_state entries (CONTRACTS §9), not
      // the pre-repair assumed {assessment, run} envelope.
      final client = RecordingClient(
        (request) => jsonResponse({
          'position_id': 'position-owned-0001',
          'latest_assessment': null,
          'run_state': {'last_success': null, 'latest_attempt': null},
        }),
      );
      final repository = ResearchRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      final latest = await repository.getLatest('position-owned-0001');
      expect(latest.positionId, 'position-owned-0001');
      expect(latest.latestAssessment, isNull);
      expect(latest.lastSuccess, isNull);
      expect(latest.latestAttempt, isNull);
      final request = client.requests.single;
      expect(request.url.path,
          endsWith('/research/positions/position-owned-0001/latest'));
    });

    test('getLatest keeps last_success and latest_attempt as separate states',
        () async {
      final client = RecordingClient(
        (request) => jsonResponse({
          'position_id': 'position-owned-0001',
          'latest_assessment': assessmentFixture(),
          'run_state': {
            'last_success': {
              'run_id': 'run-0001',
              'status': 'succeeded',
              'assessment_id': 'assessment-0001',
              'evidence_snapshot_id': 'snapshot-0001',
              'finished_at': '2026-03-06T20:00:00.000Z',
            },
            'latest_attempt': {
              'run_id': 'run-0002',
              'status': 'failed',
              'stage': 'synthesis',
              'started_at': '2026-03-06T19:00:01.000Z',
              'finished_at': '2026-03-06T19:40:00.000Z',
              'error_code': 'EVIDENCE_SOURCE_UNAVAILABLE',
              'deadline_at': '2026-03-06T21:00:00.000Z',
            },
          },
        }),
      );
      final repository = ResearchRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      final latest = await repository.getLatest('position-owned-0001');
      expect(latest.latestAssessment, isNotNull);
      expect(latest.lastSuccess!.runId, 'run-0001');
      expect(latest.lastSuccess!.status, RunStatus.succeeded);
      expect(latest.latestAttempt!.runId, 'run-0002');
      expect(latest.latestAttempt!.status, RunStatus.failed);
      expect(latest.latestAttempt!.errorCode, 'EVIDENCE_SOURCE_UNAVAILABLE');
    });

    test('listAssessments parses cursor pagination', () async {
      final client = RecordingClient(
        (request) => jsonResponse({
          'assessments': [assessmentFixture()],
          'next_cursor': 'cursor-0002',
        }),
      );
      final repository = ResearchRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      final page = await repository.listAssessments('position-owned-0001');
      expect(page.assessments, hasLength(1));
      expect(page.nextCursor, 'cursor-0002');
    });
  });

  group('Cancellation — closing the client surfaces ClientException', () {
    test('in-flight request rejects when the injected client is closed',
        () async {
      final client = CancellationClient(historyResponseFixture());
      final repository = MarketRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      final inFlight = repository.getHistory(
        instrumentId: 'instrument-acme-1',
        range: MarketRange.oneDay,
      );
      repository.close();

      await expectLater(inFlight, throwsA(isA<http.ClientException>()));
    });

    test('requests after close are not silently re-created', () async {
      final client = CancellationClient(historyResponseFixture());
      final repository = MarketRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );

      repository.close();
      await expectLater(
        repository.getHistory(
          instrumentId: 'instrument-acme-1',
          range: MarketRange.oneDay,
        ),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  group('Credential hygiene', () {
    test('write payloads never carry server-derived owner identity',
        () async {
      final client = RecordingClient(
        (request) => jsonResponse(runFixture(), status: 202),
      );
      final repository = ResearchRepository(
        client: client,
        tokenProvider: () async => 'fixture-token-not-a-secret',
      );
      await repository.queueRun(
        'position-owned-0001',
        idempotencyKey: 'fixture-idempotency-key',
      );
      final request = client.requests.single;
      final body = request.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.keys.any((k) => k.contains('owner')), isFalse);
      expect(body.keys.any((k) => k.contains('password') || k.contains('secret')), isFalse);
    });
  });
}
