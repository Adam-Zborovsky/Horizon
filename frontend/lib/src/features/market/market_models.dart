// H11 — typed observed market bar and chart-history domain models.
//
// Source of truth: docs/horizon/CONTRACTS.md §3 and the executable backend
// schemas in backend/src/features/research/contracts.js
// (marketBarSchema / historyResponseSchema) as produced by the H15A
// MarketHistoryService. Parsing is strict: unavailable versus zero volume,
// adjustment basis, delay status and stale flags are preserved exactly, bars
// must be ascending and unique by session bucket, and unavailable responses
// must be empty with a machine-readable reason. Unknown additive fields are
// ignored (forward-compatible); known malformed fields are rejected, never
// repaired. Nothing here manufactures or infers market data.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../positions/position_models.dart';

part 'market_models.freezed.dart';

/// UI range semantics of CONTRACTS §3.
enum MarketRange {
  oneDay,
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear;

  String get wireValue => switch (this) {
        MarketRange.oneDay => '1D',
        MarketRange.oneWeek => '1W',
        MarketRange.oneMonth => '1M',
        MarketRange.threeMonths => '3M',
        MarketRange.sixMonths => '6M',
        MarketRange.oneYear => '1Y',
      };

  static MarketRange parse(Object? value) => switch (value) {
        '1D' => MarketRange.oneDay,
        '1W' => MarketRange.oneWeek,
        '1M' => MarketRange.oneMonth,
        '3M' => MarketRange.threeMonths,
        '6M' => MarketRange.sixMonths,
        '1Y' => MarketRange.oneYear,
        _ => throw ContractFormatException(
            'Field "range": expected one of 1D, 1W, 1M, 3M, 6M, 1Y'),
      };
}

/// `data_status`: availability of the returned bar series.
enum DataStatus {
  available,
  partial,
  unavailable;

  String get wireValue => switch (this) {
        DataStatus.available => 'available',
        DataStatus.partial => 'partial',
        DataStatus.unavailable => 'unavailable',
      };

  static DataStatus parse(Object? value) => switch (value) {
        'available' => DataStatus.available,
        'partial' => DataStatus.partial,
        'unavailable' => DataStatus.unavailable,
        _ => throw ContractFormatException(
            'Field "data_status": expected available, partial or unavailable'),
      };
}

/// `delay_status`: never claims real-time by default.
enum DelayStatus {
  realtime,
  delayed,
  unknown;

  String get wireValue => switch (this) {
        DelayStatus.realtime => 'realtime',
        DelayStatus.delayed => 'delayed',
        DelayStatus.unknown => 'unknown',
      };

  static DelayStatus parse(Object? value) => switch (value) {
        'realtime' => DelayStatus.realtime,
        'delayed' => DelayStatus.delayed,
        'unknown' => DelayStatus.unknown,
        _ => throw ContractFormatException(
            'Field "delay_status": expected realtime, delayed or unknown'),
      };
}

/// `session_mode`: extended-hours support is labeled, never inferred.
enum SessionMode {
  regular,
  extended;

  String get wireValue => switch (this) {
        SessionMode.regular => 'regular',
        SessionMode.extended => 'extended',
      };

  static SessionMode parse(Object? value) => switch (value) {
        'regular' => SessionMode.regular,
        'extended' => SessionMode.extended,
        _ => throw ContractFormatException(
            'Field "session_mode": expected regular or extended'),
      };
}

/// Instrument identity is never a ticker alone (CONTRACTS §1).
@freezed
abstract class InstrumentIdentity with _$InstrumentIdentity {
  const factory InstrumentIdentity({
    required String instrumentId,
    required String symbol,
    required String exchange,
    required String currency,
    required String providerSymbol,
  }) = _InstrumentIdentity;

  factory InstrumentIdentity.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw ContractFormatException(
          'Field "instrument": expected an instrument identity object');
    }
    return InstrumentIdentity(
      instrumentId: requireOpaqueId(value, 'instrument_id'),
      symbol: _boundedShort(value, 'symbol', 32),
      exchange: _boundedShort(value, 'exchange', 32),
      currency: requireIsoCurrency(value, 'currency'),
      providerSymbol: _boundedShort(value, 'provider_symbol', 80),
    );
  }
}

String _boundedShort(Map<String, dynamic> json, String field, int maxLength) {
  final value = json[field];
  if (value is! String || value.isEmpty || value.length > maxLength) {
    throw ContractFormatException(
        'Field "$field": expected a non-empty string of at most $maxLength');
  }
  return value;
}

/// One observed bar. `time` is the UTC start of the bucket; daily bars use
/// `session_date` as exchange-local identity. Null volume means unavailable,
/// zero volume means zero — the distinction is preserved exactly.
@Freezed(fromJson: false, toJson: false)
abstract class MarketBar with _$MarketBar {
  const factory MarketBar({
    required String time,
    required String sessionDate,
    required double open,
    required double high,
    required double low,
    required double close,
    required int? volume,
    required double? adjustedClose,
    required bool isFinal,
  }) = _MarketBar;

  factory MarketBar.fromJson(Map<String, dynamic> json) {
    final open = requirePositiveFiniteNumber(json, 'open');
    final high = requirePositiveFiniteNumber(json, 'high');
    final low = requirePositiveFiniteNumber(json, 'low');
    final close = requirePositiveFiniteNumber(json, 'close');
    if (low > (open <= close ? open : close) ||
        high < (open >= close ? open : close)) {
      throw ContractFormatException('Field "low"/"high": OHLC must satisfy '
          'low <= min(open, close) <= max(open, close) <= high');
    }

    final adjustedClose = json['adjusted_close'];
    if (adjustedClose != null &&
        (adjustedClose is! num ||
            !adjustedClose.isFinite ||
            adjustedClose <= 0)) {
      throw ContractFormatException(
          'Field "adjusted_close": expected a finite positive number or null');
    }

    final isFinal = json['is_final'];
    if (isFinal is! bool) {
      throw ContractFormatException('Field "is_final": expected a boolean');
    }

    return MarketBar(
      time: requireUtcTimestamp(json, 'time'),
      sessionDate: requireSessionDate(json, 'session_date'),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: optionalNonNegativeInteger(json, 'volume'),
      adjustedClose: adjustedClose?.toDouble(),
      isFinal: isFinal,
    );
  }
}

/// Machine-readable warning entry (`warnings` is an open array in the
/// contract; known shapes use a `code` and optional extra keys).
@freezed
abstract class MarketWarning with _$MarketWarning {
  const factory MarketWarning({
    required String code,
    required Map<String, dynamic> extra,
  }) = _MarketWarning;

  factory MarketWarning.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw ContractFormatException(
          'Field "warnings": expected object entries');
    }
    final code = value['code'];
    if (code is! String || code.isEmpty) {
      throw ContractFormatException(
          'Field "warnings.code": expected a machine-readable code');
    }
    final extra = Map<String, dynamic>.from(value)..remove('code');
    return MarketWarning(code: code, extra: extra);
  }
}

/// `HistoryResponse` for GET /market/instruments/:id/history. Unavailable
/// responses have an empty bar array and a machine-readable reason; stale
/// cached results stay explicitly stale and can never claim realtime.
@Freezed(fromJson: false, toJson: false)
abstract class HistoryResponse with _$HistoryResponse {
  const factory HistoryResponse({
    required int contractVersion,
    required InstrumentIdentity instrument,
    required String? snapshotId,
    required MarketRange range,
    required String requestedResolution,
    required String actualResolution,
    required String exchangeTimezone,
    required SessionMode sessionMode,
    required String adjustmentBasis,
    required String? asOf,
    required String fetchedAt,
    required DataStatus dataStatus,
    required DelayStatus delayStatus,
    required bool isStale,
    required List<MarketRange> availableRanges,
    required List<MarketBar> bars,
    required List<MarketWarning> warnings,
    required String? nextCursor,
    required String? unavailableReason,
  }) = _HistoryResponse;

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final contractVersion = json['contract_version'];
    if (contractVersion != horizonContractVersion) {
      throw ContractFormatException('Field "contract_version": expected '
          '$horizonContractVersion, got $contractVersion');
    }

    final dataStatus = DataStatus.parse(json['data_status']);
    final delayStatus = DelayStatus.parse(json['delay_status']);
    final isStale = requireBool(json, 'is_stale');
    final barsJson = json['bars'];
    if (barsJson is! List) {
      throw ContractFormatException('Field "bars": expected an array');
    }
    final bars =
        barsJson.map((entry) => MarketBar.fromJson(_objectOf(entry, 'bars')))
            .toList();

    if (barsJson.length > 5000) {
      throw ContractFormatException(
          'Field "bars": exceeded the maximum of 5000 bars');
    }

    final unavailableReason = optionalBoundedText(
      json,
      'unavailable_reason',
      maxLength: 500,
    );

    if (dataStatus == DataStatus.unavailable) {
      if (bars.isNotEmpty || unavailableReason == null) {
        throw ContractFormatException(
            'Field "unavailable_reason": unavailable history requires an '
            'empty result and a machine-readable reason');
      }
    }

    if (isStale && delayStatus == DelayStatus.realtime) {
      throw ContractFormatException('Field "delay_status": stale cache data '
          'cannot claim realtime delivery');
    }

    final rangesJson = json['available_ranges'];
    if (rangesJson is! List || rangesJson.length > 6) {
      throw ContractFormatException(
          'Field "available_ranges": expected an array of at most 6 ranges');
    }
    final availableRanges = rangesJson
        .map((entry) => MarketRange.parse(entry))
        .toList()
        .cast<MarketRange>();

    // Bars must be ascending in time and unique by session bucket
    // (session_date | time).
    final seenBuckets = <String>{};
    String? previousTime;
    for (final bar in bars) {
      final bucket = '${bar.sessionDate}|${bar.time}';
      if (!seenBuckets.add(bucket)) {
        throw ContractFormatException(
            'Field "bars": bars must be unique by session bucket');
      }
      if (previousTime != null && bar.time.compareTo(previousTime) <= 0) {
        throw ContractFormatException(
            'Field "bars": bars must be ascending by time');
      }
      previousTime = bar.time;
    }

    return HistoryResponse(
      contractVersion: contractVersion as int,
      instrument: InstrumentIdentity.fromJson(json['instrument']),
      snapshotId: optionalOpaqueId(json, 'snapshot_id'),
      range: MarketRange.parse(json['range']),
      requestedResolution: _resolution(json['requested_resolution'],
          'requested_resolution'),
      actualResolution:
          _resolution(json['actual_resolution'], 'actual_resolution'),
      exchangeTimezone: _boundedShort(json, 'exchange_timezone', 80),
      sessionMode: SessionMode.parse(json['session_mode']),
      adjustmentBasis: _boundedShort(json, 'adjustment_basis', 80),
      asOf: optionalUtcTimestamp(json, 'as_of'),
      fetchedAt: requireUtcTimestamp(json, 'fetched_at'),
      dataStatus: dataStatus,
      delayStatus: delayStatus,
      isStale: isStale,
      availableRanges: availableRanges,
      bars: bars,
      warnings: (json['warnings'] is List
              ? json['warnings'] as List
              : throw ContractFormatException(
                  'Field "warnings": expected an array'))
          .map((entry) => MarketWarning.fromJson(entry))
          .toList(),
      nextCursor: optionalBoundedText(json, 'next_cursor', maxLength: 500),
      unavailableReason: unavailableReason,
    );
  }
}

String _resolution(Object? value, String field) {
  if (value is! String || value.isEmpty || value.length > 20) {
    throw ContractFormatException(
        'Field "$field": expected a resolution of at most 20 characters');
  }
  return value;
}

Map<String, dynamic> _objectOf(Object? value, String field) {
  if (value is! Map<String, dynamic>) {
    throw ContractFormatException('Field "$field": expected object entries');
  }
  return value;
}
