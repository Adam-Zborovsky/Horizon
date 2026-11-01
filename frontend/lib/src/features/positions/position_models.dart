// H11 — typed position domain models for the contract-version-1 research API.
//
// Source of truth: docs/horizon/CONTRACTS.md §1–§2 and the executable backend
// schemas in backend/src/features/research/contracts.js. Parsing is strict and
// hand-written on purpose: responses are parsed with additive-field tolerance
// (unknown keys ignored, per CONTRACTS §1 forward-compatibility), while every
// known field is validated and no invalid value is silently repaired.
//
// This file also hosts the contract primitives shared by the H11 market and
// research model files (format regexes, bounded-text and timestamp checks).
// Generated files (position_models.freezed.dart) are produced only by
// build_runner on the development PC; they are never hand edited.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_models.freezed.dart';

/// Cross-lane contract version mirrored from backend contracts.js.
const int horizonContractVersion = 1;

const int maxTextLength = 4000;
const int maxDecimalLength = 40;
const int maxDecimalIntegerDigits = 24;
const int maxDecimalFractionDigits = 12;

final RegExp _isoDateRe = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final RegExp _isoCurrencyRe = RegExp(r'^[A-Z]{3}$');
final RegExp _decimalRe = RegExp(r'^(?:0|[1-9]\d*)(?:\.\d+)?$');
final RegExp _utcTimestampRe =
    RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$');

/// Raised when a payload violates the version-1 contract. Never repairs,
/// defaults or drops malformed known fields.
class ContractFormatException extends FormatException {
  ContractFormatException(super.message);
}

ContractFormatException _contractError(String field, String expectation) =>
    ContractFormatException('Field "$field": $expectation');

// ---------------------------------------------------------------------------
// Shared contract primitives (used by market_models.dart and
// research_models.dart through imports of this file).
// ---------------------------------------------------------------------------

bool isValidSessionDate(Object? value) {
  final parts = _isoDateParts(value);
  if (parts == null) return false;
  final (year, month, day) = parts;
  return day >= 1 && day <= _daysInMonth(year, month);
}

bool isValidUtcTimestamp(Object? value) {
  if (value is! String) return false;
  final match = _utcTimestampRe.firstMatch(value);
  if (match == null) return false;
  final datePart = value.substring(0, 10);
  final parts = _isoDateParts(datePart);
  if (parts == null) return false;
  final (year, month, day) = parts;
  if (day < 1 || day > _daysInMonth(year, month)) return false;
  final hour = int.parse(value.substring(11, 13));
  final minute = int.parse(value.substring(14, 16));
  final second = int.parse(value.substring(17, 19));
  return hour <= 23 && minute <= 59 && second <= 59;
}

int _daysInMonth(int year, int month) {
  const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month == 2 &&
      (year % 4 == 0 && year % 100 != 0 || year % 400 == 0)) {
    return 29;
  }
  return days[month - 1];
}

(int, int, int)? _isoDateParts(Object? value) {
  if (value is! String) return null;
  final match = _isoDateRe.firstMatch(value);
  if (match == null) return null;
  return (
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

bool isValidPositiveDecimal(Object? value) {
  if (value is! String) return false;
  if (!_decimalRe.hasMatch(value)) return false;
  final separator = value.indexOf('.');
  final integerPart = separator == -1 ? value : value.substring(0, separator);
  final fractionPart =
      separator == -1 ? '' : value.substring(separator + 1);
  if (value.length > maxDecimalLength ||
      integerPart.length > maxDecimalIntegerDigits ||
      fractionPart.length > maxDecimalFractionDigits) {
    return false;
  }
  return value.contains(RegExp(r'[1-9]'));
}

String requireSessionDate(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (!isValidSessionDate(value)) {
    throw _contractError(field, 'expected a real ISO date (YYYY-MM-DD)');
  }
  return value as String;
}

String? optionalSessionDate(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (!isValidSessionDate(value)) {
    throw _contractError(field, 'expected a real ISO date (YYYY-MM-DD)');
  }
  return value as String;
}

String requireUtcTimestamp(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (!isValidUtcTimestamp(value)) {
    throw _contractError(field, 'expected a real UTC ISO timestamp');
  }
  return value as String;
}

String? optionalUtcTimestamp(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (!isValidUtcTimestamp(value)) {
    throw _contractError(field, 'expected a real UTC ISO timestamp');
  }
  return value as String;
}

String requireIsoCurrency(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || !_isoCurrencyRe.hasMatch(value)) {
    throw _contractError(field, 'expected an ISO 4217 currency code');
  }
  return value;
}

/// Requires a finite, strictly positive JSON number. Zero is not a valid
/// missing-value substitute anywhere in this contract.
double requirePositiveFiniteNumber(
  Map<String, dynamic> json,
  String field,
) {
  final value = json[field];
  if (value is! num || !value.isFinite || value <= 0) {
    throw _contractError(field, 'expected a finite positive number');
  }
  return value.toDouble();
}

/// Requires a nonnegative JSON integer or explicit null. A fractional number
/// is rejected rather than truncated.
int? optionalNonNegativeInteger(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! int || value < 0) {
    throw _contractError(field, 'expected a nonnegative integer or null');
  }
  return value;
}

/// Requires a bounded non-empty string (CONTRACTS boundedText).
String requireBoundedText(Map<String, dynamic> json, String field,
    {int maxLength = maxTextLength}) {
  final value = json[field];
  if (value is! String || value.isEmpty || value.length > maxLength) {
    throw _contractError(
        field, 'expected a non-empty string of at most $maxLength characters');
  }
  return value;
}

/// Requires a bounded optional string; null/absent stays null.
///
/// H11 cross-lane empty-thesis repair (defensive normalization): an empty
/// string is treated as absent — returns null instead of throwing — so a
/// producer still emitting '' (e.g. a legacy stored row read through an
/// un-repaired producer) parses instead of raising ContractFormatException.
String? optionalBoundedText(Map<String, dynamic> json, String field,
    {int maxLength = maxTextLength}) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String || value.length > maxLength) {
    throw _contractError(
        field, 'expected a non-empty string of at most $maxLength characters');
  }
  if (value.isEmpty) return null;
  return value;
}

/// Requires an opaque identifier string (CONTRACTS opaqueId).
String requireOpaqueId(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.isEmpty || value.length > 160) {
    throw _contractError(field, 'expected an opaque identifier string');
  }
  return value;
}

String? optionalOpaqueId(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String || value.isEmpty || value.length > 160) {
    throw _contractError(field, 'expected an opaque identifier string');
  }
  return value;
}

List<String> requireBoundedStringList(
  Map<String, dynamic> json,
  String field, {
  int maxLength = maxTextLength,
  int maxItems = 50,
}) {
  final value = json[field];
  if (value is! List || value.length > maxItems) {
    throw _contractError(
        field, 'expected a list of at most $maxItems string entries');
  }
  return value.map((entry) {
    if (entry is! String || entry.isEmpty || entry.length > maxLength) {
      throw _contractError(
          field, 'expected non-empty string entries of at most $maxLength');
    }
    return entry;
  }).toList();
}

List<String>? optionalBoundedStringList(
  Map<String, dynamic> json,
  String field, {
  int maxLength = maxTextLength,
  int maxItems = 50,
}) {
  final value = json[field];
  if (value == null) return null;
  return requireBoundedStringList(json, field,
      maxLength: maxLength, maxItems: maxItems);
}

bool requireBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! bool) {
    throw _contractError(field, 'expected a boolean');
  }
  return value;
}

int requirePositiveInteger(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! int || value <= 0) {
    throw _contractError(field, 'expected a positive integer');
  }
  return value;
}

int? optionalPositiveInteger(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! int || value <= 0) {
    throw _contractError(field, 'expected a positive integer or null');
  }
  return value;
}

Map<String, dynamic>? optionalObject(
  Map<String, dynamic> json,
  String field,
) {
  final value = json[field];
  if (value == null) return null;
  if (value is! Map<String, dynamic>) {
    throw _contractError(field, 'expected an object');
  }
  return value;
}

List<Map<String, dynamic>> requireObjectList(
  Map<String, dynamic> json,
  String field, {
  required Map<String, dynamic>? Function(Object? entry) unwrap,
  int maxItems = 50,
}) {
  final value = json[field];
  if (value is! List || value.length > maxItems) {
    throw _contractError(field, 'expected a list of at most $maxItems entries');
  }
  return value.map((entry) {
    final unwrapped = unwrap(entry);
    if (unwrapped == null) {
      throw _contractError(field, 'expected object entries');
    }
    return unwrapped;
  }).toList();
}

// ---------------------------------------------------------------------------
// Position domain (CONTRACTS §2).
// ---------------------------------------------------------------------------

enum PositionState {
  candidate,
  owned,
  legacyUnclassified;

  String get wireValue => switch (this) {
        PositionState.candidate => 'candidate',
        PositionState.owned => 'owned',
        PositionState.legacyUnclassified => 'legacy_unclassified',
      };

  static PositionState parse(Object? value) => switch (value) {
        'candidate' => PositionState.candidate,
        'owned' => PositionState.owned,
        'legacy_unclassified' => PositionState.legacyUnclassified,
        _ => throw _contractError(
            'state', 'expected candidate, owned or legacy_unclassified'),
      };
}

/// Decimal-string money input: `{amount: decimal_string, currency: ISO}`.
/// Strictly positive; zero is never a valid cost.
@freezed
abstract class MoneyAmount with _$MoneyAmount {
  const factory MoneyAmount({
    required String amount,
    required String currency,
  }) = _MoneyAmount;

  factory MoneyAmount.fromJson(
    Object? value, {
    String field = 'money',
  }) {
    if (value is! Map<String, dynamic>) {
      throw _contractError('$field', 'expected a money object');
    }
    final amount = value['amount'];
    if (!isValidPositiveDecimal(amount)) {
      throw _contractError('$field.amount',
          'expected a bounded positive decimal string, never zero or negative');
    }
    final currency = value['currency'];
    if (currency is! String || !_isoCurrencyRe.hasMatch(currency)) {
      throw _contractError('$field.currency',
          'expected an ISO 4217 currency code');
    }
    return MoneyAmount(amount: amount as String, currency: currency);
  }
}

/// Contract serialization for money inputs (`{amount, currency}`).
extension MoneyAmountX on MoneyAmount {
  Map<String, dynamic> toContractJson() =>
      {'amount': amount, 'currency': currency};
}

/// User-declared risk constraints (CONTRACTS §2). Absent risk context means
/// unknown, never an AI-inferred profile.
@freezed
abstract class RiskContext with _$RiskContext {
  const factory RiskContext({
    required List<String> constraints,
    required String? portfolioContext,
    required String declaredAt,
    required String source,
  }) = _RiskContext;

  factory RiskContext.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw _contractError('risk_context', 'expected an object');
    }
    final constraints = requireBoundedStringList(value, 'constraints',
        maxItems: 20);
    if (constraints.isEmpty) {
      throw _contractError('risk_context.constraints',
          'expected at least one declared constraint');
    }
    final source = value['source'];
    if (source != 'user_declared') {
      throw _contractError('risk_context.source',
          "expected the literal 'user_declared'");
    }
    return RiskContext(
      constraints: constraints,
      portfolioContext: optionalBoundedText(value, 'portfolio_context'),
      declaredAt: requireUtcTimestamp(value, 'declared_at'),
      source: source as String,
    );
  }
}

/// Nested instrument identity object, mirroring the backend wire exactly:
/// position.service.js validateInstrument() normalizes to
/// `{instrument_id, symbol, exchange, currency, provider_symbol}` and
/// serialize() emits it as the position's `instrument` field. There is no
/// top-level `instrument_id` on a serialized position.
@freezed
abstract class PositionInstrument with _$PositionInstrument {
  const factory PositionInstrument({
    required String instrumentId,
    required String symbol,
    required String? exchange,
    required String? currency,
    required String? providerSymbol,
  }) = _PositionInstrument;

  factory PositionInstrument.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw _contractError(
          'instrument', 'expected an instrument identity object');
    }
    // Backend validateInstrument(): exchange/provider_symbol accept any
    // string or null (emptiness is not restricted); currency is an ISO 4217
    // code or null.
    String? optionalWireString(String field) {
      final v = value[field];
      if (v == null) return null;
      if (v is! String) throw _contractError('instrument.$field', 'expected a string or null');
      return v;
    }

    final currency = optionalWireString('currency');
    if (currency != null && !_isoCurrencyRe.hasMatch(currency)) {
      throw _contractError(
          'instrument.currency', 'expected an ISO 4217 currency code or null');
    }
    return PositionInstrument(
      instrumentId: requireOpaqueId(value, 'instrument_id'),
      symbol: requireBoundedText(value, 'symbol'),
      exchange: optionalWireString('exchange'),
      currency: currency,
      providerSymbol: optionalWireString('provider_symbol'),
    );
  }
}

/// Contract serialization for the instrument identity object
/// (the exact key set validateInstrument() accepts).
extension PositionInstrumentX on PositionInstrument {
  Map<String, dynamic> toContractJson() => {
        'instrument_id': instrumentId,
        'symbol': symbol,
        'exchange': exchange,
        'currency': currency,
        'provider_symbol': providerSymbol,
      };
}

/// Tracked position with typed nullable economics. Null economics means
/// unknown/unavailable and must never become an invented value.
@freezed
abstract class Position with _$Position {
  const factory Position({
    required String id,
    required PositionInstrument instrument,
    required PositionState state,
    required MoneyAmount? averageCost,
    required String? quantity,
    required String? openedOn,
    required int preferredHorizonMonths,
    required String? originalThesis,
    required List<String> reviewConditions,
    required RiskContext? riskContext,
    required bool archived,
    required int revision,
    required String createdAt,
    required String updatedAt,
  }) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) {
    final state = PositionState.parse(json['state']);
    final averageCostJson = json['average_cost'];
    final quantity = json['quantity'];
    final openedOn = optionalSessionDate(json, 'opened_on');

    if (state == PositionState.candidate) {
      for (final entry in {
        'average_cost': averageCostJson,
        'quantity': quantity,
        'opened_on': openedOn,
      }.entries) {
        if (entry.value != null) {
          throw _contractError(entry.key,
              'candidate records cannot carry executed economics or an opening date');
        }
      }
    }

    if (quantity != null && !isValidPositiveDecimal(quantity)) {
      throw _contractError('quantity',
          'expected a bounded positive decimal string, never zero or negative');
    }

    final preferredHorizon = json['preferred_horizon_months'] ?? 3;
    if (preferredHorizon is! int ||
        const {1, 2, 3}.contains(preferredHorizon) == false) {
      throw _contractError('preferred_horizon_months',
          'expected 1, 2 or 3 (default 3 when the user has not chosen)');
    }

    return Position(
      id: requireOpaqueId(json, 'id'),
      instrument: PositionInstrument.fromJson(json['instrument']),
      state: state,
      averageCost: averageCostJson == null
          ? null
          : MoneyAmount.fromJson(averageCostJson, field: 'average_cost'),
      quantity: quantity as String?,
      openedOn: openedOn,
      preferredHorizonMonths: preferredHorizon as int,
      originalThesis: optionalBoundedText(json, 'original_thesis'),
      reviewConditions: optionalBoundedStringList(
            json,
            'review_conditions',
            maxItems: 20,
          ) ??
          const <String>[],
      riskContext: optionalObject(json, 'risk_context') == null
          ? null
          : RiskContext.fromJson(json['risk_context']),
      archived: requireBool(json, 'archived'),
      revision: requirePositiveInteger(json, 'revision'),
      createdAt: requireUtcTimestamp(json, 'created_at'),
      updatedAt: requireUtcTimestamp(json, 'updated_at'),
    );
  }
}

/// Strict write payload for POST /positions and the `changes` object of
/// PATCH /positions/:id. Key names mirror backend ALLOWED_FIELDS
/// (position.service.js:23-27): the instrument travels as the nested
/// `instrument` object validateInstrument() requires — never a top-level
/// `instrument_id`. `expectedRevision` is PATCH metadata only: it is NOT part
/// of ALLOWED_FIELDS, so [toJson] (the create/changes body) never emits it;
/// the repository lifts it into the `{expected_revision, changes}` PATCH
/// envelope (position.routes.js:60). Server-derived owner identity is never
/// included — it comes from the JWT.
class PositionWrite {
  const PositionWrite({
    required this.instrument,
    required this.state,
    this.averageCost,
    this.quantity,
    this.openedOn,
    this.preferredHorizonMonths,
    this.originalThesis,
    this.reviewConditions,
    this.riskContext,
    this.archived,
    this.expectedRevision,
  });

  final PositionInstrument instrument;
  final PositionState state;
  final MoneyAmount? averageCost;
  final String? quantity;
  final String? openedOn;
  final int? preferredHorizonMonths;
  final String? originalThesis;
  final List<String>? reviewConditions;
  final RiskContext? riskContext;
  final bool? archived;
  final int? expectedRevision;

  Map<String, dynamic> toJson() {
    if (preferredHorizonMonths != null &&
        const {1, 2, 3}.contains(preferredHorizonMonths) == false) {
      throw ArgumentError.value(
          preferredHorizonMonths, 'preferredHorizonMonths', 'must be 1, 2 or 3');
    }
    if (state == PositionState.candidate &&
        (averageCost != null || quantity != null || openedOn != null)) {
      throw ArgumentError(
        'candidate records cannot carry executed economics or an opening date',
      );
    }
    return {
      'instrument': instrument.toContractJson(),
      'state': state.wireValue,
      if (averageCost != null) 'average_cost': averageCost!.toContractJson(),
      if (quantity != null) 'quantity': quantity,
      if (openedOn != null) 'opened_on': openedOn,
      if (preferredHorizonMonths != null)
        'preferred_horizon_months': preferredHorizonMonths,
      if (originalThesis != null) 'original_thesis': originalThesis,
      if (reviewConditions != null) 'review_conditions': reviewConditions,
      if (riskContext != null)
        'risk_context': {
          'constraints': riskContext!.constraints,
          'portfolio_context': riskContext!.portfolioContext,
          'declared_at': riskContext!.declaredAt,
          'source': riskContext!.source,
        },
      if (archived != null) 'archived': archived,
    };
  }
}
