// H11 — typed research domain models: evidence, claims, outlooks, projection
// overlays, checkpoints, run states and immutable assessments.
//
// Source of truth: docs/horizon/CONTRACTS.md §4–§8 and the executable backend
// schemas in backend/src/features/research/contracts.js. Parsing is strict and
// hand-written: known malformed fields are rejected, never repaired; unknown
// additive fields are ignored (forward-compatible). Cross-object invariants
// (outlook triple, calendar clamping, state/action compatibility, projection
// and checkpoint identity) mirror the backend superRefine rules.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../positions/position_models.dart';

part 'research_models.freezed.dart';

// ---------------------------------------------------------------------------
// Enums (CONTRACTS §4–§8).
// ---------------------------------------------------------------------------

enum EvidenceKind {
  filing,
  earningsRelease,
  transcript,
  companyIr,
  news,
  marketData,
  corporateAction,
  eventCalendar;

  String get wireValue => switch (this) {
        EvidenceKind.filing => 'filing',
        EvidenceKind.earningsRelease => 'earnings_release',
        EvidenceKind.transcript => 'transcript',
        EvidenceKind.companyIr => 'company_ir',
        EvidenceKind.news => 'news',
        EvidenceKind.marketData => 'market_data',
        EvidenceKind.corporateAction => 'corporate_action',
        EvidenceKind.eventCalendar => 'event_calendar',
      };

  static EvidenceKind parse(Object? value) => switch (value) {
        'filing' => EvidenceKind.filing,
        'earnings_release' => EvidenceKind.earningsRelease,
        'transcript' => EvidenceKind.transcript,
        'company_ir' => EvidenceKind.companyIr,
        'news' => EvidenceKind.news,
        'market_data' => EvidenceKind.marketData,
        'corporate_action' => EvidenceKind.corporateAction,
        'event_calendar' => EvidenceKind.eventCalendar,
        _ => throw ContractFormatException(
            'Field "kind": unknown evidence kind'),
      };
}

enum CoverageStatus {
  available,
  partial,
  unavailable,
  headlineOnly;

  String get wireValue => switch (this) {
        CoverageStatus.available => 'available',
        CoverageStatus.partial => 'partial',
        CoverageStatus.unavailable => 'unavailable',
        CoverageStatus.headlineOnly => 'headline_only',
      };

  static CoverageStatus parse(Object? value) => switch (value) {
        'available' => CoverageStatus.available,
        'partial' => CoverageStatus.partial,
        'unavailable' => CoverageStatus.unavailable,
        'headline_only' => CoverageStatus.headlineOnly,
        _ => throw ContractFormatException(
            'Field "coverage_status": unknown coverage status'),
      };
}

enum ClaimType {
  observed,
  interpretation,
  assumption;

  String get wireValue => switch (this) {
        ClaimType.observed => 'observed',
        ClaimType.interpretation => 'interpretation',
        ClaimType.assumption => 'assumption',
      };

  static ClaimType parse(Object? value) => switch (value) {
        'observed' => ClaimType.observed,
        'interpretation' => ClaimType.interpretation,
        'assumption' => ClaimType.assumption,
        _ => throw ContractFormatException(
            'Field "claim_type": expected observed, interpretation or assumption'),
      };
}

enum ProjectionKind {
  conditionalScenario,
  volatilityReference,
  calibratedForecast;

  String get wireValue => switch (this) {
        ProjectionKind.conditionalScenario => 'conditional_scenario',
        ProjectionKind.volatilityReference => 'volatility_reference',
        ProjectionKind.calibratedForecast => 'calibrated_forecast',
      };

  static ProjectionKind parse(Object? value) => switch (value) {
        'conditional_scenario' => ProjectionKind.conditionalScenario,
        'volatility_reference' => ProjectionKind.volatilityReference,
        'calibrated_forecast' => ProjectionKind.calibratedForecast,
        _ => throw ContractFormatException(
            'Field "kind": unknown projection kind'),
      };
}

enum OutlookDirection {
  positive,
  negative,
  mixed,
  insufficientEvidence;

  String get wireValue => switch (this) {
        OutlookDirection.positive => 'positive',
        OutlookDirection.negative => 'negative',
        OutlookDirection.mixed => 'mixed',
        OutlookDirection.insufficientEvidence => 'insufficient_evidence',
      };

  static OutlookDirection parse(Object? value) => switch (value) {
        'positive' => OutlookDirection.positive,
        'negative' => OutlookDirection.negative,
        'mixed' => OutlookDirection.mixed,
        'insufficient_evidence' => OutlookDirection.insufficientEvidence,
        _ => throw ContractFormatException(
            'Field "direction": unknown outlook direction'),
      };
}

enum RecommendationAction {
  buy,
  wait,
  avoid,
  hold,
  holdNoAdd,
  add,
  reduce,
  exit,
  insufficientEvidence;

  String get wireValue => switch (this) {
        RecommendationAction.buy => 'buy',
        RecommendationAction.wait => 'wait',
        RecommendationAction.avoid => 'avoid',
        RecommendationAction.hold => 'hold',
        RecommendationAction.holdNoAdd => 'hold_no_add',
        RecommendationAction.add => 'add',
        RecommendationAction.reduce => 'reduce',
        RecommendationAction.exit => 'exit',
        RecommendationAction.insufficientEvidence => 'insufficient_evidence',
      };

  static RecommendationAction parse(Object? value) => switch (value) {
        'buy' => RecommendationAction.buy,
        'wait' => RecommendationAction.wait,
        'avoid' => RecommendationAction.avoid,
        'hold' => RecommendationAction.hold,
        'hold_no_add' => RecommendationAction.holdNoAdd,
        'add' => RecommendationAction.add,
        'reduce' => RecommendationAction.reduce,
        'exit' => RecommendationAction.exit,
        'insufficient_evidence' => RecommendationAction.insufficientEvidence,
        _ => throw ContractFormatException(
            'Field "action": unknown recommendation action'),
      };
}

enum AssessmentStatus {
  complete,
  limited;

  String get wireValue => switch (this) {
        AssessmentStatus.complete => 'complete',
        AssessmentStatus.limited => 'limited',
      };

  static AssessmentStatus parse(Object? value) => switch (value) {
        'complete' => AssessmentStatus.complete,
        'limited' => AssessmentStatus.limited,
        _ => throw ContractFormatException(
            'Field "status": expected complete or limited'),
      };
}

enum RunKind {
  deepResearch,
  dailyUpdate,
  manualRefresh;

  String get wireValue => switch (this) {
        RunKind.deepResearch => 'deep_research',
        RunKind.dailyUpdate => 'daily_update',
        RunKind.manualRefresh => 'manual_refresh',
      };

  static RunKind parse(Object? value) => switch (value) {
        'deep_research' => RunKind.deepResearch,
        'daily_update' => RunKind.dailyUpdate,
        'manual_refresh' => RunKind.manualRefresh,
        _ => throw ContractFormatException('Field "run_kind": unknown run kind'),
      };
}

enum RunStatus {
  queued,
  running,
  succeeded,
  limited,
  failed,
  stalled,
  superseded;

  String get wireValue => switch (this) {
        RunStatus.queued => 'queued',
        RunStatus.running => 'running',
        RunStatus.succeeded => 'succeeded',
        RunStatus.limited => 'limited',
        RunStatus.failed => 'failed',
        RunStatus.stalled => 'stalled',
        RunStatus.superseded => 'superseded',
      };

  static RunStatus parse(Object? value) => switch (value) {
        'queued' => RunStatus.queued,
        'running' => RunStatus.running,
        'succeeded' => RunStatus.succeeded,
        'limited' => RunStatus.limited,
        'failed' => RunStatus.failed,
        'stalled' => RunStatus.stalled,
        'superseded' => RunStatus.superseded,
        _ => throw ContractFormatException('Field "status": unknown run status'),
      };
}

enum CheckpointKind {
  rollingIndicator,
  fixedObservedLevel,
  businessCondition;

  String get wireValue => switch (this) {
        CheckpointKind.rollingIndicator => 'rolling_indicator',
        CheckpointKind.fixedObservedLevel => 'fixed_observed_level',
        CheckpointKind.businessCondition => 'business_condition',
      };

  static CheckpointKind parse(Object? value) => switch (value) {
        'rolling_indicator' => CheckpointKind.rollingIndicator,
        'fixed_observed_level' => CheckpointKind.fixedObservedLevel,
        'business_condition' => CheckpointKind.businessCondition,
        _ => throw ContractFormatException(
            'Field "kind": unknown checkpoint kind'),
      };
}

enum CheckpointStatus {
  active,
  triggered,
  retired;

  String get wireValue => switch (this) {
        CheckpointStatus.active => 'active',
        CheckpointStatus.triggered => 'triggered',
        CheckpointStatus.retired => 'retired',
      };

  static CheckpointStatus parse(Object? value) => switch (value) {
        'active' => CheckpointStatus.active,
        'triggered' => CheckpointStatus.triggered,
        'retired' => CheckpointStatus.retired,
        _ => throw ContractFormatException(
            'Field "status": unknown checkpoint status'),
      };
}

enum ThesisChangeStatus {
  strengthened,
  weakened,
  unchanged,
  untested,
  corrected;

  String get wireValue => switch (this) {
        ThesisChangeStatus.strengthened => 'strengthened',
        ThesisChangeStatus.weakened => 'weakened',
        ThesisChangeStatus.unchanged => 'unchanged',
        ThesisChangeStatus.untested => 'untested',
        ThesisChangeStatus.corrected => 'corrected',
      };

  static ThesisChangeStatus parse(Object? value) => switch (value) {
        'strengthened' => ThesisChangeStatus.strengthened,
        'weakened' => ThesisChangeStatus.weakened,
        'unchanged' => ThesisChangeStatus.unchanged,
        'untested' => ThesisChangeStatus.untested,
        'corrected' => ThesisChangeStatus.corrected,
        _ => throw ContractFormatException(
            'Field "status": unknown thesis change status'),
      };
}

enum EconomicsStatus {
  available,
  partial,
  unavailable;

  String get wireValue => switch (this) {
        EconomicsStatus.available => 'available',
        EconomicsStatus.partial => 'partial',
        EconomicsStatus.unavailable => 'unavailable',
      };

  static EconomicsStatus parse(Object? value) => switch (value) {
        'available' => EconomicsStatus.available,
        'partial' => EconomicsStatus.partial,
        'unavailable' => EconomicsStatus.unavailable,
        _ => throw ContractFormatException(
            'Field "economics_status": expected available, partial or unavailable'),
      };
}

// ---------------------------------------------------------------------------
// Evidence and claims (CONTRACTS §4).
// ---------------------------------------------------------------------------

/// Reporting period: a business interval with unit/currency basis carried on
/// facts — never conflated with publication or retrieval time.
@freezed
abstract class ReportingPeriod with _$ReportingPeriod {
  const factory ReportingPeriod({
    required String? start,
    required String? end,
    required String? label,
  }) = _ReportingPeriod;

  factory ReportingPeriod.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw ContractFormatException(
          'Field "reporting_period": expected an object or null');
    }
    final start = optionalSessionDate(value, 'start');
    final end = optionalSessionDate(value, 'end');
    if (start != null && end != null && start.compareTo(end) > 0) {
      throw ContractFormatException('Field "reporting_period.end": reporting '
          'period end cannot precede start');
    }
    return ReportingPeriod(
      start: start,
      end: end,
      label: optionalBoundedText(value, 'label', maxLength: 160),
    );
  }
}

/// A fact extracted from evidence with unit, currency and basis.
@freezed
abstract class EvidenceFact with _$EvidenceFact {
  const factory EvidenceFact({
    required String id,
    required String label,
    required Object? value,
    required String? unit,
    required String? currency,
    required String? basis,
    required ReportingPeriod? reportingPeriod,
  }) = _EvidenceFact;

  factory EvidenceFact.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw ContractFormatException('Field "facts": expected object entries');
    }
    final value = raw['value'];
    final valueOk = (value is num && value.isFinite) ||
        (value is String && value.isNotEmpty && value.length <= maxTextLength);
    if (!valueOk) {
      throw ContractFormatException('Field "facts.value": expected a finite '
          'number or bounded text');
    }
    return EvidenceFact(
      id: requireOpaqueId(raw, 'id'),
      label: requireBoundedText(raw, 'label'),
      value: value,
      unit: optionalBoundedText(raw, 'unit', maxLength: 80),
      currency: raw['currency'] == null
          ? null
          : requireIsoCurrency(raw, 'currency'),
      basis: optionalBoundedText(raw, 'basis', maxLength: 160),
      reportingPeriod: raw['reporting_period'] == null
          ? null
          : ReportingPeriod.fromJson(raw['reporting_period']),
    );
  }
}

/// Source-linked evidence item. Headline-only news stays headline-only; URLs
/// are vetted source links, never arbitrary model-generated destinations.
@Freezed(fromJson: false, toJson: false)
abstract class EvidenceItem with _$EvidenceItem {
  const factory EvidenceItem({
    required String id,
    required String instrumentId,
    required EvidenceKind kind,
    required String title,
    required String sourceUrl,
    required String sourceName,
    required String? publishedAt,
    required String retrievedAt,
    required String? availableAt,
    required ReportingPeriod? reportingPeriod,
    required String? excerpt,
    required String? sourceLocator,
    required List<EvidenceFact> facts,
    required CoverageStatus coverageStatus,
  }) = _EvidenceItem;

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    final sourceUrl = json['source_url'];
    if (sourceUrl is! String || Uri.tryParse(sourceUrl) == null) {
      throw ContractFormatException(
          'Field "source_url": expected a valid URL');
    }
    return EvidenceItem(
      id: requireOpaqueId(json, 'id'),
      instrumentId: requireOpaqueId(json, 'instrument_id'),
      kind: EvidenceKind.parse(json['kind']),
      title: requireBoundedText(json, 'title'),
      sourceUrl: sourceUrl,
      sourceName: requireBoundedText(json, 'source_name'),
      publishedAt: optionalUtcTimestamp(json, 'published_at'),
      retrievedAt: requireUtcTimestamp(json, 'retrieved_at'),
      availableAt: optionalUtcTimestamp(json, 'available_at'),
      reportingPeriod: json['reporting_period'] == null
          ? null
          : ReportingPeriod.fromJson(json['reporting_period']),
      excerpt: optionalBoundedText(json, 'excerpt'),
      sourceLocator: optionalBoundedText(json, 'source_locator',
          maxLength: 1000),
      facts: requireObjectList(
        json,
        'facts',
        unwrap: (entry) => entry is Map<String, dynamic> ? entry : null,
        maxItems: 100,
      ).map((entry) => EvidenceFact.fromJson(entry)).toList(),
      coverageStatus: CoverageStatus.parse(json['coverage_status']),
    );
  }
}

/// A claim with explicit evidence and metric support; reference IDs must be
/// unique. Source-ID existence alone is not treated as entailment.
@Freezed(fromJson: false, toJson: false)
abstract class Claim with _$Claim {
  const factory Claim({
    required String text,
    required List<String> evidenceIds,
    required List<String> metricIds,
    required ClaimType claimType,
  }) = _Claim;

  factory Claim.fromJson(Map<String, dynamic> json) {
    final evidenceIds = _opaqueIdList(json, 'evidence_ids');
    final metricIds = _opaqueIdList(json, 'metric_ids');
    if (evidenceIds.toSet().length != evidenceIds.length ||
        metricIds.toSet().length != metricIds.length) {
      throw ContractFormatException('Field "evidence_ids"/"metric_ids": '
          'references must be unique');
    }
    return Claim(
      text: requireBoundedText(json, 'text'),
      evidenceIds: evidenceIds,
      metricIds: metricIds,
      claimType: ClaimType.parse(json['claim_type']),
    );
  }
}

List<String> _opaqueIdList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! List || value.length > 50) {
    throw ContractFormatException(
        'Field "$field": expected a list of at most 50 identifiers');
  }
  return value.map((entry) {
    if (entry is! String || entry.isEmpty || entry.length > 160) {
      throw ContractFormatException(
          'Field "$field": expected opaque identifier strings');
    }
    return entry;
  }).toList();
}

List<Claim> _claimList(Map<String, dynamic> json, String field,
    {int maxItems = 50}) {
  final value = json[field];
  if (value is! List || value.length > maxItems) {
    throw ContractFormatException(
        'Field "$field": expected a list of at most $maxItems claims');
  }
  return value.map((entry) {
    if (entry is! Map<String, dynamic>) {
      throw ContractFormatException('Field "$field": expected claim objects');
    }
    return Claim.fromJson(entry);
  }).toList();
}

// ---------------------------------------------------------------------------
// Thesis, recommendation and position context (CONTRACTS §5).
// ---------------------------------------------------------------------------

@freezed
abstract class ThesisSection with _$ThesisSection {
  const factory ThesisSection({
    required String summary,
    required List<Claim> claims,
  }) = _ThesisSection;

  factory ThesisSection.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw ContractFormatException(
          'Field "market_thesis": expected section objects');
    }
    return ThesisSection(
      summary: requireBoundedText(raw, 'summary'),
      claims: _claimList(raw, 'claims'),
    );
  }
}

@Freezed(fromJson: false, toJson: false)
abstract class MarketThesis with _$MarketThesis {
  const factory MarketThesis({
    required ThesisSection businessAssessment,
    required ThesisSection priceTechnicalAssessment,
    required ThesisSection valuationAssessment,
    required List<Claim> rationale,
    required List<Claim> counterevidence,
  }) = _MarketThesis;

  factory MarketThesis.fromJson(Map<String, dynamic> json) => MarketThesis(
        businessAssessment: ThesisSection.fromJson(json['business_assessment']),
        priceTechnicalAssessment:
            ThesisSection.fromJson(json['price_technical_assessment']),
        valuationAssessment:
            ThesisSection.fromJson(json['valuation_assessment']),
        rationale: _claimList(json, 'rationale'),
        counterevidence: _claimList(json, 'counterevidence'),
      );
}

@Freezed(fromJson: false, toJson: false)
abstract class Recommendation with _$Recommendation {
  const factory Recommendation({
    required RecommendationAction action,
    required int horizonMonths,
    required String headline,
    required List<Claim> rationale,
    required List<Claim> countercase,
    required List<Claim> invalidationConditions,
    required String evidenceQuality,
    required String predictiveUncertainty,
  }) = _Recommendation;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final horizonMonths = json['horizon_months'];
    if (horizonMonths is! int ||
        const {1, 2, 3}.contains(horizonMonths) == false) {
      throw ContractFormatException(
          'Field "horizon_months": expected 1, 2 or 3');
    }
    return Recommendation(
      action: RecommendationAction.parse(json['action']),
      horizonMonths: horizonMonths,
      headline: requireBoundedText(json, 'headline'),
      rationale: _claimList(json, 'rationale'),
      countercase: _claimList(json, 'countercase'),
      invalidationConditions: _claimList(json, 'invalidation_conditions'),
      evidenceQuality: requireBoundedText(json, 'evidence_quality'),
      predictiveUncertainty: requireBoundedText(json, 'predictive_uncertainty'),
    );
  }
}

/// Assessment position context: exact revision copy. Candidate records cannot
/// carry executed economics; legacy records keep null economics.
@Freezed(fromJson: false, toJson: false)
abstract class AssessmentPositionContext with _$AssessmentPositionContext {
  const factory AssessmentPositionContext({
    required String? positionId,
    required String instrumentId,
    required PositionState state,
    required int? revision,
    required MoneyAmount? averageCost,
    required String? quantity,
    required String? openedOn,
    required EconomicsStatus? economicsStatus,
  }) = _AssessmentPositionContext;

  factory AssessmentPositionContext.fromJson(Map<String, dynamic> json) {
    final state = PositionState.parse(json['state']);
    final averageCostJson = json['average_cost'];
    final quantity = json['quantity'];
    final openedOn = optionalSessionDate(json, 'opened_on');
    if (state == PositionState.candidate) {
      if (averageCostJson != null || quantity != null || openedOn != null) {
        throw ContractFormatException(
            'Field "position_context": candidate assessment context cannot '
            'carry executed economics or an opening date');
      }
    }
    if (quantity != null && !isValidPositiveDecimal(quantity)) {
      throw ContractFormatException(
          'Field "position_context.quantity": expected a bounded positive '
          'decimal string');
    }
    return AssessmentPositionContext(
      positionId: optionalOpaqueId(json, 'position_id'),
      instrumentId: requireOpaqueId(json, 'instrument_id'),
      state: state,
      revision: optionalPositiveInteger(json, 'revision'),
      averageCost: averageCostJson == null
          ? null
          : MoneyAmount.fromJson(averageCostJson, field: 'average_cost'),
      quantity: quantity as String?,
      openedOn: openedOn,
      economicsStatus: json['economics_status'] == null
          ? null
          : EconomicsStatus.parse(json['economics_status']),
    );
  }
}

// ---------------------------------------------------------------------------
// Outlooks and numeric projection overlays (CONTRACTS §5, §7).
// ---------------------------------------------------------------------------

/// Contract month arithmetic with month-end clamping (CONTRACTS §5).
/// Mirrors backend `calendarTargetDate`; rejects supported-year overflow
/// instead of emitting year 10000.
String calendarTargetDate(String sessionAsOf, int horizonMonths) {
  if (!isValidSessionDate(sessionAsOf)) {
    throw ArgumentError.value(sessionAsOf, 'sessionAsOf',
        'expected a valid ISO session date');
  }
  if (horizonMonths < 1 || horizonMonths > 3) {
    throw ArgumentError.value(
        horizonMonths, 'horizonMonths', 'expected 1, 2 or 3');
  }
  final year = int.parse(sessionAsOf.substring(0, 4));
  final month = int.parse(sessionAsOf.substring(5, 7));
  final day = int.parse(sessionAsOf.substring(8, 10));

  final targetMonthIndex = (month - 1) + horizonMonths;
  final targetYear = year + targetMonthIndex ~/ 12;
  final targetMonth = targetMonthIndex % 12 + 1;
  if (targetYear > 9999) {
    throw RangeError('Calendar target exceeds the supported year range');
  }
  const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var clampDay = daysInMonth[targetMonth - 1];
  if (targetMonth == 2 &&
      (targetYear % 4 == 0 && targetYear % 100 != 0 || targetYear % 400 == 0)) {
    clampDay = 29;
  }
  final targetDay = day < clampDay ? day : clampDay;
  return '${targetYear.toString().padLeft(4, '0')}-'
      '${targetMonth.toString().padLeft(2, '0')}-'
      '${targetDay.toString().padLeft(2, '0')}';
}

Map<String, dynamic>? _optionalObject(Object? value, String field) {
  if (value == null) return null;
  if (value is! Map<String, dynamic>) {
    throw ContractFormatException('Field "$field": expected an object or null');
  }
  return value;
}

/// Numeric projection overlay. Null bounds stay null; conditional scenarios
/// require explicit assumptions; calibrated forecasts require calibration
/// evidence; volatility references are never directional forecasts.
@Freezed(fromJson: false, toJson: false)
abstract class NumericProjection with _$NumericProjection {
  const factory NumericProjection({
    required String id,
    required String assessmentId,
    required String instrumentId,
    required String evidenceSnapshotId,
    required String anchorTime,
    required String anchorPriceMetricId,
    required String targetSessionDate,
    required ProjectionKind kind,
    required String method,
    required String methodVersion,
    required List<String> inputMetricIds,
    required List<String> assumptionIds,
    required double? lower,
    required double? central,
    required double? upper,
    required String currency,
    required String adjustmentBasis,
    required CalibrationEvidence? calibration,
    required String? validUntil,
    required List<String> limitations,
  }) = _NumericProjection;

  factory NumericProjection.fromJson(Map<String, dynamic> json) {
    final kind = ProjectionKind.parse(json['kind']);
    final id = requireOpaqueId(json, 'id');
    final instrumentId = requireOpaqueId(json, 'instrument_id');
    final assessmentId = requireOpaqueId(json, 'assessment_id');
    final evidenceSnapshotId = requireOpaqueId(json, 'evidence_snapshot_id');
    final targetSessionDate = requireSessionDate(json, 'target_session_date');
    final anchorTime = requireUtcTimestamp(json, 'anchor_time');

    double? bound(String field) {
      final value = json[field];
      if (value == null) return null;
      if (value is! num || !value.isFinite || value <= 0) {
        throw ContractFormatException(
            'Field "$field": expected a finite positive number or null');
      }
      return value.toDouble();
    }

    final lower = bound('lower');
    final central = bound('central');
    final upper = bound('upper');
    if (lower == null && central == null && upper == null) {
      throw ContractFormatException('Field "lower": at least one projection '
          'bound is required');
    }
    if (lower != null && central != null && lower > central) {
      throw ContractFormatException(
          'Field "lower": lower cannot exceed central');
    }
    if (central != null && upper != null && central > upper) {
      throw ContractFormatException(
          'Field "central": central cannot exceed upper');
    }
    if (lower != null && upper != null && lower > upper) {
      throw ContractFormatException('Field "lower": lower cannot exceed upper');
    }

    final assumptionIds = _opaqueIdList(json, 'assumption_ids');
    if (kind == ProjectionKind.conditionalScenario && assumptionIds.isEmpty) {
      throw ContractFormatException('Field "assumption_ids": conditional '
          'scenarios require explicit assumptions');
    }

    final calibration = _optionalObject(json['calibration'], 'calibration');
    if (kind == ProjectionKind.calibratedForecast && calibration == null) {
      throw ContractFormatException('Field "calibration": calibrated forecasts '
          'require calibration evidence');
    }

    final validUntil = optionalUtcTimestamp(json, 'valid_until');
    if (validUntil != null && validUntil.compareTo(anchorTime) < 0) {
      throw ContractFormatException('Field "valid_until": projection validity '
          'cannot end before its anchor');
    }

    return NumericProjection(
      id: id,
      assessmentId: assessmentId,
      instrumentId: instrumentId,
      evidenceSnapshotId: evidenceSnapshotId,
      anchorTime: anchorTime,
      anchorPriceMetricId: requireOpaqueId(json, 'anchor_price_metric_id'),
      targetSessionDate: targetSessionDate,
      kind: kind,
      method: requireBoundedText(json, 'method'),
      methodVersion: requireBoundedText(json, 'method_version'),
      inputMetricIds: _opaqueIdList(json, 'input_metric_ids'),
      assumptionIds: assumptionIds,
      lower: lower,
      central: central,
      upper: upper,
      currency: requireIsoCurrency(json, 'currency'),
      adjustmentBasis: _bounded(json, 'adjustment_basis', 80),
      calibration: calibration == null
          ? null
          : CalibrationEvidence.fromJson(calibration),
      validUntil: validUntil,
      limitations: requireBoundedStringList(json, 'limitations', maxItems: 50),
    );
  }
}

String _bounded(Map<String, dynamic> json, String field, int maxLength) {
  final value = json[field];
  if (value is! String || value.isEmpty || value.length > maxLength) {
    throw ContractFormatException(
        'Field "$field": expected a non-empty string of at most $maxLength');
  }
  return value;
}

@Freezed(fromJson: false, toJson: false)
abstract class CalibrationEvidence with _$CalibrationEvidence {
  const factory CalibrationEvidence({
    required String modelVersion,
    required String heldOutEvaluation,
    required String coverageDefinition,
    required List<String> validationEvidenceIds,
  }) = _CalibrationEvidence;

  factory CalibrationEvidence.fromJson(Map<String, dynamic> json) {
    final validationEvidenceIds = _opaqueIdList(
      json,
      'validation_evidence_ids',
    );
    if (validationEvidenceIds.isEmpty) {
      throw ContractFormatException('Field "validation_evidence_ids": '
          'calibration evidence requires at least one validation reference');
    }
    return CalibrationEvidence(
      modelVersion: requireBoundedText(json, 'model_version'),
      heldOutEvaluation: requireBoundedText(json, 'held_out_evaluation'),
      coverageDefinition: requireBoundedText(json, 'coverage_definition'),
      validationEvidenceIds: validationEvidenceIds,
    );
  }
}

@Freezed(fromJson: false, toJson: false)
abstract class Outlook with _$Outlook {
  const factory Outlook({
    required int horizonMonths,
    required String calendarTargetDate,
    required String evaluationSessionDate,
    required OutlookDirection direction,
    required List<Claim> baseCase,
    required List<Claim> upsideCase,
    required List<Claim> downsideCase,
    required List<Claim> catalysts,
    required List<Claim> invalidators,
    required NumericProjection? numericProjection,
    required List<String> dataLimitations,
  }) = _Outlook;

  factory Outlook.fromJson(Map<String, dynamic> json) {
    final horizonMonths = json['horizon_months'];
    if (horizonMonths is! int ||
        const {1, 2, 3}.contains(horizonMonths) == false) {
      throw ContractFormatException(
          'Field "horizon_months": expected 1, 2 or 3');
    }
    final calendarTarget = requireSessionDate(json, 'calendar_target_date');
    final evaluationSession =
        requireSessionDate(json, 'evaluation_session_date');
    return Outlook(
      horizonMonths: horizonMonths,
      calendarTargetDate: calendarTarget,
      evaluationSessionDate: evaluationSession,
      direction: OutlookDirection.parse(json['direction']),
      baseCase: _claimList(json, 'base_case', maxItems: 20),
      upsideCase: _claimList(json, 'upside_case', maxItems: 20),
      downsideCase: _claimList(json, 'downside_case', maxItems: 20),
      catalysts: _claimList(json, 'catalysts', maxItems: 20),
      invalidators: _claimList(json, 'invalidators', maxItems: 20),
      numericProjection:
          _optionalObject(json['numeric_projection'], 'numeric_projection') ==
                  null
              ? null
              : NumericProjection.fromJson(_optionalObject(
                  json['numeric_projection'], 'numeric_projection')!),
      dataLimitations:
          requireBoundedStringList(json, 'data_limitations', maxItems: 50),
    );
  }
}

// ---------------------------------------------------------------------------
// Checkpoints and thesis continuity (CONTRACTS §6).
// ---------------------------------------------------------------------------

@Freezed(fromJson: false, toJson: false)
abstract class Checkpoint with _$Checkpoint {
  const factory Checkpoint({
    required String id,
    required String instrumentId,
    required CheckpointKind kind,
    required String? metricId,
    required double? fixedLevel,
    required String condition,
    required String createdAt,
    required String updatedAt,
    required CheckpointStatus status,
    required String reason,
    required String sourceAssessmentId,
  }) = _Checkpoint;

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    final kind = CheckpointKind.parse(json['kind']);
    final metricId = optionalOpaqueId(json, 'metric_id');
    final fixedLevel = json['fixed_level'];
    double? parsedFixedLevel;
    if (fixedLevel != null) {
      if (fixedLevel is! num || !fixedLevel.isFinite || fixedLevel <= 0) {
        throw ContractFormatException('Field "fixed_level": expected a finite '
            'positive number or null');
      }
      parsedFixedLevel = fixedLevel.toDouble();
    }

    switch (kind) {
      case CheckpointKind.rollingIndicator:
        if (metricId == null) {
          throw ContractFormatException('Field "metric_id": rolling checkpoints '
              'require a metric reference');
        }
        if (parsedFixedLevel != null) {
          throw ContractFormatException('Field "fixed_level": rolling '
              'checkpoints cannot carry a fixed observed level');
        }
        break;
      case CheckpointKind.fixedObservedLevel:
        if (parsedFixedLevel == null) {
          throw ContractFormatException('Field "fixed_level": fixed-level '
              'checkpoints require a positive observed level');
        }
        if (metricId != null) {
          throw ContractFormatException('Field "metric_id": fixed-level '
              'checkpoints cannot carry a metric reference');
        }
        break;
      case CheckpointKind.businessCondition:
        if (metricId != null || parsedFixedLevel != null) {
          throw ContractFormatException('Field "kind": business-condition '
              'checkpoints cannot carry a metric reference or fixed level');
        }
        break;
    }

    final createdAt = requireUtcTimestamp(json, 'created_at');
    final updatedAt = requireUtcTimestamp(json, 'updated_at');
    if (updatedAt.compareTo(createdAt) < 0) {
      throw ContractFormatException('Field "updated_at": checkpoint update '
          'cannot precede creation');
    }

    return Checkpoint(
      id: requireOpaqueId(json, 'id'),
      instrumentId: requireOpaqueId(json, 'instrument_id'),
      kind: kind,
      metricId: metricId,
      fixedLevel: parsedFixedLevel,
      condition: requireBoundedText(json, 'condition'),
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: CheckpointStatus.parse(json['status']),
      reason: requireBoundedText(json, 'reason'),
      sourceAssessmentId: requireOpaqueId(json, 'source_assessment_id'),
    );
  }
}

@Freezed(fromJson: false, toJson: false)
abstract class ThesisChange with _$ThesisChange {
  const factory ThesisChange({
    required String component,
    required ThesisChangeStatus status,
    required String reason,
    required List<String> evidenceIds,
  }) = _ThesisChange;

  factory ThesisChange.fromJson(Map<String, dynamic> json) => ThesisChange(
        component: requireBoundedText(json, 'component'),
        status: ThesisChangeStatus.parse(json['status']),
        reason: requireBoundedText(json, 'reason'),
        evidenceIds: _opaqueIdList(json, 'evidence_ids'),
      );
}

@Freezed(fromJson: false, toJson: false)
abstract class ChangesSincePrevious with _$ChangesSincePrevious {
  const factory ChangesSincePrevious({
    required String? previousAssessmentId,
    required String? previousSessionAsOf,
    required List<String> missingReportSessions,
    required List<ThesisChange> thesisChanges,
    required List<String> checkpointChangeIds,
  }) = _ChangesSincePrevious;

  factory ChangesSincePrevious.fromJson(Map<String, dynamic> json) =>
      ChangesSincePrevious(
        previousAssessmentId: optionalOpaqueId(json, 'previous_assessment_id'),
        previousSessionAsOf:
            optionalSessionDate(json, 'previous_session_as_of'),
        missingReportSessions: requireSessionDateList(
          json,
          'missing_report_sessions',
          maxItems: 100,
        ),
        thesisChanges: _objectList(json, 'thesis_changes', maxItems: 100)
            .map((entry) => ThesisChange.fromJson(entry))
            .toList(),
        checkpointChangeIds:
            requireOpaqueIdList(json, 'checkpoint_change_ids', maxItems: 100),
      );
}

List<String> requireSessionDateList(
  Map<String, dynamic> json,
  String field, {
  int maxItems = 100,
}) {
  final value = json[field];
  if (value is! List || value.length > maxItems) {
    throw ContractFormatException(
        'Field "$field": expected a list of at most $maxItems session dates');
  }
  return value.map((entry) {
    if (!isValidSessionDate(entry)) {
      throw ContractFormatException(
          'Field "$field": expected ISO session dates');
    }
    return entry as String;
  }).toList();
}

List<String> requireOpaqueIdList(
  Map<String, dynamic> json,
  String field, {
  int maxItems = 100,
}) {
  final value = json[field];
  if (value is! List || value.length > maxItems) {
    throw ContractFormatException(
        'Field "$field": expected a list of at most $maxItems identifiers');
  }
  return value.map((entry) {
    if (entry is! String || entry.isEmpty || entry.length > 160) {
      throw ContractFormatException(
          'Field "$field": expected opaque identifier strings');
    }
    return entry;
  }).toList();
}

List<Map<String, dynamic>> _objectList(
  Map<String, dynamic> json,
  String field, {
  int maxItems = 100,
}) {
  final value = json[field];
  if (value is! List || value.length > maxItems) {
    throw ContractFormatException(
        'Field "$field": expected a list of at most $maxItems objects');
  }
  return value.map((entry) {
    if (entry is! Map<String, dynamic>) {
      throw ContractFormatException(
          'Field "$field": expected object entries');
    }
    return entry;
  }).toList();
}

// ---------------------------------------------------------------------------
// Immutable assessment (CONTRACTS §5–§7).
// ---------------------------------------------------------------------------

@Freezed(fromJson: false, toJson: false)
abstract class ResearchAssessment with _$ResearchAssessment {
  const factory ResearchAssessment({
    required String id,
    required int contractVersion,
    required String? positionId,
    required int? positionRevision,
    required String instrumentId,
    required String runId,
    required String evidenceSnapshotId,
    required String generatedAt,
    required String sessionAsOf,
    required AssessmentStatus status,
    required MarketThesis marketThesis,
    required Recommendation recommendation,
    required AssessmentPositionContext positionContext,
    required ChangesSincePrevious? changesSincePrevious,
    required List<Checkpoint> checkpoints,
    required List<Outlook> outlooks,
    required List<String> missingData,
    required String? nextReview,
    required Map<String, String> versions,
  }) = _ResearchAssessment;

  factory ResearchAssessment.fromJson(Map<String, dynamic> json) {
    final contractVersion = json['contract_version'];
    if (contractVersion != horizonContractVersion) {
      throw ContractFormatException('Field "contract_version": expected '
          '$horizonContractVersion, got $contractVersion');
    }

    final positionContext =
        _optionalObject(json['position_context'], 'position_context') == null
            ? throw ContractFormatException(
                'Field "position_context": expected an object')
            : AssessmentPositionContext.fromJson(
                _optionalObject(json['position_context'], 'position_context')!);

    final outlooksJson = json['outlooks'];
    if (outlooksJson is! List) {
      throw ContractFormatException('Field "outlooks": expected an array');
    }
    final outlooks = outlooksJson
        .map((entry) => entry is Map<String, dynamic>
            ? Outlook.fromJson(entry)
            : throw ContractFormatException(
                'Field "outlooks": expected outlook objects'))
        .toList();

    // Exactly one 1, 2 and 3 month outlook (CONTRACTS §5).
    final horizons = outlooks.map((o) => o.horizonMonths).toList()..sort();
    if (outlooks.length != 3 ||
        horizons[0] != 1 ||
        horizons[1] != 2 ||
        horizons[2] != 3) {
      throw ContractFormatException('Field "outlooks": exactly one 1, 2 and 3 '
          'month outlook is required');
    }

    final sessionAsOf = requireSessionDate(json, 'session_as_of');
    for (final outlook in outlooks) {
      // Calendar month arithmetic with contract month-end clamping.
      final expectedTarget = calendarTargetDate(sessionAsOf,
          outlook.horizonMonths);
      if (outlook.calendarTargetDate != expectedTarget) {
        throw ContractFormatException('Field "outlooks": outlook target must '
            'use contract month-end clamping');
      }
      if (outlook.evaluationSessionDate.compareTo(sessionAsOf) < 0) {
        throw ContractFormatException('Field "outlooks": evaluation session '
            'cannot predate the assessment session');
      }
      if (outlook.evaluationSessionDate
          .compareTo(outlook.calendarTargetDate) > 0) {
        throw ContractFormatException('Field "outlooks": evaluation session '
            'cannot be after its calendar target');
      }
      final projection = outlook.numericProjection;
      if (projection != null) {
        if (projection.assessmentId != json['id'] ||
            projection.instrumentId != json['instrument_id'] ||
            projection.evidenceSnapshotId != json['evidence_snapshot_id'] ||
            projection.targetSessionDate != outlook.evaluationSessionDate) {
          throw ContractFormatException('Field "outlooks": projection identity '
              'must match its assessment, snapshot, instrument and evaluation '
              'session');
        }
      }
    }

    // State-compatible recommendation actions (CONTRACTS §5).
    final allowedActions = switch (positionContext.state) {
      PositionState.candidate => const {
          RecommendationAction.buy,
          RecommendationAction.wait,
          RecommendationAction.avoid,
          RecommendationAction.insufficientEvidence,
        },
      PositionState.owned => const {
          RecommendationAction.hold,
          RecommendationAction.holdNoAdd,
          RecommendationAction.add,
          RecommendationAction.reduce,
          RecommendationAction.exit,
          RecommendationAction.insufficientEvidence,
        },
      PositionState.legacyUnclassified => const {
          RecommendationAction.insufficientEvidence,
        },
    };
    final recommendation = Recommendation.fromJson(
      _requiredObject(json, 'recommendation'),
    );
    if (!allowedActions.contains(recommendation.action)) {
      throw ContractFormatException('Field "recommendation.action": action is '
          'incompatible with the position state');
    }

    // Position context identity must match the assessment.
    if (positionContext.positionId != json['position_id'] ||
        positionContext.instrumentId != json['instrument_id'] ||
        positionContext.revision != json['position_revision']) {
      throw ContractFormatException('Field "position_context": position '
          'context must match the assessment identity and revision');
    }

    final positionId = optionalOpaqueId(json, 'position_id');
    final positionRevision = optionalPositiveInteger(json, 'position_revision');
    if (positionContext.state == PositionState.legacyUnclassified &&
        positionId != null &&
        positionRevision == null) {
      throw ContractFormatException('Field "position_revision": '
          'position-specific assessments require a revision');
    }

    final checkpointsJson = json['checkpoints'];
    if (checkpointsJson is! List || checkpointsJson.length > 100) {
      throw ContractFormatException(
          'Field "checkpoints": expected an array of at most 100 entries');
    }
    final checkpoints = checkpointsJson.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw ContractFormatException(
            'Field "checkpoints": expected checkpoint objects');
      }
      final checkpoint = Checkpoint.fromJson(entry);
      if (checkpoint.instrumentId != json['instrument_id'] ||
          checkpoint.sourceAssessmentId != json['id']) {
        throw ContractFormatException('Field "checkpoints": checkpoint '
            'identity must match its assessment and instrument');
      }
      return checkpoint;
    }).toList();

    return ResearchAssessment(
      id: requireOpaqueId(json, 'id'),
      contractVersion: contractVersion as int,
      positionId: positionId,
      positionRevision: positionRevision,
      instrumentId: requireOpaqueId(json, 'instrument_id'),
      runId: requireOpaqueId(json, 'run_id'),
      evidenceSnapshotId: requireOpaqueId(json, 'evidence_snapshot_id'),
      generatedAt: requireUtcTimestamp(json, 'generated_at'),
      sessionAsOf: sessionAsOf,
      status: AssessmentStatus.parse(json['status']),
      marketThesis: MarketThesis.fromJson(_requiredObject(json, 'market_thesis')),
      recommendation: recommendation,
      positionContext: positionContext,
      changesSincePrevious: _optionalObject(
                  json['changes_since_previous'], 'changes_since_previous') ==
              null
          ? null
          : ChangesSincePrevious.fromJson(_optionalObject(
              json['changes_since_previous'], 'changes_since_previous')!),
      checkpoints: checkpoints,
      outlooks: outlooks,
      missingData: requireBoundedStringList(json, 'missing_data', maxItems: 100),
      nextReview: optionalUtcTimestamp(json, 'next_review'),
      versions: _versions(json['versions']),
    );
  }
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! Map<String, dynamic>) {
    throw ContractFormatException('Field "$field": expected an object');
  }
  return value;
}

Map<String, String> _versions(Object? value) {
  if (value is! Map || value.isEmpty || value.length > 20) {
    throw ContractFormatException('Field "versions": expected a map of at '
        'most 20 version entries');
  }
  return value.map((key, entry) {
    if (key is! String ||
        key.length > 80 ||
        entry is! String ||
        entry.isEmpty ||
        entry.length > maxTextLength) {
      throw ContractFormatException(
          'Field "versions": expected bounded string entries');
    }
    return MapEntry(key, entry);
  });
}

// ---------------------------------------------------------------------------
// Run lifecycle (CONTRACTS §8).
// ---------------------------------------------------------------------------

@Freezed(fromJson: false, toJson: false)
abstract class ResearchRun with _$ResearchRun {
  const factory ResearchRun({
    required String id,
    required String positionId,
    required String ownerIdInternal,
    required int positionRevision,
    required RunKind runKind,
    required String idempotencyKey,
    required RunStatus status,
    required String stage,
    required String createdAt,
    required String? startedAt,
    required String? heartbeatAt,
    required String deadlineAt,
    required String? finishedAt,
    required String? evidenceSnapshotId,
    required String? assessmentId,
    required String? errorCode,
    required int retryCount,
    required Map<String, String> versions,
  }) = _ResearchRun;

  factory ResearchRun.fromJson(Map<String, dynamic> json) {
    final id = requireOpaqueId(json, 'id');
    final positionId = requireOpaqueId(json, 'position_id');
    final ownerIdInternal = requireOpaqueId(json, 'owner_id_internal');
    final positionRevision = requirePositiveInteger(json, 'position_revision');
    final runKind = RunKind.parse(json['run_kind']);
    final idempotencyKey = _bounded(json, 'idempotency_key', 255);
    final status = RunStatus.parse(json['status']);
    final stage = _bounded(json, 'stage', 80);
    final createdAt = requireUtcTimestamp(json, 'created_at');
    final startedAt = optionalUtcTimestamp(json, 'started_at');
    final heartbeatAt = optionalUtcTimestamp(json, 'heartbeat_at');
    final deadlineAt = requireUtcTimestamp(json, 'deadline_at');
    final finishedAt = optionalUtcTimestamp(json, 'finished_at');
    final evidenceSnapshotId = optionalOpaqueId(json, 'evidence_snapshot_id');
    final assessmentId = optionalOpaqueId(json, 'assessment_id');
    final errorCode = optionalBoundedText(json, 'error_code', maxLength: 120);
    final retryCount = json['retry_count'];

    if (retryCount is! int || retryCount < 0 || retryCount > 2) {
      throw ContractFormatException('Field "retry_count": expected an integer '
          'between 0 and 2');
    }

    void require(bool condition, String message) {
      if (!condition) {
        throw ContractFormatException('Field "status"/"run": $message');
      }
    }

    require(deadlineAt.compareTo(createdAt) >= 0,
        'run deadline cannot precede creation');
    if (startedAt != null) {
      require(startedAt.compareTo(createdAt) >= 0,
          'run start cannot precede creation');
    }
    if (heartbeatAt != null) {
      require(startedAt != null && heartbeatAt.compareTo(startedAt) >= 0,
          'heartbeat requires a started run and cannot precede its start');
    }
    if (finishedAt != null) {
      require(startedAt != null && finishedAt.compareTo(startedAt) >= 0,
          'finished runs must have started and cannot finish before start');
    }
    if (heartbeatAt != null && finishedAt != null) {
      require(heartbeatAt.compareTo(finishedAt) <= 0,
          'heartbeat cannot be after run completion');
    }

    final terminalStatuses = {
      RunStatus.succeeded,
      RunStatus.limited,
      RunStatus.failed,
      RunStatus.stalled,
      RunStatus.superseded,
    };

    if (status == RunStatus.queued) {
      require(
          startedAt == null &&
              heartbeatAt == null &&
              finishedAt == null &&
              evidenceSnapshotId == null &&
              assessmentId == null &&
              errorCode == null,
          'queued runs cannot contain active, result or error state');
    }
    if (status == RunStatus.running) {
      require(startedAt != null && finishedAt == null && assessmentId == null,
          'running runs require a start and cannot contain terminal result or '
          'error state');
    }
    if (terminalStatuses.contains(status)) {
      require(finishedAt != null, 'terminal runs require a completion '
          'timestamp');
    }
    if (status == RunStatus.succeeded || status == RunStatus.limited) {
      require(assessmentId != null && evidenceSnapshotId != null,
          'successful or limited runs require a snapshot and assessment');
      require(errorCode == null,
          'successful or limited runs cannot carry an error code');
      if (finishedAt != null) {
        require(finishedAt.compareTo(deadlineAt) <= 0,
            'successful or limited runs cannot complete after their deadline');
      }
    }
    if (status == RunStatus.failed || status == RunStatus.stalled) {
      require(startedAt != null && assessmentId == null && errorCode != null,
          'failed or stalled runs require start, terminal error and no '
          'assessment');
    }
    if (status == RunStatus.stalled && finishedAt != null) {
      require(finishedAt.compareTo(deadlineAt) >= 0,
          'stalled runs cannot finish before their deadline');
    }
    if (status == RunStatus.superseded) {
      require(assessmentId == null && errorCode == null,
          'superseded runs cannot publish an assessment or terminal error');
    }

    return ResearchRun(
      id: id,
      positionId: positionId,
      ownerIdInternal: ownerIdInternal,
      positionRevision: positionRevision,
      runKind: runKind,
      idempotencyKey: idempotencyKey,
      status: status,
      stage: stage,
      createdAt: createdAt,
      startedAt: startedAt,
      heartbeatAt: heartbeatAt,
      deadlineAt: deadlineAt,
      finishedAt: finishedAt,
      evidenceSnapshotId: evidenceSnapshotId,
      assessmentId: assessmentId,
      errorCode: errorCode,
      retryCount: retryCount as int,
      versions: _versions(json['versions']),
    );
  }
}

// ---------------------------------------------------------------------------
// Authenticated response envelopes (CONTRACTS §9).
// ---------------------------------------------------------------------------

/// GET /research/positions/:id/latest — the real backend wire
/// (backend/src/features/research/research.routes.js:67-74) is a TOP-LEVEL
/// object: `position_id`, a nullable `latest_assessment` (public assessment
/// view), and a `run_state` object carrying two SEPARATE projections —
/// `last_success` (research.service.js:816-822) and `latest_attempt`
/// (research.service.js:823-831). Those entries are partial run projections,
/// NOT full run views: they lack owner_id_internal, position_revision,
/// idempotency_key, created_at, deadline_at and retry_count, so
/// ResearchRun.fromJson cannot parse them. last_success and latest_attempt
/// are distinct concepts and are never collapsed: an existing success is not
/// rewritten by a later failure (research.service.js:811-812).
@Freezed(fromJson: false, toJson: false)
abstract class ResearchLatest with _$ResearchLatest {
  const factory ResearchLatest({
    required String positionId,
    required ResearchAssessment? latestAssessment,
    required ResearchLastSuccess? lastSuccess,
    required ResearchLatestAttempt? latestAttempt,
  }) = _ResearchLatest;

  factory ResearchLatest.fromJson(Map<String, dynamic> json) {
    final positionId = requireOpaqueId(json, 'position_id');
    final latestAssessment =
        _optionalObject(json['latest_assessment'], 'latest_assessment');
    final runStateJson = json['run_state'];
    if (runStateJson is! Map<String, dynamic>) {
      throw ContractFormatException('Field "run_state": expected an object');
    }
    return ResearchLatest(
      positionId: positionId,
      latestAssessment: latestAssessment == null
          ? null
          : ResearchAssessment.fromJson(
              latestAssessment['assessment'] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(
                      latestAssessment['assessment'] as Map)
                  : latestAssessment),
      lastSuccess: runStateJson['last_success'] == null
          ? null
          : ResearchLastSuccess.fromJson(_optionalObject(
              runStateJson['last_success'], 'run_state.last_success')!),
      latestAttempt: runStateJson['latest_attempt'] == null
          ? null
          : ResearchLatestAttempt.fromJson(_optionalObject(
              runStateJson['latest_attempt'], 'run_state.latest_attempt')!),
    );
  }
}

/// run_state.last_success (research.service.js:816-822): projection of the
/// most recent SUCCESSFUL run for the position. Nullable fields mirror the
/// backend projection, which copies whatever the run document carries.
@Freezed(fromJson: false, toJson: false)
abstract class ResearchLastSuccess with _$ResearchLastSuccess {
  const factory ResearchLastSuccess({
    required String runId,
    required RunStatus status,
    required String? assessmentId,
    required String? evidenceSnapshotId,
    required String? finishedAt,
  }) = _ResearchLastSuccess;

  factory ResearchLastSuccess.fromJson(Map<String, dynamic> json) {
    return ResearchLastSuccess(
      runId: requireOpaqueId(json, 'run_id'),
      status: RunStatus.parse(json['status']),
      assessmentId: optionalOpaqueId(json, 'assessment_id'),
      evidenceSnapshotId: optionalOpaqueId(json, 'evidence_snapshot_id'),
      finishedAt: optionalUtcTimestamp(json, 'finished_at'),
    );
  }
}

/// run_state.latest_attempt (research.service.js:823-831): projection of the
/// most recent run of ANY status — including queued, running, failed and
/// stalled. Distinct from ResearchLastSuccess: a later failure never
/// overwrites the last success.
@Freezed(fromJson: false, toJson: false)
abstract class ResearchLatestAttempt with _$ResearchLatestAttempt {
  const factory ResearchLatestAttempt({
    required String runId,
    required RunStatus status,
    required String? stage,
    required String? startedAt,
    required String? finishedAt,
    required String? errorCode,
    required String deadlineAt,
  }) = _ResearchLatestAttempt;

  factory ResearchLatestAttempt.fromJson(Map<String, dynamic> json) {
    return ResearchLatestAttempt(
      runId: requireOpaqueId(json, 'run_id'),
      status: RunStatus.parse(json['status']),
      stage: optionalBoundedText(json, 'stage', maxLength: 80),
      startedAt: optionalUtcTimestamp(json, 'started_at'),
      finishedAt: optionalUtcTimestamp(json, 'finished_at'),
      errorCode: optionalBoundedText(json, 'error_code', maxLength: 120),
      deadlineAt: requireUtcTimestamp(json, 'deadline_at'),
    );
  }
}

/// Cursor-paginated assessment history for
/// GET /research/positions/:id/assessments.
@Freezed(fromJson: false, toJson: false)
abstract class AssessmentPage with _$AssessmentPage {
  const factory AssessmentPage({
    required List<ResearchAssessment> assessments,
    required String? nextCursor,
  }) = _AssessmentPage;

  factory AssessmentPage.fromJson(Map<String, dynamic> json) {
    final assessmentsJson = json['assessments'];
    if (assessmentsJson is! List) {
      throw ContractFormatException('Field "assessments": expected an array');
    }
    return AssessmentPage(
      assessments: assessmentsJson
          .map((entry) => entry is Map<String, dynamic>
              ? ResearchAssessment.fromJson(entry)
              : throw ContractFormatException(
                  'Field "assessments": expected assessment objects'))
          .toList(),
      nextCursor: optionalBoundedText(json, 'next_cursor', maxLength: 500),
    );
  }
}
