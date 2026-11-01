// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'research_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReportingPeriod {

 String? get start; String? get end; String? get label;
/// Create a copy of ReportingPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportingPeriodCopyWith<ReportingPeriod> get copyWith => _$ReportingPeriodCopyWithImpl<ReportingPeriod>(this as ReportingPeriod, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportingPeriod&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,start,end,label);

@override
String toString() {
  return 'ReportingPeriod(start: $start, end: $end, label: $label)';
}


}

/// @nodoc
abstract mixin class $ReportingPeriodCopyWith<$Res>  {
  factory $ReportingPeriodCopyWith(ReportingPeriod value, $Res Function(ReportingPeriod) _then) = _$ReportingPeriodCopyWithImpl;
@useResult
$Res call({
 String? start, String? end, String? label
});




}
/// @nodoc
class _$ReportingPeriodCopyWithImpl<$Res>
    implements $ReportingPeriodCopyWith<$Res> {
  _$ReportingPeriodCopyWithImpl(this._self, this._then);

  final ReportingPeriod _self;
  final $Res Function(ReportingPeriod) _then;

/// Create a copy of ReportingPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = freezed,Object? end = freezed,Object? label = freezed,}) {
  return _then(_self.copyWith(
start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String?,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportingPeriod].
extension ReportingPeriodPatterns on ReportingPeriod {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportingPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportingPeriod() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportingPeriod value)  $default,){
final _that = this;
switch (_that) {
case _ReportingPeriod():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportingPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _ReportingPeriod() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? start,  String? end,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportingPeriod() when $default != null:
return $default(_that.start,_that.end,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? start,  String? end,  String? label)  $default,) {final _that = this;
switch (_that) {
case _ReportingPeriod():
return $default(_that.start,_that.end,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? start,  String? end,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _ReportingPeriod() when $default != null:
return $default(_that.start,_that.end,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _ReportingPeriod implements ReportingPeriod {
  const _ReportingPeriod({required this.start, required this.end, required this.label});
  

@override final  String? start;
@override final  String? end;
@override final  String? label;

/// Create a copy of ReportingPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportingPeriodCopyWith<_ReportingPeriod> get copyWith => __$ReportingPeriodCopyWithImpl<_ReportingPeriod>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportingPeriod&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,start,end,label);

@override
String toString() {
  return 'ReportingPeriod(start: $start, end: $end, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ReportingPeriodCopyWith<$Res> implements $ReportingPeriodCopyWith<$Res> {
  factory _$ReportingPeriodCopyWith(_ReportingPeriod value, $Res Function(_ReportingPeriod) _then) = __$ReportingPeriodCopyWithImpl;
@override @useResult
$Res call({
 String? start, String? end, String? label
});




}
/// @nodoc
class __$ReportingPeriodCopyWithImpl<$Res>
    implements _$ReportingPeriodCopyWith<$Res> {
  __$ReportingPeriodCopyWithImpl(this._self, this._then);

  final _ReportingPeriod _self;
  final $Res Function(_ReportingPeriod) _then;

/// Create a copy of ReportingPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = freezed,Object? end = freezed,Object? label = freezed,}) {
  return _then(_ReportingPeriod(
start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String?,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$EvidenceFact {

 String get id; String get label; Object? get value; String? get unit; String? get currency; String? get basis; ReportingPeriod? get reportingPeriod;
/// Create a copy of EvidenceFact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceFactCopyWith<EvidenceFact> get copyWith => _$EvidenceFactCopyWithImpl<EvidenceFact>(this as EvidenceFact, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceFact&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.reportingPeriod, reportingPeriod) || other.reportingPeriod == reportingPeriod));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,const DeepCollectionEquality().hash(value),unit,currency,basis,reportingPeriod);

@override
String toString() {
  return 'EvidenceFact(id: $id, label: $label, value: $value, unit: $unit, currency: $currency, basis: $basis, reportingPeriod: $reportingPeriod)';
}


}

/// @nodoc
abstract mixin class $EvidenceFactCopyWith<$Res>  {
  factory $EvidenceFactCopyWith(EvidenceFact value, $Res Function(EvidenceFact) _then) = _$EvidenceFactCopyWithImpl;
@useResult
$Res call({
 String id, String label, Object? value, String? unit, String? currency, String? basis, ReportingPeriod? reportingPeriod
});


$ReportingPeriodCopyWith<$Res>? get reportingPeriod;

}
/// @nodoc
class _$EvidenceFactCopyWithImpl<$Res>
    implements $EvidenceFactCopyWith<$Res> {
  _$EvidenceFactCopyWithImpl(this._self, this._then);

  final EvidenceFact _self;
  final $Res Function(EvidenceFact) _then;

/// Create a copy of EvidenceFact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? value = freezed,Object? unit = freezed,Object? currency = freezed,Object? basis = freezed,Object? reportingPeriod = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,basis: freezed == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String?,reportingPeriod: freezed == reportingPeriod ? _self.reportingPeriod : reportingPeriod // ignore: cast_nullable_to_non_nullable
as ReportingPeriod?,
  ));
}
/// Create a copy of EvidenceFact
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportingPeriodCopyWith<$Res>? get reportingPeriod {
    if (_self.reportingPeriod == null) {
    return null;
  }

  return $ReportingPeriodCopyWith<$Res>(_self.reportingPeriod!, (value) {
    return _then(_self.copyWith(reportingPeriod: value));
  });
}
}


/// Adds pattern-matching-related methods to [EvidenceFact].
extension EvidenceFactPatterns on EvidenceFact {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EvidenceFact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EvidenceFact() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EvidenceFact value)  $default,){
final _that = this;
switch (_that) {
case _EvidenceFact():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EvidenceFact value)?  $default,){
final _that = this;
switch (_that) {
case _EvidenceFact() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  Object? value,  String? unit,  String? currency,  String? basis,  ReportingPeriod? reportingPeriod)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvidenceFact() when $default != null:
return $default(_that.id,_that.label,_that.value,_that.unit,_that.currency,_that.basis,_that.reportingPeriod);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  Object? value,  String? unit,  String? currency,  String? basis,  ReportingPeriod? reportingPeriod)  $default,) {final _that = this;
switch (_that) {
case _EvidenceFact():
return $default(_that.id,_that.label,_that.value,_that.unit,_that.currency,_that.basis,_that.reportingPeriod);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  Object? value,  String? unit,  String? currency,  String? basis,  ReportingPeriod? reportingPeriod)?  $default,) {final _that = this;
switch (_that) {
case _EvidenceFact() when $default != null:
return $default(_that.id,_that.label,_that.value,_that.unit,_that.currency,_that.basis,_that.reportingPeriod);case _:
  return null;

}
}

}

/// @nodoc


class _EvidenceFact implements EvidenceFact {
  const _EvidenceFact({required this.id, required this.label, required this.value, required this.unit, required this.currency, required this.basis, required this.reportingPeriod});
  

@override final  String id;
@override final  String label;
@override final  Object? value;
@override final  String? unit;
@override final  String? currency;
@override final  String? basis;
@override final  ReportingPeriod? reportingPeriod;

/// Create a copy of EvidenceFact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvidenceFactCopyWith<_EvidenceFact> get copyWith => __$EvidenceFactCopyWithImpl<_EvidenceFact>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvidenceFact&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.reportingPeriod, reportingPeriod) || other.reportingPeriod == reportingPeriod));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,const DeepCollectionEquality().hash(value),unit,currency,basis,reportingPeriod);

@override
String toString() {
  return 'EvidenceFact(id: $id, label: $label, value: $value, unit: $unit, currency: $currency, basis: $basis, reportingPeriod: $reportingPeriod)';
}


}

/// @nodoc
abstract mixin class _$EvidenceFactCopyWith<$Res> implements $EvidenceFactCopyWith<$Res> {
  factory _$EvidenceFactCopyWith(_EvidenceFact value, $Res Function(_EvidenceFact) _then) = __$EvidenceFactCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, Object? value, String? unit, String? currency, String? basis, ReportingPeriod? reportingPeriod
});


@override $ReportingPeriodCopyWith<$Res>? get reportingPeriod;

}
/// @nodoc
class __$EvidenceFactCopyWithImpl<$Res>
    implements _$EvidenceFactCopyWith<$Res> {
  __$EvidenceFactCopyWithImpl(this._self, this._then);

  final _EvidenceFact _self;
  final $Res Function(_EvidenceFact) _then;

/// Create a copy of EvidenceFact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? value = freezed,Object? unit = freezed,Object? currency = freezed,Object? basis = freezed,Object? reportingPeriod = freezed,}) {
  return _then(_EvidenceFact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,basis: freezed == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String?,reportingPeriod: freezed == reportingPeriod ? _self.reportingPeriod : reportingPeriod // ignore: cast_nullable_to_non_nullable
as ReportingPeriod?,
  ));
}

/// Create a copy of EvidenceFact
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportingPeriodCopyWith<$Res>? get reportingPeriod {
    if (_self.reportingPeriod == null) {
    return null;
  }

  return $ReportingPeriodCopyWith<$Res>(_self.reportingPeriod!, (value) {
    return _then(_self.copyWith(reportingPeriod: value));
  });
}
}

/// @nodoc
mixin _$EvidenceItem {

 String get id; String get instrumentId; EvidenceKind get kind; String get title; String get sourceUrl; String get sourceName; String? get publishedAt; String get retrievedAt; String? get availableAt; ReportingPeriod? get reportingPeriod; String? get excerpt; String? get sourceLocator; List<EvidenceFact> get facts; CoverageStatus get coverageStatus;
/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceItemCopyWith<EvidenceItem> get copyWith => _$EvidenceItemCopyWithImpl<EvidenceItem>(this as EvidenceItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceItem&&(identical(other.id, id) || other.id == id)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.retrievedAt, retrievedAt) || other.retrievedAt == retrievedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.reportingPeriod, reportingPeriod) || other.reportingPeriod == reportingPeriod)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.sourceLocator, sourceLocator) || other.sourceLocator == sourceLocator)&&const DeepCollectionEquality().equals(other.facts, facts)&&(identical(other.coverageStatus, coverageStatus) || other.coverageStatus == coverageStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,instrumentId,kind,title,sourceUrl,sourceName,publishedAt,retrievedAt,availableAt,reportingPeriod,excerpt,sourceLocator,const DeepCollectionEquality().hash(facts),coverageStatus);

@override
String toString() {
  return 'EvidenceItem(id: $id, instrumentId: $instrumentId, kind: $kind, title: $title, sourceUrl: $sourceUrl, sourceName: $sourceName, publishedAt: $publishedAt, retrievedAt: $retrievedAt, availableAt: $availableAt, reportingPeriod: $reportingPeriod, excerpt: $excerpt, sourceLocator: $sourceLocator, facts: $facts, coverageStatus: $coverageStatus)';
}


}

/// @nodoc
abstract mixin class $EvidenceItemCopyWith<$Res>  {
  factory $EvidenceItemCopyWith(EvidenceItem value, $Res Function(EvidenceItem) _then) = _$EvidenceItemCopyWithImpl;
@useResult
$Res call({
 String id, String instrumentId, EvidenceKind kind, String title, String sourceUrl, String sourceName, String? publishedAt, String retrievedAt, String? availableAt, ReportingPeriod? reportingPeriod, String? excerpt, String? sourceLocator, List<EvidenceFact> facts, CoverageStatus coverageStatus
});


$ReportingPeriodCopyWith<$Res>? get reportingPeriod;

}
/// @nodoc
class _$EvidenceItemCopyWithImpl<$Res>
    implements $EvidenceItemCopyWith<$Res> {
  _$EvidenceItemCopyWithImpl(this._self, this._then);

  final EvidenceItem _self;
  final $Res Function(EvidenceItem) _then;

/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? instrumentId = null,Object? kind = null,Object? title = null,Object? sourceUrl = null,Object? sourceName = null,Object? publishedAt = freezed,Object? retrievedAt = null,Object? availableAt = freezed,Object? reportingPeriod = freezed,Object? excerpt = freezed,Object? sourceLocator = freezed,Object? facts = null,Object? coverageStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EvidenceKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: null == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String,sourceName: null == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String?,retrievedAt: null == retrievedAt ? _self.retrievedAt : retrievedAt // ignore: cast_nullable_to_non_nullable
as String,availableAt: freezed == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as String?,reportingPeriod: freezed == reportingPeriod ? _self.reportingPeriod : reportingPeriod // ignore: cast_nullable_to_non_nullable
as ReportingPeriod?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,sourceLocator: freezed == sourceLocator ? _self.sourceLocator : sourceLocator // ignore: cast_nullable_to_non_nullable
as String?,facts: null == facts ? _self.facts : facts // ignore: cast_nullable_to_non_nullable
as List<EvidenceFact>,coverageStatus: null == coverageStatus ? _self.coverageStatus : coverageStatus // ignore: cast_nullable_to_non_nullable
as CoverageStatus,
  ));
}
/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportingPeriodCopyWith<$Res>? get reportingPeriod {
    if (_self.reportingPeriod == null) {
    return null;
  }

  return $ReportingPeriodCopyWith<$Res>(_self.reportingPeriod!, (value) {
    return _then(_self.copyWith(reportingPeriod: value));
  });
}
}


/// Adds pattern-matching-related methods to [EvidenceItem].
extension EvidenceItemPatterns on EvidenceItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EvidenceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EvidenceItem value)  $default,){
final _that = this;
switch (_that) {
case _EvidenceItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EvidenceItem value)?  $default,){
final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String instrumentId,  EvidenceKind kind,  String title,  String sourceUrl,  String sourceName,  String? publishedAt,  String retrievedAt,  String? availableAt,  ReportingPeriod? reportingPeriod,  String? excerpt,  String? sourceLocator,  List<EvidenceFact> facts,  CoverageStatus coverageStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that.id,_that.instrumentId,_that.kind,_that.title,_that.sourceUrl,_that.sourceName,_that.publishedAt,_that.retrievedAt,_that.availableAt,_that.reportingPeriod,_that.excerpt,_that.sourceLocator,_that.facts,_that.coverageStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String instrumentId,  EvidenceKind kind,  String title,  String sourceUrl,  String sourceName,  String? publishedAt,  String retrievedAt,  String? availableAt,  ReportingPeriod? reportingPeriod,  String? excerpt,  String? sourceLocator,  List<EvidenceFact> facts,  CoverageStatus coverageStatus)  $default,) {final _that = this;
switch (_that) {
case _EvidenceItem():
return $default(_that.id,_that.instrumentId,_that.kind,_that.title,_that.sourceUrl,_that.sourceName,_that.publishedAt,_that.retrievedAt,_that.availableAt,_that.reportingPeriod,_that.excerpt,_that.sourceLocator,_that.facts,_that.coverageStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String instrumentId,  EvidenceKind kind,  String title,  String sourceUrl,  String sourceName,  String? publishedAt,  String retrievedAt,  String? availableAt,  ReportingPeriod? reportingPeriod,  String? excerpt,  String? sourceLocator,  List<EvidenceFact> facts,  CoverageStatus coverageStatus)?  $default,) {final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that.id,_that.instrumentId,_that.kind,_that.title,_that.sourceUrl,_that.sourceName,_that.publishedAt,_that.retrievedAt,_that.availableAt,_that.reportingPeriod,_that.excerpt,_that.sourceLocator,_that.facts,_that.coverageStatus);case _:
  return null;

}
}

}

/// @nodoc


class _EvidenceItem implements EvidenceItem {
  const _EvidenceItem({required this.id, required this.instrumentId, required this.kind, required this.title, required this.sourceUrl, required this.sourceName, required this.publishedAt, required this.retrievedAt, required this.availableAt, required this.reportingPeriod, required this.excerpt, required this.sourceLocator, required final  List<EvidenceFact> facts, required this.coverageStatus}): _facts = facts;
  

@override final  String id;
@override final  String instrumentId;
@override final  EvidenceKind kind;
@override final  String title;
@override final  String sourceUrl;
@override final  String sourceName;
@override final  String? publishedAt;
@override final  String retrievedAt;
@override final  String? availableAt;
@override final  ReportingPeriod? reportingPeriod;
@override final  String? excerpt;
@override final  String? sourceLocator;
 final  List<EvidenceFact> _facts;
@override List<EvidenceFact> get facts {
  if (_facts is EqualUnmodifiableListView) return _facts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_facts);
}

@override final  CoverageStatus coverageStatus;

/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvidenceItemCopyWith<_EvidenceItem> get copyWith => __$EvidenceItemCopyWithImpl<_EvidenceItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvidenceItem&&(identical(other.id, id) || other.id == id)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.retrievedAt, retrievedAt) || other.retrievedAt == retrievedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.reportingPeriod, reportingPeriod) || other.reportingPeriod == reportingPeriod)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.sourceLocator, sourceLocator) || other.sourceLocator == sourceLocator)&&const DeepCollectionEquality().equals(other._facts, _facts)&&(identical(other.coverageStatus, coverageStatus) || other.coverageStatus == coverageStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,instrumentId,kind,title,sourceUrl,sourceName,publishedAt,retrievedAt,availableAt,reportingPeriod,excerpt,sourceLocator,const DeepCollectionEquality().hash(_facts),coverageStatus);

@override
String toString() {
  return 'EvidenceItem(id: $id, instrumentId: $instrumentId, kind: $kind, title: $title, sourceUrl: $sourceUrl, sourceName: $sourceName, publishedAt: $publishedAt, retrievedAt: $retrievedAt, availableAt: $availableAt, reportingPeriod: $reportingPeriod, excerpt: $excerpt, sourceLocator: $sourceLocator, facts: $facts, coverageStatus: $coverageStatus)';
}


}

/// @nodoc
abstract mixin class _$EvidenceItemCopyWith<$Res> implements $EvidenceItemCopyWith<$Res> {
  factory _$EvidenceItemCopyWith(_EvidenceItem value, $Res Function(_EvidenceItem) _then) = __$EvidenceItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String instrumentId, EvidenceKind kind, String title, String sourceUrl, String sourceName, String? publishedAt, String retrievedAt, String? availableAt, ReportingPeriod? reportingPeriod, String? excerpt, String? sourceLocator, List<EvidenceFact> facts, CoverageStatus coverageStatus
});


@override $ReportingPeriodCopyWith<$Res>? get reportingPeriod;

}
/// @nodoc
class __$EvidenceItemCopyWithImpl<$Res>
    implements _$EvidenceItemCopyWith<$Res> {
  __$EvidenceItemCopyWithImpl(this._self, this._then);

  final _EvidenceItem _self;
  final $Res Function(_EvidenceItem) _then;

/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? instrumentId = null,Object? kind = null,Object? title = null,Object? sourceUrl = null,Object? sourceName = null,Object? publishedAt = freezed,Object? retrievedAt = null,Object? availableAt = freezed,Object? reportingPeriod = freezed,Object? excerpt = freezed,Object? sourceLocator = freezed,Object? facts = null,Object? coverageStatus = null,}) {
  return _then(_EvidenceItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EvidenceKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: null == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String,sourceName: null == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String?,retrievedAt: null == retrievedAt ? _self.retrievedAt : retrievedAt // ignore: cast_nullable_to_non_nullable
as String,availableAt: freezed == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as String?,reportingPeriod: freezed == reportingPeriod ? _self.reportingPeriod : reportingPeriod // ignore: cast_nullable_to_non_nullable
as ReportingPeriod?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,sourceLocator: freezed == sourceLocator ? _self.sourceLocator : sourceLocator // ignore: cast_nullable_to_non_nullable
as String?,facts: null == facts ? _self._facts : facts // ignore: cast_nullable_to_non_nullable
as List<EvidenceFact>,coverageStatus: null == coverageStatus ? _self.coverageStatus : coverageStatus // ignore: cast_nullable_to_non_nullable
as CoverageStatus,
  ));
}

/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportingPeriodCopyWith<$Res>? get reportingPeriod {
    if (_self.reportingPeriod == null) {
    return null;
  }

  return $ReportingPeriodCopyWith<$Res>(_self.reportingPeriod!, (value) {
    return _then(_self.copyWith(reportingPeriod: value));
  });
}
}

/// @nodoc
mixin _$Claim {

 String get text; List<String> get evidenceIds; List<String> get metricIds; ClaimType get claimType;
/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaimCopyWith<Claim> get copyWith => _$ClaimCopyWithImpl<Claim>(this as Claim, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Claim&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.evidenceIds, evidenceIds)&&const DeepCollectionEquality().equals(other.metricIds, metricIds)&&(identical(other.claimType, claimType) || other.claimType == claimType));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(evidenceIds),const DeepCollectionEquality().hash(metricIds),claimType);

@override
String toString() {
  return 'Claim(text: $text, evidenceIds: $evidenceIds, metricIds: $metricIds, claimType: $claimType)';
}


}

/// @nodoc
abstract mixin class $ClaimCopyWith<$Res>  {
  factory $ClaimCopyWith(Claim value, $Res Function(Claim) _then) = _$ClaimCopyWithImpl;
@useResult
$Res call({
 String text, List<String> evidenceIds, List<String> metricIds, ClaimType claimType
});




}
/// @nodoc
class _$ClaimCopyWithImpl<$Res>
    implements $ClaimCopyWith<$Res> {
  _$ClaimCopyWithImpl(this._self, this._then);

  final Claim _self;
  final $Res Function(Claim) _then;

/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? evidenceIds = null,Object? metricIds = null,Object? claimType = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,evidenceIds: null == evidenceIds ? _self.evidenceIds : evidenceIds // ignore: cast_nullable_to_non_nullable
as List<String>,metricIds: null == metricIds ? _self.metricIds : metricIds // ignore: cast_nullable_to_non_nullable
as List<String>,claimType: null == claimType ? _self.claimType : claimType // ignore: cast_nullable_to_non_nullable
as ClaimType,
  ));
}

}


/// Adds pattern-matching-related methods to [Claim].
extension ClaimPatterns on Claim {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Claim value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Claim() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Claim value)  $default,){
final _that = this;
switch (_that) {
case _Claim():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Claim value)?  $default,){
final _that = this;
switch (_that) {
case _Claim() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  List<String> evidenceIds,  List<String> metricIds,  ClaimType claimType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Claim() when $default != null:
return $default(_that.text,_that.evidenceIds,_that.metricIds,_that.claimType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  List<String> evidenceIds,  List<String> metricIds,  ClaimType claimType)  $default,) {final _that = this;
switch (_that) {
case _Claim():
return $default(_that.text,_that.evidenceIds,_that.metricIds,_that.claimType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  List<String> evidenceIds,  List<String> metricIds,  ClaimType claimType)?  $default,) {final _that = this;
switch (_that) {
case _Claim() when $default != null:
return $default(_that.text,_that.evidenceIds,_that.metricIds,_that.claimType);case _:
  return null;

}
}

}

/// @nodoc


class _Claim implements Claim {
  const _Claim({required this.text, required final  List<String> evidenceIds, required final  List<String> metricIds, required this.claimType}): _evidenceIds = evidenceIds,_metricIds = metricIds;
  

@override final  String text;
 final  List<String> _evidenceIds;
@override List<String> get evidenceIds {
  if (_evidenceIds is EqualUnmodifiableListView) return _evidenceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evidenceIds);
}

 final  List<String> _metricIds;
@override List<String> get metricIds {
  if (_metricIds is EqualUnmodifiableListView) return _metricIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metricIds);
}

@override final  ClaimType claimType;

/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClaimCopyWith<_Claim> get copyWith => __$ClaimCopyWithImpl<_Claim>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Claim&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._evidenceIds, _evidenceIds)&&const DeepCollectionEquality().equals(other._metricIds, _metricIds)&&(identical(other.claimType, claimType) || other.claimType == claimType));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_evidenceIds),const DeepCollectionEquality().hash(_metricIds),claimType);

@override
String toString() {
  return 'Claim(text: $text, evidenceIds: $evidenceIds, metricIds: $metricIds, claimType: $claimType)';
}


}

/// @nodoc
abstract mixin class _$ClaimCopyWith<$Res> implements $ClaimCopyWith<$Res> {
  factory _$ClaimCopyWith(_Claim value, $Res Function(_Claim) _then) = __$ClaimCopyWithImpl;
@override @useResult
$Res call({
 String text, List<String> evidenceIds, List<String> metricIds, ClaimType claimType
});




}
/// @nodoc
class __$ClaimCopyWithImpl<$Res>
    implements _$ClaimCopyWith<$Res> {
  __$ClaimCopyWithImpl(this._self, this._then);

  final _Claim _self;
  final $Res Function(_Claim) _then;

/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? evidenceIds = null,Object? metricIds = null,Object? claimType = null,}) {
  return _then(_Claim(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,evidenceIds: null == evidenceIds ? _self._evidenceIds : evidenceIds // ignore: cast_nullable_to_non_nullable
as List<String>,metricIds: null == metricIds ? _self._metricIds : metricIds // ignore: cast_nullable_to_non_nullable
as List<String>,claimType: null == claimType ? _self.claimType : claimType // ignore: cast_nullable_to_non_nullable
as ClaimType,
  ));
}


}

/// @nodoc
mixin _$ThesisSection {

 String get summary; List<Claim> get claims;
/// Create a copy of ThesisSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThesisSectionCopyWith<ThesisSection> get copyWith => _$ThesisSectionCopyWithImpl<ThesisSection>(this as ThesisSection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThesisSection&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.claims, claims));
}


@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(claims));

@override
String toString() {
  return 'ThesisSection(summary: $summary, claims: $claims)';
}


}

/// @nodoc
abstract mixin class $ThesisSectionCopyWith<$Res>  {
  factory $ThesisSectionCopyWith(ThesisSection value, $Res Function(ThesisSection) _then) = _$ThesisSectionCopyWithImpl;
@useResult
$Res call({
 String summary, List<Claim> claims
});




}
/// @nodoc
class _$ThesisSectionCopyWithImpl<$Res>
    implements $ThesisSectionCopyWith<$Res> {
  _$ThesisSectionCopyWithImpl(this._self, this._then);

  final ThesisSection _self;
  final $Res Function(ThesisSection) _then;

/// Create a copy of ThesisSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? claims = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,claims: null == claims ? _self.claims : claims // ignore: cast_nullable_to_non_nullable
as List<Claim>,
  ));
}

}


/// Adds pattern-matching-related methods to [ThesisSection].
extension ThesisSectionPatterns on ThesisSection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThesisSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThesisSection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThesisSection value)  $default,){
final _that = this;
switch (_that) {
case _ThesisSection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThesisSection value)?  $default,){
final _that = this;
switch (_that) {
case _ThesisSection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summary,  List<Claim> claims)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThesisSection() when $default != null:
return $default(_that.summary,_that.claims);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summary,  List<Claim> claims)  $default,) {final _that = this;
switch (_that) {
case _ThesisSection():
return $default(_that.summary,_that.claims);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summary,  List<Claim> claims)?  $default,) {final _that = this;
switch (_that) {
case _ThesisSection() when $default != null:
return $default(_that.summary,_that.claims);case _:
  return null;

}
}

}

/// @nodoc


class _ThesisSection implements ThesisSection {
  const _ThesisSection({required this.summary, required final  List<Claim> claims}): _claims = claims;
  

@override final  String summary;
 final  List<Claim> _claims;
@override List<Claim> get claims {
  if (_claims is EqualUnmodifiableListView) return _claims;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_claims);
}


/// Create a copy of ThesisSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThesisSectionCopyWith<_ThesisSection> get copyWith => __$ThesisSectionCopyWithImpl<_ThesisSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThesisSection&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._claims, _claims));
}


@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_claims));

@override
String toString() {
  return 'ThesisSection(summary: $summary, claims: $claims)';
}


}

/// @nodoc
abstract mixin class _$ThesisSectionCopyWith<$Res> implements $ThesisSectionCopyWith<$Res> {
  factory _$ThesisSectionCopyWith(_ThesisSection value, $Res Function(_ThesisSection) _then) = __$ThesisSectionCopyWithImpl;
@override @useResult
$Res call({
 String summary, List<Claim> claims
});




}
/// @nodoc
class __$ThesisSectionCopyWithImpl<$Res>
    implements _$ThesisSectionCopyWith<$Res> {
  __$ThesisSectionCopyWithImpl(this._self, this._then);

  final _ThesisSection _self;
  final $Res Function(_ThesisSection) _then;

/// Create a copy of ThesisSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? claims = null,}) {
  return _then(_ThesisSection(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,claims: null == claims ? _self._claims : claims // ignore: cast_nullable_to_non_nullable
as List<Claim>,
  ));
}


}

/// @nodoc
mixin _$MarketThesis {

 ThesisSection get businessAssessment; ThesisSection get priceTechnicalAssessment; ThesisSection get valuationAssessment; List<Claim> get rationale; List<Claim> get counterevidence;
/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketThesisCopyWith<MarketThesis> get copyWith => _$MarketThesisCopyWithImpl<MarketThesis>(this as MarketThesis, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketThesis&&(identical(other.businessAssessment, businessAssessment) || other.businessAssessment == businessAssessment)&&(identical(other.priceTechnicalAssessment, priceTechnicalAssessment) || other.priceTechnicalAssessment == priceTechnicalAssessment)&&(identical(other.valuationAssessment, valuationAssessment) || other.valuationAssessment == valuationAssessment)&&const DeepCollectionEquality().equals(other.rationale, rationale)&&const DeepCollectionEquality().equals(other.counterevidence, counterevidence));
}


@override
int get hashCode => Object.hash(runtimeType,businessAssessment,priceTechnicalAssessment,valuationAssessment,const DeepCollectionEquality().hash(rationale),const DeepCollectionEquality().hash(counterevidence));

@override
String toString() {
  return 'MarketThesis(businessAssessment: $businessAssessment, priceTechnicalAssessment: $priceTechnicalAssessment, valuationAssessment: $valuationAssessment, rationale: $rationale, counterevidence: $counterevidence)';
}


}

/// @nodoc
abstract mixin class $MarketThesisCopyWith<$Res>  {
  factory $MarketThesisCopyWith(MarketThesis value, $Res Function(MarketThesis) _then) = _$MarketThesisCopyWithImpl;
@useResult
$Res call({
 ThesisSection businessAssessment, ThesisSection priceTechnicalAssessment, ThesisSection valuationAssessment, List<Claim> rationale, List<Claim> counterevidence
});


$ThesisSectionCopyWith<$Res> get businessAssessment;$ThesisSectionCopyWith<$Res> get priceTechnicalAssessment;$ThesisSectionCopyWith<$Res> get valuationAssessment;

}
/// @nodoc
class _$MarketThesisCopyWithImpl<$Res>
    implements $MarketThesisCopyWith<$Res> {
  _$MarketThesisCopyWithImpl(this._self, this._then);

  final MarketThesis _self;
  final $Res Function(MarketThesis) _then;

/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessAssessment = null,Object? priceTechnicalAssessment = null,Object? valuationAssessment = null,Object? rationale = null,Object? counterevidence = null,}) {
  return _then(_self.copyWith(
businessAssessment: null == businessAssessment ? _self.businessAssessment : businessAssessment // ignore: cast_nullable_to_non_nullable
as ThesisSection,priceTechnicalAssessment: null == priceTechnicalAssessment ? _self.priceTechnicalAssessment : priceTechnicalAssessment // ignore: cast_nullable_to_non_nullable
as ThesisSection,valuationAssessment: null == valuationAssessment ? _self.valuationAssessment : valuationAssessment // ignore: cast_nullable_to_non_nullable
as ThesisSection,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as List<Claim>,counterevidence: null == counterevidence ? _self.counterevidence : counterevidence // ignore: cast_nullable_to_non_nullable
as List<Claim>,
  ));
}
/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThesisSectionCopyWith<$Res> get businessAssessment {
  
  return $ThesisSectionCopyWith<$Res>(_self.businessAssessment, (value) {
    return _then(_self.copyWith(businessAssessment: value));
  });
}/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThesisSectionCopyWith<$Res> get priceTechnicalAssessment {
  
  return $ThesisSectionCopyWith<$Res>(_self.priceTechnicalAssessment, (value) {
    return _then(_self.copyWith(priceTechnicalAssessment: value));
  });
}/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThesisSectionCopyWith<$Res> get valuationAssessment {
  
  return $ThesisSectionCopyWith<$Res>(_self.valuationAssessment, (value) {
    return _then(_self.copyWith(valuationAssessment: value));
  });
}
}


/// Adds pattern-matching-related methods to [MarketThesis].
extension MarketThesisPatterns on MarketThesis {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketThesis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketThesis() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketThesis value)  $default,){
final _that = this;
switch (_that) {
case _MarketThesis():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketThesis value)?  $default,){
final _that = this;
switch (_that) {
case _MarketThesis() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThesisSection businessAssessment,  ThesisSection priceTechnicalAssessment,  ThesisSection valuationAssessment,  List<Claim> rationale,  List<Claim> counterevidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketThesis() when $default != null:
return $default(_that.businessAssessment,_that.priceTechnicalAssessment,_that.valuationAssessment,_that.rationale,_that.counterevidence);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThesisSection businessAssessment,  ThesisSection priceTechnicalAssessment,  ThesisSection valuationAssessment,  List<Claim> rationale,  List<Claim> counterevidence)  $default,) {final _that = this;
switch (_that) {
case _MarketThesis():
return $default(_that.businessAssessment,_that.priceTechnicalAssessment,_that.valuationAssessment,_that.rationale,_that.counterevidence);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThesisSection businessAssessment,  ThesisSection priceTechnicalAssessment,  ThesisSection valuationAssessment,  List<Claim> rationale,  List<Claim> counterevidence)?  $default,) {final _that = this;
switch (_that) {
case _MarketThesis() when $default != null:
return $default(_that.businessAssessment,_that.priceTechnicalAssessment,_that.valuationAssessment,_that.rationale,_that.counterevidence);case _:
  return null;

}
}

}

/// @nodoc


class _MarketThesis implements MarketThesis {
  const _MarketThesis({required this.businessAssessment, required this.priceTechnicalAssessment, required this.valuationAssessment, required final  List<Claim> rationale, required final  List<Claim> counterevidence}): _rationale = rationale,_counterevidence = counterevidence;
  

@override final  ThesisSection businessAssessment;
@override final  ThesisSection priceTechnicalAssessment;
@override final  ThesisSection valuationAssessment;
 final  List<Claim> _rationale;
@override List<Claim> get rationale {
  if (_rationale is EqualUnmodifiableListView) return _rationale;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rationale);
}

 final  List<Claim> _counterevidence;
@override List<Claim> get counterevidence {
  if (_counterevidence is EqualUnmodifiableListView) return _counterevidence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_counterevidence);
}


/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketThesisCopyWith<_MarketThesis> get copyWith => __$MarketThesisCopyWithImpl<_MarketThesis>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketThesis&&(identical(other.businessAssessment, businessAssessment) || other.businessAssessment == businessAssessment)&&(identical(other.priceTechnicalAssessment, priceTechnicalAssessment) || other.priceTechnicalAssessment == priceTechnicalAssessment)&&(identical(other.valuationAssessment, valuationAssessment) || other.valuationAssessment == valuationAssessment)&&const DeepCollectionEquality().equals(other._rationale, _rationale)&&const DeepCollectionEquality().equals(other._counterevidence, _counterevidence));
}


@override
int get hashCode => Object.hash(runtimeType,businessAssessment,priceTechnicalAssessment,valuationAssessment,const DeepCollectionEquality().hash(_rationale),const DeepCollectionEquality().hash(_counterevidence));

@override
String toString() {
  return 'MarketThesis(businessAssessment: $businessAssessment, priceTechnicalAssessment: $priceTechnicalAssessment, valuationAssessment: $valuationAssessment, rationale: $rationale, counterevidence: $counterevidence)';
}


}

/// @nodoc
abstract mixin class _$MarketThesisCopyWith<$Res> implements $MarketThesisCopyWith<$Res> {
  factory _$MarketThesisCopyWith(_MarketThesis value, $Res Function(_MarketThesis) _then) = __$MarketThesisCopyWithImpl;
@override @useResult
$Res call({
 ThesisSection businessAssessment, ThesisSection priceTechnicalAssessment, ThesisSection valuationAssessment, List<Claim> rationale, List<Claim> counterevidence
});


@override $ThesisSectionCopyWith<$Res> get businessAssessment;@override $ThesisSectionCopyWith<$Res> get priceTechnicalAssessment;@override $ThesisSectionCopyWith<$Res> get valuationAssessment;

}
/// @nodoc
class __$MarketThesisCopyWithImpl<$Res>
    implements _$MarketThesisCopyWith<$Res> {
  __$MarketThesisCopyWithImpl(this._self, this._then);

  final _MarketThesis _self;
  final $Res Function(_MarketThesis) _then;

/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessAssessment = null,Object? priceTechnicalAssessment = null,Object? valuationAssessment = null,Object? rationale = null,Object? counterevidence = null,}) {
  return _then(_MarketThesis(
businessAssessment: null == businessAssessment ? _self.businessAssessment : businessAssessment // ignore: cast_nullable_to_non_nullable
as ThesisSection,priceTechnicalAssessment: null == priceTechnicalAssessment ? _self.priceTechnicalAssessment : priceTechnicalAssessment // ignore: cast_nullable_to_non_nullable
as ThesisSection,valuationAssessment: null == valuationAssessment ? _self.valuationAssessment : valuationAssessment // ignore: cast_nullable_to_non_nullable
as ThesisSection,rationale: null == rationale ? _self._rationale : rationale // ignore: cast_nullable_to_non_nullable
as List<Claim>,counterevidence: null == counterevidence ? _self._counterevidence : counterevidence // ignore: cast_nullable_to_non_nullable
as List<Claim>,
  ));
}

/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThesisSectionCopyWith<$Res> get businessAssessment {
  
  return $ThesisSectionCopyWith<$Res>(_self.businessAssessment, (value) {
    return _then(_self.copyWith(businessAssessment: value));
  });
}/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThesisSectionCopyWith<$Res> get priceTechnicalAssessment {
  
  return $ThesisSectionCopyWith<$Res>(_self.priceTechnicalAssessment, (value) {
    return _then(_self.copyWith(priceTechnicalAssessment: value));
  });
}/// Create a copy of MarketThesis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThesisSectionCopyWith<$Res> get valuationAssessment {
  
  return $ThesisSectionCopyWith<$Res>(_self.valuationAssessment, (value) {
    return _then(_self.copyWith(valuationAssessment: value));
  });
}
}

/// @nodoc
mixin _$Recommendation {

 RecommendationAction get action; int get horizonMonths; String get headline; List<Claim> get rationale; List<Claim> get countercase; List<Claim> get invalidationConditions; String get evidenceQuality; String get predictiveUncertainty;
/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendationCopyWith<Recommendation> get copyWith => _$RecommendationCopyWithImpl<Recommendation>(this as Recommendation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recommendation&&(identical(other.action, action) || other.action == action)&&(identical(other.horizonMonths, horizonMonths) || other.horizonMonths == horizonMonths)&&(identical(other.headline, headline) || other.headline == headline)&&const DeepCollectionEquality().equals(other.rationale, rationale)&&const DeepCollectionEquality().equals(other.countercase, countercase)&&const DeepCollectionEquality().equals(other.invalidationConditions, invalidationConditions)&&(identical(other.evidenceQuality, evidenceQuality) || other.evidenceQuality == evidenceQuality)&&(identical(other.predictiveUncertainty, predictiveUncertainty) || other.predictiveUncertainty == predictiveUncertainty));
}


@override
int get hashCode => Object.hash(runtimeType,action,horizonMonths,headline,const DeepCollectionEquality().hash(rationale),const DeepCollectionEquality().hash(countercase),const DeepCollectionEquality().hash(invalidationConditions),evidenceQuality,predictiveUncertainty);

@override
String toString() {
  return 'Recommendation(action: $action, horizonMonths: $horizonMonths, headline: $headline, rationale: $rationale, countercase: $countercase, invalidationConditions: $invalidationConditions, evidenceQuality: $evidenceQuality, predictiveUncertainty: $predictiveUncertainty)';
}


}

/// @nodoc
abstract mixin class $RecommendationCopyWith<$Res>  {
  factory $RecommendationCopyWith(Recommendation value, $Res Function(Recommendation) _then) = _$RecommendationCopyWithImpl;
@useResult
$Res call({
 RecommendationAction action, int horizonMonths, String headline, List<Claim> rationale, List<Claim> countercase, List<Claim> invalidationConditions, String evidenceQuality, String predictiveUncertainty
});




}
/// @nodoc
class _$RecommendationCopyWithImpl<$Res>
    implements $RecommendationCopyWith<$Res> {
  _$RecommendationCopyWithImpl(this._self, this._then);

  final Recommendation _self;
  final $Res Function(Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? horizonMonths = null,Object? headline = null,Object? rationale = null,Object? countercase = null,Object? invalidationConditions = null,Object? evidenceQuality = null,Object? predictiveUncertainty = null,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as RecommendationAction,horizonMonths: null == horizonMonths ? _self.horizonMonths : horizonMonths // ignore: cast_nullable_to_non_nullable
as int,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as List<Claim>,countercase: null == countercase ? _self.countercase : countercase // ignore: cast_nullable_to_non_nullable
as List<Claim>,invalidationConditions: null == invalidationConditions ? _self.invalidationConditions : invalidationConditions // ignore: cast_nullable_to_non_nullable
as List<Claim>,evidenceQuality: null == evidenceQuality ? _self.evidenceQuality : evidenceQuality // ignore: cast_nullable_to_non_nullable
as String,predictiveUncertainty: null == predictiveUncertainty ? _self.predictiveUncertainty : predictiveUncertainty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Recommendation].
extension RecommendationPatterns on Recommendation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recommendation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recommendation value)  $default,){
final _that = this;
switch (_that) {
case _Recommendation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recommendation value)?  $default,){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RecommendationAction action,  int horizonMonths,  String headline,  List<Claim> rationale,  List<Claim> countercase,  List<Claim> invalidationConditions,  String evidenceQuality,  String predictiveUncertainty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.action,_that.horizonMonths,_that.headline,_that.rationale,_that.countercase,_that.invalidationConditions,_that.evidenceQuality,_that.predictiveUncertainty);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RecommendationAction action,  int horizonMonths,  String headline,  List<Claim> rationale,  List<Claim> countercase,  List<Claim> invalidationConditions,  String evidenceQuality,  String predictiveUncertainty)  $default,) {final _that = this;
switch (_that) {
case _Recommendation():
return $default(_that.action,_that.horizonMonths,_that.headline,_that.rationale,_that.countercase,_that.invalidationConditions,_that.evidenceQuality,_that.predictiveUncertainty);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RecommendationAction action,  int horizonMonths,  String headline,  List<Claim> rationale,  List<Claim> countercase,  List<Claim> invalidationConditions,  String evidenceQuality,  String predictiveUncertainty)?  $default,) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.action,_that.horizonMonths,_that.headline,_that.rationale,_that.countercase,_that.invalidationConditions,_that.evidenceQuality,_that.predictiveUncertainty);case _:
  return null;

}
}

}

/// @nodoc


class _Recommendation implements Recommendation {
  const _Recommendation({required this.action, required this.horizonMonths, required this.headline, required final  List<Claim> rationale, required final  List<Claim> countercase, required final  List<Claim> invalidationConditions, required this.evidenceQuality, required this.predictiveUncertainty}): _rationale = rationale,_countercase = countercase,_invalidationConditions = invalidationConditions;
  

@override final  RecommendationAction action;
@override final  int horizonMonths;
@override final  String headline;
 final  List<Claim> _rationale;
@override List<Claim> get rationale {
  if (_rationale is EqualUnmodifiableListView) return _rationale;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rationale);
}

 final  List<Claim> _countercase;
@override List<Claim> get countercase {
  if (_countercase is EqualUnmodifiableListView) return _countercase;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_countercase);
}

 final  List<Claim> _invalidationConditions;
@override List<Claim> get invalidationConditions {
  if (_invalidationConditions is EqualUnmodifiableListView) return _invalidationConditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invalidationConditions);
}

@override final  String evidenceQuality;
@override final  String predictiveUncertainty;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendationCopyWith<_Recommendation> get copyWith => __$RecommendationCopyWithImpl<_Recommendation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recommendation&&(identical(other.action, action) || other.action == action)&&(identical(other.horizonMonths, horizonMonths) || other.horizonMonths == horizonMonths)&&(identical(other.headline, headline) || other.headline == headline)&&const DeepCollectionEquality().equals(other._rationale, _rationale)&&const DeepCollectionEquality().equals(other._countercase, _countercase)&&const DeepCollectionEquality().equals(other._invalidationConditions, _invalidationConditions)&&(identical(other.evidenceQuality, evidenceQuality) || other.evidenceQuality == evidenceQuality)&&(identical(other.predictiveUncertainty, predictiveUncertainty) || other.predictiveUncertainty == predictiveUncertainty));
}


@override
int get hashCode => Object.hash(runtimeType,action,horizonMonths,headline,const DeepCollectionEquality().hash(_rationale),const DeepCollectionEquality().hash(_countercase),const DeepCollectionEquality().hash(_invalidationConditions),evidenceQuality,predictiveUncertainty);

@override
String toString() {
  return 'Recommendation(action: $action, horizonMonths: $horizonMonths, headline: $headline, rationale: $rationale, countercase: $countercase, invalidationConditions: $invalidationConditions, evidenceQuality: $evidenceQuality, predictiveUncertainty: $predictiveUncertainty)';
}


}

/// @nodoc
abstract mixin class _$RecommendationCopyWith<$Res> implements $RecommendationCopyWith<$Res> {
  factory _$RecommendationCopyWith(_Recommendation value, $Res Function(_Recommendation) _then) = __$RecommendationCopyWithImpl;
@override @useResult
$Res call({
 RecommendationAction action, int horizonMonths, String headline, List<Claim> rationale, List<Claim> countercase, List<Claim> invalidationConditions, String evidenceQuality, String predictiveUncertainty
});




}
/// @nodoc
class __$RecommendationCopyWithImpl<$Res>
    implements _$RecommendationCopyWith<$Res> {
  __$RecommendationCopyWithImpl(this._self, this._then);

  final _Recommendation _self;
  final $Res Function(_Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? horizonMonths = null,Object? headline = null,Object? rationale = null,Object? countercase = null,Object? invalidationConditions = null,Object? evidenceQuality = null,Object? predictiveUncertainty = null,}) {
  return _then(_Recommendation(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as RecommendationAction,horizonMonths: null == horizonMonths ? _self.horizonMonths : horizonMonths // ignore: cast_nullable_to_non_nullable
as int,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,rationale: null == rationale ? _self._rationale : rationale // ignore: cast_nullable_to_non_nullable
as List<Claim>,countercase: null == countercase ? _self._countercase : countercase // ignore: cast_nullable_to_non_nullable
as List<Claim>,invalidationConditions: null == invalidationConditions ? _self._invalidationConditions : invalidationConditions // ignore: cast_nullable_to_non_nullable
as List<Claim>,evidenceQuality: null == evidenceQuality ? _self.evidenceQuality : evidenceQuality // ignore: cast_nullable_to_non_nullable
as String,predictiveUncertainty: null == predictiveUncertainty ? _self.predictiveUncertainty : predictiveUncertainty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AssessmentPositionContext {

 String? get positionId; String get instrumentId; PositionState get state; int? get revision; MoneyAmount? get averageCost; String? get quantity; String? get openedOn; EconomicsStatus? get economicsStatus;
/// Create a copy of AssessmentPositionContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssessmentPositionContextCopyWith<AssessmentPositionContext> get copyWith => _$AssessmentPositionContextCopyWithImpl<AssessmentPositionContext>(this as AssessmentPositionContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssessmentPositionContext&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.state, state) || other.state == state)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.averageCost, averageCost) || other.averageCost == averageCost)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.economicsStatus, economicsStatus) || other.economicsStatus == economicsStatus));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,instrumentId,state,revision,averageCost,quantity,openedOn,economicsStatus);

@override
String toString() {
  return 'AssessmentPositionContext(positionId: $positionId, instrumentId: $instrumentId, state: $state, revision: $revision, averageCost: $averageCost, quantity: $quantity, openedOn: $openedOn, economicsStatus: $economicsStatus)';
}


}

/// @nodoc
abstract mixin class $AssessmentPositionContextCopyWith<$Res>  {
  factory $AssessmentPositionContextCopyWith(AssessmentPositionContext value, $Res Function(AssessmentPositionContext) _then) = _$AssessmentPositionContextCopyWithImpl;
@useResult
$Res call({
 String? positionId, String instrumentId, PositionState state, int? revision, MoneyAmount? averageCost, String? quantity, String? openedOn, EconomicsStatus? economicsStatus
});


$MoneyAmountCopyWith<$Res>? get averageCost;

}
/// @nodoc
class _$AssessmentPositionContextCopyWithImpl<$Res>
    implements $AssessmentPositionContextCopyWith<$Res> {
  _$AssessmentPositionContextCopyWithImpl(this._self, this._then);

  final AssessmentPositionContext _self;
  final $Res Function(AssessmentPositionContext) _then;

/// Create a copy of AssessmentPositionContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionId = freezed,Object? instrumentId = null,Object? state = null,Object? revision = freezed,Object? averageCost = freezed,Object? quantity = freezed,Object? openedOn = freezed,Object? economicsStatus = freezed,}) {
  return _then(_self.copyWith(
positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PositionState,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int?,averageCost: freezed == averageCost ? _self.averageCost : averageCost // ignore: cast_nullable_to_non_nullable
as MoneyAmount?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,economicsStatus: freezed == economicsStatus ? _self.economicsStatus : economicsStatus // ignore: cast_nullable_to_non_nullable
as EconomicsStatus?,
  ));
}
/// Create a copy of AssessmentPositionContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyAmountCopyWith<$Res>? get averageCost {
    if (_self.averageCost == null) {
    return null;
  }

  return $MoneyAmountCopyWith<$Res>(_self.averageCost!, (value) {
    return _then(_self.copyWith(averageCost: value));
  });
}
}


/// Adds pattern-matching-related methods to [AssessmentPositionContext].
extension AssessmentPositionContextPatterns on AssessmentPositionContext {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssessmentPositionContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssessmentPositionContext() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssessmentPositionContext value)  $default,){
final _that = this;
switch (_that) {
case _AssessmentPositionContext():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssessmentPositionContext value)?  $default,){
final _that = this;
switch (_that) {
case _AssessmentPositionContext() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? positionId,  String instrumentId,  PositionState state,  int? revision,  MoneyAmount? averageCost,  String? quantity,  String? openedOn,  EconomicsStatus? economicsStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssessmentPositionContext() when $default != null:
return $default(_that.positionId,_that.instrumentId,_that.state,_that.revision,_that.averageCost,_that.quantity,_that.openedOn,_that.economicsStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? positionId,  String instrumentId,  PositionState state,  int? revision,  MoneyAmount? averageCost,  String? quantity,  String? openedOn,  EconomicsStatus? economicsStatus)  $default,) {final _that = this;
switch (_that) {
case _AssessmentPositionContext():
return $default(_that.positionId,_that.instrumentId,_that.state,_that.revision,_that.averageCost,_that.quantity,_that.openedOn,_that.economicsStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? positionId,  String instrumentId,  PositionState state,  int? revision,  MoneyAmount? averageCost,  String? quantity,  String? openedOn,  EconomicsStatus? economicsStatus)?  $default,) {final _that = this;
switch (_that) {
case _AssessmentPositionContext() when $default != null:
return $default(_that.positionId,_that.instrumentId,_that.state,_that.revision,_that.averageCost,_that.quantity,_that.openedOn,_that.economicsStatus);case _:
  return null;

}
}

}

/// @nodoc


class _AssessmentPositionContext implements AssessmentPositionContext {
  const _AssessmentPositionContext({required this.positionId, required this.instrumentId, required this.state, required this.revision, required this.averageCost, required this.quantity, required this.openedOn, required this.economicsStatus});
  

@override final  String? positionId;
@override final  String instrumentId;
@override final  PositionState state;
@override final  int? revision;
@override final  MoneyAmount? averageCost;
@override final  String? quantity;
@override final  String? openedOn;
@override final  EconomicsStatus? economicsStatus;

/// Create a copy of AssessmentPositionContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssessmentPositionContextCopyWith<_AssessmentPositionContext> get copyWith => __$AssessmentPositionContextCopyWithImpl<_AssessmentPositionContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssessmentPositionContext&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.state, state) || other.state == state)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.averageCost, averageCost) || other.averageCost == averageCost)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.economicsStatus, economicsStatus) || other.economicsStatus == economicsStatus));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,instrumentId,state,revision,averageCost,quantity,openedOn,economicsStatus);

@override
String toString() {
  return 'AssessmentPositionContext(positionId: $positionId, instrumentId: $instrumentId, state: $state, revision: $revision, averageCost: $averageCost, quantity: $quantity, openedOn: $openedOn, economicsStatus: $economicsStatus)';
}


}

/// @nodoc
abstract mixin class _$AssessmentPositionContextCopyWith<$Res> implements $AssessmentPositionContextCopyWith<$Res> {
  factory _$AssessmentPositionContextCopyWith(_AssessmentPositionContext value, $Res Function(_AssessmentPositionContext) _then) = __$AssessmentPositionContextCopyWithImpl;
@override @useResult
$Res call({
 String? positionId, String instrumentId, PositionState state, int? revision, MoneyAmount? averageCost, String? quantity, String? openedOn, EconomicsStatus? economicsStatus
});


@override $MoneyAmountCopyWith<$Res>? get averageCost;

}
/// @nodoc
class __$AssessmentPositionContextCopyWithImpl<$Res>
    implements _$AssessmentPositionContextCopyWith<$Res> {
  __$AssessmentPositionContextCopyWithImpl(this._self, this._then);

  final _AssessmentPositionContext _self;
  final $Res Function(_AssessmentPositionContext) _then;

/// Create a copy of AssessmentPositionContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionId = freezed,Object? instrumentId = null,Object? state = null,Object? revision = freezed,Object? averageCost = freezed,Object? quantity = freezed,Object? openedOn = freezed,Object? economicsStatus = freezed,}) {
  return _then(_AssessmentPositionContext(
positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PositionState,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int?,averageCost: freezed == averageCost ? _self.averageCost : averageCost // ignore: cast_nullable_to_non_nullable
as MoneyAmount?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,economicsStatus: freezed == economicsStatus ? _self.economicsStatus : economicsStatus // ignore: cast_nullable_to_non_nullable
as EconomicsStatus?,
  ));
}

/// Create a copy of AssessmentPositionContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyAmountCopyWith<$Res>? get averageCost {
    if (_self.averageCost == null) {
    return null;
  }

  return $MoneyAmountCopyWith<$Res>(_self.averageCost!, (value) {
    return _then(_self.copyWith(averageCost: value));
  });
}
}

/// @nodoc
mixin _$NumericProjection {

 String get id; String get assessmentId; String get instrumentId; String get evidenceSnapshotId; String get anchorTime; String get anchorPriceMetricId; String get targetSessionDate; ProjectionKind get kind; String get method; String get methodVersion; List<String> get inputMetricIds; List<String> get assumptionIds; double? get lower; double? get central; double? get upper; String get currency; String get adjustmentBasis; CalibrationEvidence? get calibration; String? get validUntil; List<String> get limitations;
/// Create a copy of NumericProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NumericProjectionCopyWith<NumericProjection> get copyWith => _$NumericProjectionCopyWithImpl<NumericProjection>(this as NumericProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NumericProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.assessmentId, assessmentId) || other.assessmentId == assessmentId)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.anchorTime, anchorTime) || other.anchorTime == anchorTime)&&(identical(other.anchorPriceMetricId, anchorPriceMetricId) || other.anchorPriceMetricId == anchorPriceMetricId)&&(identical(other.targetSessionDate, targetSessionDate) || other.targetSessionDate == targetSessionDate)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.method, method) || other.method == method)&&(identical(other.methodVersion, methodVersion) || other.methodVersion == methodVersion)&&const DeepCollectionEquality().equals(other.inputMetricIds, inputMetricIds)&&const DeepCollectionEquality().equals(other.assumptionIds, assumptionIds)&&(identical(other.lower, lower) || other.lower == lower)&&(identical(other.central, central) || other.central == central)&&(identical(other.upper, upper) || other.upper == upper)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.adjustmentBasis, adjustmentBasis) || other.adjustmentBasis == adjustmentBasis)&&(identical(other.calibration, calibration) || other.calibration == calibration)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&const DeepCollectionEquality().equals(other.limitations, limitations));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,assessmentId,instrumentId,evidenceSnapshotId,anchorTime,anchorPriceMetricId,targetSessionDate,kind,method,methodVersion,const DeepCollectionEquality().hash(inputMetricIds),const DeepCollectionEquality().hash(assumptionIds),lower,central,upper,currency,adjustmentBasis,calibration,validUntil,const DeepCollectionEquality().hash(limitations)]);

@override
String toString() {
  return 'NumericProjection(id: $id, assessmentId: $assessmentId, instrumentId: $instrumentId, evidenceSnapshotId: $evidenceSnapshotId, anchorTime: $anchorTime, anchorPriceMetricId: $anchorPriceMetricId, targetSessionDate: $targetSessionDate, kind: $kind, method: $method, methodVersion: $methodVersion, inputMetricIds: $inputMetricIds, assumptionIds: $assumptionIds, lower: $lower, central: $central, upper: $upper, currency: $currency, adjustmentBasis: $adjustmentBasis, calibration: $calibration, validUntil: $validUntil, limitations: $limitations)';
}


}

/// @nodoc
abstract mixin class $NumericProjectionCopyWith<$Res>  {
  factory $NumericProjectionCopyWith(NumericProjection value, $Res Function(NumericProjection) _then) = _$NumericProjectionCopyWithImpl;
@useResult
$Res call({
 String id, String assessmentId, String instrumentId, String evidenceSnapshotId, String anchorTime, String anchorPriceMetricId, String targetSessionDate, ProjectionKind kind, String method, String methodVersion, List<String> inputMetricIds, List<String> assumptionIds, double? lower, double? central, double? upper, String currency, String adjustmentBasis, CalibrationEvidence? calibration, String? validUntil, List<String> limitations
});


$CalibrationEvidenceCopyWith<$Res>? get calibration;

}
/// @nodoc
class _$NumericProjectionCopyWithImpl<$Res>
    implements $NumericProjectionCopyWith<$Res> {
  _$NumericProjectionCopyWithImpl(this._self, this._then);

  final NumericProjection _self;
  final $Res Function(NumericProjection) _then;

/// Create a copy of NumericProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? assessmentId = null,Object? instrumentId = null,Object? evidenceSnapshotId = null,Object? anchorTime = null,Object? anchorPriceMetricId = null,Object? targetSessionDate = null,Object? kind = null,Object? method = null,Object? methodVersion = null,Object? inputMetricIds = null,Object? assumptionIds = null,Object? lower = freezed,Object? central = freezed,Object? upper = freezed,Object? currency = null,Object? adjustmentBasis = null,Object? calibration = freezed,Object? validUntil = freezed,Object? limitations = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assessmentId: null == assessmentId ? _self.assessmentId : assessmentId // ignore: cast_nullable_to_non_nullable
as String,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,evidenceSnapshotId: null == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String,anchorTime: null == anchorTime ? _self.anchorTime : anchorTime // ignore: cast_nullable_to_non_nullable
as String,anchorPriceMetricId: null == anchorPriceMetricId ? _self.anchorPriceMetricId : anchorPriceMetricId // ignore: cast_nullable_to_non_nullable
as String,targetSessionDate: null == targetSessionDate ? _self.targetSessionDate : targetSessionDate // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProjectionKind,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,methodVersion: null == methodVersion ? _self.methodVersion : methodVersion // ignore: cast_nullable_to_non_nullable
as String,inputMetricIds: null == inputMetricIds ? _self.inputMetricIds : inputMetricIds // ignore: cast_nullable_to_non_nullable
as List<String>,assumptionIds: null == assumptionIds ? _self.assumptionIds : assumptionIds // ignore: cast_nullable_to_non_nullable
as List<String>,lower: freezed == lower ? _self.lower : lower // ignore: cast_nullable_to_non_nullable
as double?,central: freezed == central ? _self.central : central // ignore: cast_nullable_to_non_nullable
as double?,upper: freezed == upper ? _self.upper : upper // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,adjustmentBasis: null == adjustmentBasis ? _self.adjustmentBasis : adjustmentBasis // ignore: cast_nullable_to_non_nullable
as String,calibration: freezed == calibration ? _self.calibration : calibration // ignore: cast_nullable_to_non_nullable
as CalibrationEvidence?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,limitations: null == limitations ? _self.limitations : limitations // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of NumericProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalibrationEvidenceCopyWith<$Res>? get calibration {
    if (_self.calibration == null) {
    return null;
  }

  return $CalibrationEvidenceCopyWith<$Res>(_self.calibration!, (value) {
    return _then(_self.copyWith(calibration: value));
  });
}
}


/// Adds pattern-matching-related methods to [NumericProjection].
extension NumericProjectionPatterns on NumericProjection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NumericProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NumericProjection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NumericProjection value)  $default,){
final _that = this;
switch (_that) {
case _NumericProjection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NumericProjection value)?  $default,){
final _that = this;
switch (_that) {
case _NumericProjection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String assessmentId,  String instrumentId,  String evidenceSnapshotId,  String anchorTime,  String anchorPriceMetricId,  String targetSessionDate,  ProjectionKind kind,  String method,  String methodVersion,  List<String> inputMetricIds,  List<String> assumptionIds,  double? lower,  double? central,  double? upper,  String currency,  String adjustmentBasis,  CalibrationEvidence? calibration,  String? validUntil,  List<String> limitations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NumericProjection() when $default != null:
return $default(_that.id,_that.assessmentId,_that.instrumentId,_that.evidenceSnapshotId,_that.anchorTime,_that.anchorPriceMetricId,_that.targetSessionDate,_that.kind,_that.method,_that.methodVersion,_that.inputMetricIds,_that.assumptionIds,_that.lower,_that.central,_that.upper,_that.currency,_that.adjustmentBasis,_that.calibration,_that.validUntil,_that.limitations);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String assessmentId,  String instrumentId,  String evidenceSnapshotId,  String anchorTime,  String anchorPriceMetricId,  String targetSessionDate,  ProjectionKind kind,  String method,  String methodVersion,  List<String> inputMetricIds,  List<String> assumptionIds,  double? lower,  double? central,  double? upper,  String currency,  String adjustmentBasis,  CalibrationEvidence? calibration,  String? validUntil,  List<String> limitations)  $default,) {final _that = this;
switch (_that) {
case _NumericProjection():
return $default(_that.id,_that.assessmentId,_that.instrumentId,_that.evidenceSnapshotId,_that.anchorTime,_that.anchorPriceMetricId,_that.targetSessionDate,_that.kind,_that.method,_that.methodVersion,_that.inputMetricIds,_that.assumptionIds,_that.lower,_that.central,_that.upper,_that.currency,_that.adjustmentBasis,_that.calibration,_that.validUntil,_that.limitations);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String assessmentId,  String instrumentId,  String evidenceSnapshotId,  String anchorTime,  String anchorPriceMetricId,  String targetSessionDate,  ProjectionKind kind,  String method,  String methodVersion,  List<String> inputMetricIds,  List<String> assumptionIds,  double? lower,  double? central,  double? upper,  String currency,  String adjustmentBasis,  CalibrationEvidence? calibration,  String? validUntil,  List<String> limitations)?  $default,) {final _that = this;
switch (_that) {
case _NumericProjection() when $default != null:
return $default(_that.id,_that.assessmentId,_that.instrumentId,_that.evidenceSnapshotId,_that.anchorTime,_that.anchorPriceMetricId,_that.targetSessionDate,_that.kind,_that.method,_that.methodVersion,_that.inputMetricIds,_that.assumptionIds,_that.lower,_that.central,_that.upper,_that.currency,_that.adjustmentBasis,_that.calibration,_that.validUntil,_that.limitations);case _:
  return null;

}
}

}

/// @nodoc


class _NumericProjection implements NumericProjection {
  const _NumericProjection({required this.id, required this.assessmentId, required this.instrumentId, required this.evidenceSnapshotId, required this.anchorTime, required this.anchorPriceMetricId, required this.targetSessionDate, required this.kind, required this.method, required this.methodVersion, required final  List<String> inputMetricIds, required final  List<String> assumptionIds, required this.lower, required this.central, required this.upper, required this.currency, required this.adjustmentBasis, required this.calibration, required this.validUntil, required final  List<String> limitations}): _inputMetricIds = inputMetricIds,_assumptionIds = assumptionIds,_limitations = limitations;
  

@override final  String id;
@override final  String assessmentId;
@override final  String instrumentId;
@override final  String evidenceSnapshotId;
@override final  String anchorTime;
@override final  String anchorPriceMetricId;
@override final  String targetSessionDate;
@override final  ProjectionKind kind;
@override final  String method;
@override final  String methodVersion;
 final  List<String> _inputMetricIds;
@override List<String> get inputMetricIds {
  if (_inputMetricIds is EqualUnmodifiableListView) return _inputMetricIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputMetricIds);
}

 final  List<String> _assumptionIds;
@override List<String> get assumptionIds {
  if (_assumptionIds is EqualUnmodifiableListView) return _assumptionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assumptionIds);
}

@override final  double? lower;
@override final  double? central;
@override final  double? upper;
@override final  String currency;
@override final  String adjustmentBasis;
@override final  CalibrationEvidence? calibration;
@override final  String? validUntil;
 final  List<String> _limitations;
@override List<String> get limitations {
  if (_limitations is EqualUnmodifiableListView) return _limitations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_limitations);
}


/// Create a copy of NumericProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NumericProjectionCopyWith<_NumericProjection> get copyWith => __$NumericProjectionCopyWithImpl<_NumericProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NumericProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.assessmentId, assessmentId) || other.assessmentId == assessmentId)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.anchorTime, anchorTime) || other.anchorTime == anchorTime)&&(identical(other.anchorPriceMetricId, anchorPriceMetricId) || other.anchorPriceMetricId == anchorPriceMetricId)&&(identical(other.targetSessionDate, targetSessionDate) || other.targetSessionDate == targetSessionDate)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.method, method) || other.method == method)&&(identical(other.methodVersion, methodVersion) || other.methodVersion == methodVersion)&&const DeepCollectionEquality().equals(other._inputMetricIds, _inputMetricIds)&&const DeepCollectionEquality().equals(other._assumptionIds, _assumptionIds)&&(identical(other.lower, lower) || other.lower == lower)&&(identical(other.central, central) || other.central == central)&&(identical(other.upper, upper) || other.upper == upper)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.adjustmentBasis, adjustmentBasis) || other.adjustmentBasis == adjustmentBasis)&&(identical(other.calibration, calibration) || other.calibration == calibration)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&const DeepCollectionEquality().equals(other._limitations, _limitations));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,assessmentId,instrumentId,evidenceSnapshotId,anchorTime,anchorPriceMetricId,targetSessionDate,kind,method,methodVersion,const DeepCollectionEquality().hash(_inputMetricIds),const DeepCollectionEquality().hash(_assumptionIds),lower,central,upper,currency,adjustmentBasis,calibration,validUntil,const DeepCollectionEquality().hash(_limitations)]);

@override
String toString() {
  return 'NumericProjection(id: $id, assessmentId: $assessmentId, instrumentId: $instrumentId, evidenceSnapshotId: $evidenceSnapshotId, anchorTime: $anchorTime, anchorPriceMetricId: $anchorPriceMetricId, targetSessionDate: $targetSessionDate, kind: $kind, method: $method, methodVersion: $methodVersion, inputMetricIds: $inputMetricIds, assumptionIds: $assumptionIds, lower: $lower, central: $central, upper: $upper, currency: $currency, adjustmentBasis: $adjustmentBasis, calibration: $calibration, validUntil: $validUntil, limitations: $limitations)';
}


}

/// @nodoc
abstract mixin class _$NumericProjectionCopyWith<$Res> implements $NumericProjectionCopyWith<$Res> {
  factory _$NumericProjectionCopyWith(_NumericProjection value, $Res Function(_NumericProjection) _then) = __$NumericProjectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String assessmentId, String instrumentId, String evidenceSnapshotId, String anchorTime, String anchorPriceMetricId, String targetSessionDate, ProjectionKind kind, String method, String methodVersion, List<String> inputMetricIds, List<String> assumptionIds, double? lower, double? central, double? upper, String currency, String adjustmentBasis, CalibrationEvidence? calibration, String? validUntil, List<String> limitations
});


@override $CalibrationEvidenceCopyWith<$Res>? get calibration;

}
/// @nodoc
class __$NumericProjectionCopyWithImpl<$Res>
    implements _$NumericProjectionCopyWith<$Res> {
  __$NumericProjectionCopyWithImpl(this._self, this._then);

  final _NumericProjection _self;
  final $Res Function(_NumericProjection) _then;

/// Create a copy of NumericProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assessmentId = null,Object? instrumentId = null,Object? evidenceSnapshotId = null,Object? anchorTime = null,Object? anchorPriceMetricId = null,Object? targetSessionDate = null,Object? kind = null,Object? method = null,Object? methodVersion = null,Object? inputMetricIds = null,Object? assumptionIds = null,Object? lower = freezed,Object? central = freezed,Object? upper = freezed,Object? currency = null,Object? adjustmentBasis = null,Object? calibration = freezed,Object? validUntil = freezed,Object? limitations = null,}) {
  return _then(_NumericProjection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assessmentId: null == assessmentId ? _self.assessmentId : assessmentId // ignore: cast_nullable_to_non_nullable
as String,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,evidenceSnapshotId: null == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String,anchorTime: null == anchorTime ? _self.anchorTime : anchorTime // ignore: cast_nullable_to_non_nullable
as String,anchorPriceMetricId: null == anchorPriceMetricId ? _self.anchorPriceMetricId : anchorPriceMetricId // ignore: cast_nullable_to_non_nullable
as String,targetSessionDate: null == targetSessionDate ? _self.targetSessionDate : targetSessionDate // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ProjectionKind,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,methodVersion: null == methodVersion ? _self.methodVersion : methodVersion // ignore: cast_nullable_to_non_nullable
as String,inputMetricIds: null == inputMetricIds ? _self._inputMetricIds : inputMetricIds // ignore: cast_nullable_to_non_nullable
as List<String>,assumptionIds: null == assumptionIds ? _self._assumptionIds : assumptionIds // ignore: cast_nullable_to_non_nullable
as List<String>,lower: freezed == lower ? _self.lower : lower // ignore: cast_nullable_to_non_nullable
as double?,central: freezed == central ? _self.central : central // ignore: cast_nullable_to_non_nullable
as double?,upper: freezed == upper ? _self.upper : upper // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,adjustmentBasis: null == adjustmentBasis ? _self.adjustmentBasis : adjustmentBasis // ignore: cast_nullable_to_non_nullable
as String,calibration: freezed == calibration ? _self.calibration : calibration // ignore: cast_nullable_to_non_nullable
as CalibrationEvidence?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,limitations: null == limitations ? _self._limitations : limitations // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of NumericProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalibrationEvidenceCopyWith<$Res>? get calibration {
    if (_self.calibration == null) {
    return null;
  }

  return $CalibrationEvidenceCopyWith<$Res>(_self.calibration!, (value) {
    return _then(_self.copyWith(calibration: value));
  });
}
}

/// @nodoc
mixin _$CalibrationEvidence {

 String get modelVersion; String get heldOutEvaluation; String get coverageDefinition; List<String> get validationEvidenceIds;
/// Create a copy of CalibrationEvidence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalibrationEvidenceCopyWith<CalibrationEvidence> get copyWith => _$CalibrationEvidenceCopyWithImpl<CalibrationEvidence>(this as CalibrationEvidence, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalibrationEvidence&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.heldOutEvaluation, heldOutEvaluation) || other.heldOutEvaluation == heldOutEvaluation)&&(identical(other.coverageDefinition, coverageDefinition) || other.coverageDefinition == coverageDefinition)&&const DeepCollectionEquality().equals(other.validationEvidenceIds, validationEvidenceIds));
}


@override
int get hashCode => Object.hash(runtimeType,modelVersion,heldOutEvaluation,coverageDefinition,const DeepCollectionEquality().hash(validationEvidenceIds));

@override
String toString() {
  return 'CalibrationEvidence(modelVersion: $modelVersion, heldOutEvaluation: $heldOutEvaluation, coverageDefinition: $coverageDefinition, validationEvidenceIds: $validationEvidenceIds)';
}


}

/// @nodoc
abstract mixin class $CalibrationEvidenceCopyWith<$Res>  {
  factory $CalibrationEvidenceCopyWith(CalibrationEvidence value, $Res Function(CalibrationEvidence) _then) = _$CalibrationEvidenceCopyWithImpl;
@useResult
$Res call({
 String modelVersion, String heldOutEvaluation, String coverageDefinition, List<String> validationEvidenceIds
});




}
/// @nodoc
class _$CalibrationEvidenceCopyWithImpl<$Res>
    implements $CalibrationEvidenceCopyWith<$Res> {
  _$CalibrationEvidenceCopyWithImpl(this._self, this._then);

  final CalibrationEvidence _self;
  final $Res Function(CalibrationEvidence) _then;

/// Create a copy of CalibrationEvidence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelVersion = null,Object? heldOutEvaluation = null,Object? coverageDefinition = null,Object? validationEvidenceIds = null,}) {
  return _then(_self.copyWith(
modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,heldOutEvaluation: null == heldOutEvaluation ? _self.heldOutEvaluation : heldOutEvaluation // ignore: cast_nullable_to_non_nullable
as String,coverageDefinition: null == coverageDefinition ? _self.coverageDefinition : coverageDefinition // ignore: cast_nullable_to_non_nullable
as String,validationEvidenceIds: null == validationEvidenceIds ? _self.validationEvidenceIds : validationEvidenceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CalibrationEvidence].
extension CalibrationEvidencePatterns on CalibrationEvidence {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalibrationEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalibrationEvidence() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalibrationEvidence value)  $default,){
final _that = this;
switch (_that) {
case _CalibrationEvidence():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalibrationEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _CalibrationEvidence() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String modelVersion,  String heldOutEvaluation,  String coverageDefinition,  List<String> validationEvidenceIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalibrationEvidence() when $default != null:
return $default(_that.modelVersion,_that.heldOutEvaluation,_that.coverageDefinition,_that.validationEvidenceIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String modelVersion,  String heldOutEvaluation,  String coverageDefinition,  List<String> validationEvidenceIds)  $default,) {final _that = this;
switch (_that) {
case _CalibrationEvidence():
return $default(_that.modelVersion,_that.heldOutEvaluation,_that.coverageDefinition,_that.validationEvidenceIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String modelVersion,  String heldOutEvaluation,  String coverageDefinition,  List<String> validationEvidenceIds)?  $default,) {final _that = this;
switch (_that) {
case _CalibrationEvidence() when $default != null:
return $default(_that.modelVersion,_that.heldOutEvaluation,_that.coverageDefinition,_that.validationEvidenceIds);case _:
  return null;

}
}

}

/// @nodoc


class _CalibrationEvidence implements CalibrationEvidence {
  const _CalibrationEvidence({required this.modelVersion, required this.heldOutEvaluation, required this.coverageDefinition, required final  List<String> validationEvidenceIds}): _validationEvidenceIds = validationEvidenceIds;
  

@override final  String modelVersion;
@override final  String heldOutEvaluation;
@override final  String coverageDefinition;
 final  List<String> _validationEvidenceIds;
@override List<String> get validationEvidenceIds {
  if (_validationEvidenceIds is EqualUnmodifiableListView) return _validationEvidenceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_validationEvidenceIds);
}


/// Create a copy of CalibrationEvidence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalibrationEvidenceCopyWith<_CalibrationEvidence> get copyWith => __$CalibrationEvidenceCopyWithImpl<_CalibrationEvidence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalibrationEvidence&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.heldOutEvaluation, heldOutEvaluation) || other.heldOutEvaluation == heldOutEvaluation)&&(identical(other.coverageDefinition, coverageDefinition) || other.coverageDefinition == coverageDefinition)&&const DeepCollectionEquality().equals(other._validationEvidenceIds, _validationEvidenceIds));
}


@override
int get hashCode => Object.hash(runtimeType,modelVersion,heldOutEvaluation,coverageDefinition,const DeepCollectionEquality().hash(_validationEvidenceIds));

@override
String toString() {
  return 'CalibrationEvidence(modelVersion: $modelVersion, heldOutEvaluation: $heldOutEvaluation, coverageDefinition: $coverageDefinition, validationEvidenceIds: $validationEvidenceIds)';
}


}

/// @nodoc
abstract mixin class _$CalibrationEvidenceCopyWith<$Res> implements $CalibrationEvidenceCopyWith<$Res> {
  factory _$CalibrationEvidenceCopyWith(_CalibrationEvidence value, $Res Function(_CalibrationEvidence) _then) = __$CalibrationEvidenceCopyWithImpl;
@override @useResult
$Res call({
 String modelVersion, String heldOutEvaluation, String coverageDefinition, List<String> validationEvidenceIds
});




}
/// @nodoc
class __$CalibrationEvidenceCopyWithImpl<$Res>
    implements _$CalibrationEvidenceCopyWith<$Res> {
  __$CalibrationEvidenceCopyWithImpl(this._self, this._then);

  final _CalibrationEvidence _self;
  final $Res Function(_CalibrationEvidence) _then;

/// Create a copy of CalibrationEvidence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelVersion = null,Object? heldOutEvaluation = null,Object? coverageDefinition = null,Object? validationEvidenceIds = null,}) {
  return _then(_CalibrationEvidence(
modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,heldOutEvaluation: null == heldOutEvaluation ? _self.heldOutEvaluation : heldOutEvaluation // ignore: cast_nullable_to_non_nullable
as String,coverageDefinition: null == coverageDefinition ? _self.coverageDefinition : coverageDefinition // ignore: cast_nullable_to_non_nullable
as String,validationEvidenceIds: null == validationEvidenceIds ? _self._validationEvidenceIds : validationEvidenceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$Outlook {

 int get horizonMonths; String get calendarTargetDate; String get evaluationSessionDate; OutlookDirection get direction; List<Claim> get baseCase; List<Claim> get upsideCase; List<Claim> get downsideCase; List<Claim> get catalysts; List<Claim> get invalidators; NumericProjection? get numericProjection; List<String> get dataLimitations;
/// Create a copy of Outlook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutlookCopyWith<Outlook> get copyWith => _$OutlookCopyWithImpl<Outlook>(this as Outlook, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Outlook&&(identical(other.horizonMonths, horizonMonths) || other.horizonMonths == horizonMonths)&&(identical(other.calendarTargetDate, calendarTargetDate) || other.calendarTargetDate == calendarTargetDate)&&(identical(other.evaluationSessionDate, evaluationSessionDate) || other.evaluationSessionDate == evaluationSessionDate)&&(identical(other.direction, direction) || other.direction == direction)&&const DeepCollectionEquality().equals(other.baseCase, baseCase)&&const DeepCollectionEquality().equals(other.upsideCase, upsideCase)&&const DeepCollectionEquality().equals(other.downsideCase, downsideCase)&&const DeepCollectionEquality().equals(other.catalysts, catalysts)&&const DeepCollectionEquality().equals(other.invalidators, invalidators)&&(identical(other.numericProjection, numericProjection) || other.numericProjection == numericProjection)&&const DeepCollectionEquality().equals(other.dataLimitations, dataLimitations));
}


@override
int get hashCode => Object.hash(runtimeType,horizonMonths,calendarTargetDate,evaluationSessionDate,direction,const DeepCollectionEquality().hash(baseCase),const DeepCollectionEquality().hash(upsideCase),const DeepCollectionEquality().hash(downsideCase),const DeepCollectionEquality().hash(catalysts),const DeepCollectionEquality().hash(invalidators),numericProjection,const DeepCollectionEquality().hash(dataLimitations));

@override
String toString() {
  return 'Outlook(horizonMonths: $horizonMonths, calendarTargetDate: $calendarTargetDate, evaluationSessionDate: $evaluationSessionDate, direction: $direction, baseCase: $baseCase, upsideCase: $upsideCase, downsideCase: $downsideCase, catalysts: $catalysts, invalidators: $invalidators, numericProjection: $numericProjection, dataLimitations: $dataLimitations)';
}


}

/// @nodoc
abstract mixin class $OutlookCopyWith<$Res>  {
  factory $OutlookCopyWith(Outlook value, $Res Function(Outlook) _then) = _$OutlookCopyWithImpl;
@useResult
$Res call({
 int horizonMonths, String calendarTargetDate, String evaluationSessionDate, OutlookDirection direction, List<Claim> baseCase, List<Claim> upsideCase, List<Claim> downsideCase, List<Claim> catalysts, List<Claim> invalidators, NumericProjection? numericProjection, List<String> dataLimitations
});


$NumericProjectionCopyWith<$Res>? get numericProjection;

}
/// @nodoc
class _$OutlookCopyWithImpl<$Res>
    implements $OutlookCopyWith<$Res> {
  _$OutlookCopyWithImpl(this._self, this._then);

  final Outlook _self;
  final $Res Function(Outlook) _then;

/// Create a copy of Outlook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? horizonMonths = null,Object? calendarTargetDate = null,Object? evaluationSessionDate = null,Object? direction = null,Object? baseCase = null,Object? upsideCase = null,Object? downsideCase = null,Object? catalysts = null,Object? invalidators = null,Object? numericProjection = freezed,Object? dataLimitations = null,}) {
  return _then(_self.copyWith(
horizonMonths: null == horizonMonths ? _self.horizonMonths : horizonMonths // ignore: cast_nullable_to_non_nullable
as int,calendarTargetDate: null == calendarTargetDate ? _self.calendarTargetDate : calendarTargetDate // ignore: cast_nullable_to_non_nullable
as String,evaluationSessionDate: null == evaluationSessionDate ? _self.evaluationSessionDate : evaluationSessionDate // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as OutlookDirection,baseCase: null == baseCase ? _self.baseCase : baseCase // ignore: cast_nullable_to_non_nullable
as List<Claim>,upsideCase: null == upsideCase ? _self.upsideCase : upsideCase // ignore: cast_nullable_to_non_nullable
as List<Claim>,downsideCase: null == downsideCase ? _self.downsideCase : downsideCase // ignore: cast_nullable_to_non_nullable
as List<Claim>,catalysts: null == catalysts ? _self.catalysts : catalysts // ignore: cast_nullable_to_non_nullable
as List<Claim>,invalidators: null == invalidators ? _self.invalidators : invalidators // ignore: cast_nullable_to_non_nullable
as List<Claim>,numericProjection: freezed == numericProjection ? _self.numericProjection : numericProjection // ignore: cast_nullable_to_non_nullable
as NumericProjection?,dataLimitations: null == dataLimitations ? _self.dataLimitations : dataLimitations // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of Outlook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NumericProjectionCopyWith<$Res>? get numericProjection {
    if (_self.numericProjection == null) {
    return null;
  }

  return $NumericProjectionCopyWith<$Res>(_self.numericProjection!, (value) {
    return _then(_self.copyWith(numericProjection: value));
  });
}
}


/// Adds pattern-matching-related methods to [Outlook].
extension OutlookPatterns on Outlook {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Outlook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Outlook() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Outlook value)  $default,){
final _that = this;
switch (_that) {
case _Outlook():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Outlook value)?  $default,){
final _that = this;
switch (_that) {
case _Outlook() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int horizonMonths,  String calendarTargetDate,  String evaluationSessionDate,  OutlookDirection direction,  List<Claim> baseCase,  List<Claim> upsideCase,  List<Claim> downsideCase,  List<Claim> catalysts,  List<Claim> invalidators,  NumericProjection? numericProjection,  List<String> dataLimitations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Outlook() when $default != null:
return $default(_that.horizonMonths,_that.calendarTargetDate,_that.evaluationSessionDate,_that.direction,_that.baseCase,_that.upsideCase,_that.downsideCase,_that.catalysts,_that.invalidators,_that.numericProjection,_that.dataLimitations);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int horizonMonths,  String calendarTargetDate,  String evaluationSessionDate,  OutlookDirection direction,  List<Claim> baseCase,  List<Claim> upsideCase,  List<Claim> downsideCase,  List<Claim> catalysts,  List<Claim> invalidators,  NumericProjection? numericProjection,  List<String> dataLimitations)  $default,) {final _that = this;
switch (_that) {
case _Outlook():
return $default(_that.horizonMonths,_that.calendarTargetDate,_that.evaluationSessionDate,_that.direction,_that.baseCase,_that.upsideCase,_that.downsideCase,_that.catalysts,_that.invalidators,_that.numericProjection,_that.dataLimitations);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int horizonMonths,  String calendarTargetDate,  String evaluationSessionDate,  OutlookDirection direction,  List<Claim> baseCase,  List<Claim> upsideCase,  List<Claim> downsideCase,  List<Claim> catalysts,  List<Claim> invalidators,  NumericProjection? numericProjection,  List<String> dataLimitations)?  $default,) {final _that = this;
switch (_that) {
case _Outlook() when $default != null:
return $default(_that.horizonMonths,_that.calendarTargetDate,_that.evaluationSessionDate,_that.direction,_that.baseCase,_that.upsideCase,_that.downsideCase,_that.catalysts,_that.invalidators,_that.numericProjection,_that.dataLimitations);case _:
  return null;

}
}

}

/// @nodoc


class _Outlook implements Outlook {
  const _Outlook({required this.horizonMonths, required this.calendarTargetDate, required this.evaluationSessionDate, required this.direction, required final  List<Claim> baseCase, required final  List<Claim> upsideCase, required final  List<Claim> downsideCase, required final  List<Claim> catalysts, required final  List<Claim> invalidators, required this.numericProjection, required final  List<String> dataLimitations}): _baseCase = baseCase,_upsideCase = upsideCase,_downsideCase = downsideCase,_catalysts = catalysts,_invalidators = invalidators,_dataLimitations = dataLimitations;
  

@override final  int horizonMonths;
@override final  String calendarTargetDate;
@override final  String evaluationSessionDate;
@override final  OutlookDirection direction;
 final  List<Claim> _baseCase;
@override List<Claim> get baseCase {
  if (_baseCase is EqualUnmodifiableListView) return _baseCase;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_baseCase);
}

 final  List<Claim> _upsideCase;
@override List<Claim> get upsideCase {
  if (_upsideCase is EqualUnmodifiableListView) return _upsideCase;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upsideCase);
}

 final  List<Claim> _downsideCase;
@override List<Claim> get downsideCase {
  if (_downsideCase is EqualUnmodifiableListView) return _downsideCase;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_downsideCase);
}

 final  List<Claim> _catalysts;
@override List<Claim> get catalysts {
  if (_catalysts is EqualUnmodifiableListView) return _catalysts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_catalysts);
}

 final  List<Claim> _invalidators;
@override List<Claim> get invalidators {
  if (_invalidators is EqualUnmodifiableListView) return _invalidators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invalidators);
}

@override final  NumericProjection? numericProjection;
 final  List<String> _dataLimitations;
@override List<String> get dataLimitations {
  if (_dataLimitations is EqualUnmodifiableListView) return _dataLimitations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dataLimitations);
}


/// Create a copy of Outlook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutlookCopyWith<_Outlook> get copyWith => __$OutlookCopyWithImpl<_Outlook>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Outlook&&(identical(other.horizonMonths, horizonMonths) || other.horizonMonths == horizonMonths)&&(identical(other.calendarTargetDate, calendarTargetDate) || other.calendarTargetDate == calendarTargetDate)&&(identical(other.evaluationSessionDate, evaluationSessionDate) || other.evaluationSessionDate == evaluationSessionDate)&&(identical(other.direction, direction) || other.direction == direction)&&const DeepCollectionEquality().equals(other._baseCase, _baseCase)&&const DeepCollectionEquality().equals(other._upsideCase, _upsideCase)&&const DeepCollectionEquality().equals(other._downsideCase, _downsideCase)&&const DeepCollectionEquality().equals(other._catalysts, _catalysts)&&const DeepCollectionEquality().equals(other._invalidators, _invalidators)&&(identical(other.numericProjection, numericProjection) || other.numericProjection == numericProjection)&&const DeepCollectionEquality().equals(other._dataLimitations, _dataLimitations));
}


@override
int get hashCode => Object.hash(runtimeType,horizonMonths,calendarTargetDate,evaluationSessionDate,direction,const DeepCollectionEquality().hash(_baseCase),const DeepCollectionEquality().hash(_upsideCase),const DeepCollectionEquality().hash(_downsideCase),const DeepCollectionEquality().hash(_catalysts),const DeepCollectionEquality().hash(_invalidators),numericProjection,const DeepCollectionEquality().hash(_dataLimitations));

@override
String toString() {
  return 'Outlook(horizonMonths: $horizonMonths, calendarTargetDate: $calendarTargetDate, evaluationSessionDate: $evaluationSessionDate, direction: $direction, baseCase: $baseCase, upsideCase: $upsideCase, downsideCase: $downsideCase, catalysts: $catalysts, invalidators: $invalidators, numericProjection: $numericProjection, dataLimitations: $dataLimitations)';
}


}

/// @nodoc
abstract mixin class _$OutlookCopyWith<$Res> implements $OutlookCopyWith<$Res> {
  factory _$OutlookCopyWith(_Outlook value, $Res Function(_Outlook) _then) = __$OutlookCopyWithImpl;
@override @useResult
$Res call({
 int horizonMonths, String calendarTargetDate, String evaluationSessionDate, OutlookDirection direction, List<Claim> baseCase, List<Claim> upsideCase, List<Claim> downsideCase, List<Claim> catalysts, List<Claim> invalidators, NumericProjection? numericProjection, List<String> dataLimitations
});


@override $NumericProjectionCopyWith<$Res>? get numericProjection;

}
/// @nodoc
class __$OutlookCopyWithImpl<$Res>
    implements _$OutlookCopyWith<$Res> {
  __$OutlookCopyWithImpl(this._self, this._then);

  final _Outlook _self;
  final $Res Function(_Outlook) _then;

/// Create a copy of Outlook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? horizonMonths = null,Object? calendarTargetDate = null,Object? evaluationSessionDate = null,Object? direction = null,Object? baseCase = null,Object? upsideCase = null,Object? downsideCase = null,Object? catalysts = null,Object? invalidators = null,Object? numericProjection = freezed,Object? dataLimitations = null,}) {
  return _then(_Outlook(
horizonMonths: null == horizonMonths ? _self.horizonMonths : horizonMonths // ignore: cast_nullable_to_non_nullable
as int,calendarTargetDate: null == calendarTargetDate ? _self.calendarTargetDate : calendarTargetDate // ignore: cast_nullable_to_non_nullable
as String,evaluationSessionDate: null == evaluationSessionDate ? _self.evaluationSessionDate : evaluationSessionDate // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as OutlookDirection,baseCase: null == baseCase ? _self._baseCase : baseCase // ignore: cast_nullable_to_non_nullable
as List<Claim>,upsideCase: null == upsideCase ? _self._upsideCase : upsideCase // ignore: cast_nullable_to_non_nullable
as List<Claim>,downsideCase: null == downsideCase ? _self._downsideCase : downsideCase // ignore: cast_nullable_to_non_nullable
as List<Claim>,catalysts: null == catalysts ? _self._catalysts : catalysts // ignore: cast_nullable_to_non_nullable
as List<Claim>,invalidators: null == invalidators ? _self._invalidators : invalidators // ignore: cast_nullable_to_non_nullable
as List<Claim>,numericProjection: freezed == numericProjection ? _self.numericProjection : numericProjection // ignore: cast_nullable_to_non_nullable
as NumericProjection?,dataLimitations: null == dataLimitations ? _self._dataLimitations : dataLimitations // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of Outlook
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NumericProjectionCopyWith<$Res>? get numericProjection {
    if (_self.numericProjection == null) {
    return null;
  }

  return $NumericProjectionCopyWith<$Res>(_self.numericProjection!, (value) {
    return _then(_self.copyWith(numericProjection: value));
  });
}
}

/// @nodoc
mixin _$Checkpoint {

 String get id; String get instrumentId; CheckpointKind get kind; String? get metricId; double? get fixedLevel; String get condition; String get createdAt; String get updatedAt; CheckpointStatus get status; String get reason; String get sourceAssessmentId;
/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckpointCopyWith<Checkpoint> get copyWith => _$CheckpointCopyWithImpl<Checkpoint>(this as Checkpoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Checkpoint&&(identical(other.id, id) || other.id == id)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.metricId, metricId) || other.metricId == metricId)&&(identical(other.fixedLevel, fixedLevel) || other.fixedLevel == fixedLevel)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sourceAssessmentId, sourceAssessmentId) || other.sourceAssessmentId == sourceAssessmentId));
}


@override
int get hashCode => Object.hash(runtimeType,id,instrumentId,kind,metricId,fixedLevel,condition,createdAt,updatedAt,status,reason,sourceAssessmentId);

@override
String toString() {
  return 'Checkpoint(id: $id, instrumentId: $instrumentId, kind: $kind, metricId: $metricId, fixedLevel: $fixedLevel, condition: $condition, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, reason: $reason, sourceAssessmentId: $sourceAssessmentId)';
}


}

/// @nodoc
abstract mixin class $CheckpointCopyWith<$Res>  {
  factory $CheckpointCopyWith(Checkpoint value, $Res Function(Checkpoint) _then) = _$CheckpointCopyWithImpl;
@useResult
$Res call({
 String id, String instrumentId, CheckpointKind kind, String? metricId, double? fixedLevel, String condition, String createdAt, String updatedAt, CheckpointStatus status, String reason, String sourceAssessmentId
});




}
/// @nodoc
class _$CheckpointCopyWithImpl<$Res>
    implements $CheckpointCopyWith<$Res> {
  _$CheckpointCopyWithImpl(this._self, this._then);

  final Checkpoint _self;
  final $Res Function(Checkpoint) _then;

/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? instrumentId = null,Object? kind = null,Object? metricId = freezed,Object? fixedLevel = freezed,Object? condition = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? reason = null,Object? sourceAssessmentId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CheckpointKind,metricId: freezed == metricId ? _self.metricId : metricId // ignore: cast_nullable_to_non_nullable
as String?,fixedLevel: freezed == fixedLevel ? _self.fixedLevel : fixedLevel // ignore: cast_nullable_to_non_nullable
as double?,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CheckpointStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,sourceAssessmentId: null == sourceAssessmentId ? _self.sourceAssessmentId : sourceAssessmentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Checkpoint].
extension CheckpointPatterns on Checkpoint {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Checkpoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Checkpoint value)  $default,){
final _that = this;
switch (_that) {
case _Checkpoint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Checkpoint value)?  $default,){
final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String instrumentId,  CheckpointKind kind,  String? metricId,  double? fixedLevel,  String condition,  String createdAt,  String updatedAt,  CheckpointStatus status,  String reason,  String sourceAssessmentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
return $default(_that.id,_that.instrumentId,_that.kind,_that.metricId,_that.fixedLevel,_that.condition,_that.createdAt,_that.updatedAt,_that.status,_that.reason,_that.sourceAssessmentId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String instrumentId,  CheckpointKind kind,  String? metricId,  double? fixedLevel,  String condition,  String createdAt,  String updatedAt,  CheckpointStatus status,  String reason,  String sourceAssessmentId)  $default,) {final _that = this;
switch (_that) {
case _Checkpoint():
return $default(_that.id,_that.instrumentId,_that.kind,_that.metricId,_that.fixedLevel,_that.condition,_that.createdAt,_that.updatedAt,_that.status,_that.reason,_that.sourceAssessmentId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String instrumentId,  CheckpointKind kind,  String? metricId,  double? fixedLevel,  String condition,  String createdAt,  String updatedAt,  CheckpointStatus status,  String reason,  String sourceAssessmentId)?  $default,) {final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
return $default(_that.id,_that.instrumentId,_that.kind,_that.metricId,_that.fixedLevel,_that.condition,_that.createdAt,_that.updatedAt,_that.status,_that.reason,_that.sourceAssessmentId);case _:
  return null;

}
}

}

/// @nodoc


class _Checkpoint implements Checkpoint {
  const _Checkpoint({required this.id, required this.instrumentId, required this.kind, required this.metricId, required this.fixedLevel, required this.condition, required this.createdAt, required this.updatedAt, required this.status, required this.reason, required this.sourceAssessmentId});
  

@override final  String id;
@override final  String instrumentId;
@override final  CheckpointKind kind;
@override final  String? metricId;
@override final  double? fixedLevel;
@override final  String condition;
@override final  String createdAt;
@override final  String updatedAt;
@override final  CheckpointStatus status;
@override final  String reason;
@override final  String sourceAssessmentId;

/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckpointCopyWith<_Checkpoint> get copyWith => __$CheckpointCopyWithImpl<_Checkpoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Checkpoint&&(identical(other.id, id) || other.id == id)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.metricId, metricId) || other.metricId == metricId)&&(identical(other.fixedLevel, fixedLevel) || other.fixedLevel == fixedLevel)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sourceAssessmentId, sourceAssessmentId) || other.sourceAssessmentId == sourceAssessmentId));
}


@override
int get hashCode => Object.hash(runtimeType,id,instrumentId,kind,metricId,fixedLevel,condition,createdAt,updatedAt,status,reason,sourceAssessmentId);

@override
String toString() {
  return 'Checkpoint(id: $id, instrumentId: $instrumentId, kind: $kind, metricId: $metricId, fixedLevel: $fixedLevel, condition: $condition, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, reason: $reason, sourceAssessmentId: $sourceAssessmentId)';
}


}

/// @nodoc
abstract mixin class _$CheckpointCopyWith<$Res> implements $CheckpointCopyWith<$Res> {
  factory _$CheckpointCopyWith(_Checkpoint value, $Res Function(_Checkpoint) _then) = __$CheckpointCopyWithImpl;
@override @useResult
$Res call({
 String id, String instrumentId, CheckpointKind kind, String? metricId, double? fixedLevel, String condition, String createdAt, String updatedAt, CheckpointStatus status, String reason, String sourceAssessmentId
});




}
/// @nodoc
class __$CheckpointCopyWithImpl<$Res>
    implements _$CheckpointCopyWith<$Res> {
  __$CheckpointCopyWithImpl(this._self, this._then);

  final _Checkpoint _self;
  final $Res Function(_Checkpoint) _then;

/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? instrumentId = null,Object? kind = null,Object? metricId = freezed,Object? fixedLevel = freezed,Object? condition = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? reason = null,Object? sourceAssessmentId = null,}) {
  return _then(_Checkpoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CheckpointKind,metricId: freezed == metricId ? _self.metricId : metricId // ignore: cast_nullable_to_non_nullable
as String?,fixedLevel: freezed == fixedLevel ? _self.fixedLevel : fixedLevel // ignore: cast_nullable_to_non_nullable
as double?,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CheckpointStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,sourceAssessmentId: null == sourceAssessmentId ? _self.sourceAssessmentId : sourceAssessmentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ThesisChange {

 String get component; ThesisChangeStatus get status; String get reason; List<String> get evidenceIds;
/// Create a copy of ThesisChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThesisChangeCopyWith<ThesisChange> get copyWith => _$ThesisChangeCopyWithImpl<ThesisChange>(this as ThesisChange, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThesisChange&&(identical(other.component, component) || other.component == component)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.evidenceIds, evidenceIds));
}


@override
int get hashCode => Object.hash(runtimeType,component,status,reason,const DeepCollectionEquality().hash(evidenceIds));

@override
String toString() {
  return 'ThesisChange(component: $component, status: $status, reason: $reason, evidenceIds: $evidenceIds)';
}


}

/// @nodoc
abstract mixin class $ThesisChangeCopyWith<$Res>  {
  factory $ThesisChangeCopyWith(ThesisChange value, $Res Function(ThesisChange) _then) = _$ThesisChangeCopyWithImpl;
@useResult
$Res call({
 String component, ThesisChangeStatus status, String reason, List<String> evidenceIds
});




}
/// @nodoc
class _$ThesisChangeCopyWithImpl<$Res>
    implements $ThesisChangeCopyWith<$Res> {
  _$ThesisChangeCopyWithImpl(this._self, this._then);

  final ThesisChange _self;
  final $Res Function(ThesisChange) _then;

/// Create a copy of ThesisChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? component = null,Object? status = null,Object? reason = null,Object? evidenceIds = null,}) {
  return _then(_self.copyWith(
component: null == component ? _self.component : component // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ThesisChangeStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,evidenceIds: null == evidenceIds ? _self.evidenceIds : evidenceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ThesisChange].
extension ThesisChangePatterns on ThesisChange {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThesisChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThesisChange() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThesisChange value)  $default,){
final _that = this;
switch (_that) {
case _ThesisChange():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThesisChange value)?  $default,){
final _that = this;
switch (_that) {
case _ThesisChange() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String component,  ThesisChangeStatus status,  String reason,  List<String> evidenceIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThesisChange() when $default != null:
return $default(_that.component,_that.status,_that.reason,_that.evidenceIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String component,  ThesisChangeStatus status,  String reason,  List<String> evidenceIds)  $default,) {final _that = this;
switch (_that) {
case _ThesisChange():
return $default(_that.component,_that.status,_that.reason,_that.evidenceIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String component,  ThesisChangeStatus status,  String reason,  List<String> evidenceIds)?  $default,) {final _that = this;
switch (_that) {
case _ThesisChange() when $default != null:
return $default(_that.component,_that.status,_that.reason,_that.evidenceIds);case _:
  return null;

}
}

}

/// @nodoc


class _ThesisChange implements ThesisChange {
  const _ThesisChange({required this.component, required this.status, required this.reason, required final  List<String> evidenceIds}): _evidenceIds = evidenceIds;
  

@override final  String component;
@override final  ThesisChangeStatus status;
@override final  String reason;
 final  List<String> _evidenceIds;
@override List<String> get evidenceIds {
  if (_evidenceIds is EqualUnmodifiableListView) return _evidenceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evidenceIds);
}


/// Create a copy of ThesisChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThesisChangeCopyWith<_ThesisChange> get copyWith => __$ThesisChangeCopyWithImpl<_ThesisChange>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThesisChange&&(identical(other.component, component) || other.component == component)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._evidenceIds, _evidenceIds));
}


@override
int get hashCode => Object.hash(runtimeType,component,status,reason,const DeepCollectionEquality().hash(_evidenceIds));

@override
String toString() {
  return 'ThesisChange(component: $component, status: $status, reason: $reason, evidenceIds: $evidenceIds)';
}


}

/// @nodoc
abstract mixin class _$ThesisChangeCopyWith<$Res> implements $ThesisChangeCopyWith<$Res> {
  factory _$ThesisChangeCopyWith(_ThesisChange value, $Res Function(_ThesisChange) _then) = __$ThesisChangeCopyWithImpl;
@override @useResult
$Res call({
 String component, ThesisChangeStatus status, String reason, List<String> evidenceIds
});




}
/// @nodoc
class __$ThesisChangeCopyWithImpl<$Res>
    implements _$ThesisChangeCopyWith<$Res> {
  __$ThesisChangeCopyWithImpl(this._self, this._then);

  final _ThesisChange _self;
  final $Res Function(_ThesisChange) _then;

/// Create a copy of ThesisChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? component = null,Object? status = null,Object? reason = null,Object? evidenceIds = null,}) {
  return _then(_ThesisChange(
component: null == component ? _self.component : component // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ThesisChangeStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,evidenceIds: null == evidenceIds ? _self._evidenceIds : evidenceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$ChangesSincePrevious {

 String? get previousAssessmentId; String? get previousSessionAsOf; List<String> get missingReportSessions; List<ThesisChange> get thesisChanges; List<String> get checkpointChangeIds;
/// Create a copy of ChangesSincePrevious
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangesSincePreviousCopyWith<ChangesSincePrevious> get copyWith => _$ChangesSincePreviousCopyWithImpl<ChangesSincePrevious>(this as ChangesSincePrevious, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangesSincePrevious&&(identical(other.previousAssessmentId, previousAssessmentId) || other.previousAssessmentId == previousAssessmentId)&&(identical(other.previousSessionAsOf, previousSessionAsOf) || other.previousSessionAsOf == previousSessionAsOf)&&const DeepCollectionEquality().equals(other.missingReportSessions, missingReportSessions)&&const DeepCollectionEquality().equals(other.thesisChanges, thesisChanges)&&const DeepCollectionEquality().equals(other.checkpointChangeIds, checkpointChangeIds));
}


@override
int get hashCode => Object.hash(runtimeType,previousAssessmentId,previousSessionAsOf,const DeepCollectionEquality().hash(missingReportSessions),const DeepCollectionEquality().hash(thesisChanges),const DeepCollectionEquality().hash(checkpointChangeIds));

@override
String toString() {
  return 'ChangesSincePrevious(previousAssessmentId: $previousAssessmentId, previousSessionAsOf: $previousSessionAsOf, missingReportSessions: $missingReportSessions, thesisChanges: $thesisChanges, checkpointChangeIds: $checkpointChangeIds)';
}


}

/// @nodoc
abstract mixin class $ChangesSincePreviousCopyWith<$Res>  {
  factory $ChangesSincePreviousCopyWith(ChangesSincePrevious value, $Res Function(ChangesSincePrevious) _then) = _$ChangesSincePreviousCopyWithImpl;
@useResult
$Res call({
 String? previousAssessmentId, String? previousSessionAsOf, List<String> missingReportSessions, List<ThesisChange> thesisChanges, List<String> checkpointChangeIds
});




}
/// @nodoc
class _$ChangesSincePreviousCopyWithImpl<$Res>
    implements $ChangesSincePreviousCopyWith<$Res> {
  _$ChangesSincePreviousCopyWithImpl(this._self, this._then);

  final ChangesSincePrevious _self;
  final $Res Function(ChangesSincePrevious) _then;

/// Create a copy of ChangesSincePrevious
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? previousAssessmentId = freezed,Object? previousSessionAsOf = freezed,Object? missingReportSessions = null,Object? thesisChanges = null,Object? checkpointChangeIds = null,}) {
  return _then(_self.copyWith(
previousAssessmentId: freezed == previousAssessmentId ? _self.previousAssessmentId : previousAssessmentId // ignore: cast_nullable_to_non_nullable
as String?,previousSessionAsOf: freezed == previousSessionAsOf ? _self.previousSessionAsOf : previousSessionAsOf // ignore: cast_nullable_to_non_nullable
as String?,missingReportSessions: null == missingReportSessions ? _self.missingReportSessions : missingReportSessions // ignore: cast_nullable_to_non_nullable
as List<String>,thesisChanges: null == thesisChanges ? _self.thesisChanges : thesisChanges // ignore: cast_nullable_to_non_nullable
as List<ThesisChange>,checkpointChangeIds: null == checkpointChangeIds ? _self.checkpointChangeIds : checkpointChangeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangesSincePrevious].
extension ChangesSincePreviousPatterns on ChangesSincePrevious {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangesSincePrevious value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangesSincePrevious() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangesSincePrevious value)  $default,){
final _that = this;
switch (_that) {
case _ChangesSincePrevious():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangesSincePrevious value)?  $default,){
final _that = this;
switch (_that) {
case _ChangesSincePrevious() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? previousAssessmentId,  String? previousSessionAsOf,  List<String> missingReportSessions,  List<ThesisChange> thesisChanges,  List<String> checkpointChangeIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangesSincePrevious() when $default != null:
return $default(_that.previousAssessmentId,_that.previousSessionAsOf,_that.missingReportSessions,_that.thesisChanges,_that.checkpointChangeIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? previousAssessmentId,  String? previousSessionAsOf,  List<String> missingReportSessions,  List<ThesisChange> thesisChanges,  List<String> checkpointChangeIds)  $default,) {final _that = this;
switch (_that) {
case _ChangesSincePrevious():
return $default(_that.previousAssessmentId,_that.previousSessionAsOf,_that.missingReportSessions,_that.thesisChanges,_that.checkpointChangeIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? previousAssessmentId,  String? previousSessionAsOf,  List<String> missingReportSessions,  List<ThesisChange> thesisChanges,  List<String> checkpointChangeIds)?  $default,) {final _that = this;
switch (_that) {
case _ChangesSincePrevious() when $default != null:
return $default(_that.previousAssessmentId,_that.previousSessionAsOf,_that.missingReportSessions,_that.thesisChanges,_that.checkpointChangeIds);case _:
  return null;

}
}

}

/// @nodoc


class _ChangesSincePrevious implements ChangesSincePrevious {
  const _ChangesSincePrevious({required this.previousAssessmentId, required this.previousSessionAsOf, required final  List<String> missingReportSessions, required final  List<ThesisChange> thesisChanges, required final  List<String> checkpointChangeIds}): _missingReportSessions = missingReportSessions,_thesisChanges = thesisChanges,_checkpointChangeIds = checkpointChangeIds;
  

@override final  String? previousAssessmentId;
@override final  String? previousSessionAsOf;
 final  List<String> _missingReportSessions;
@override List<String> get missingReportSessions {
  if (_missingReportSessions is EqualUnmodifiableListView) return _missingReportSessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingReportSessions);
}

 final  List<ThesisChange> _thesisChanges;
@override List<ThesisChange> get thesisChanges {
  if (_thesisChanges is EqualUnmodifiableListView) return _thesisChanges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_thesisChanges);
}

 final  List<String> _checkpointChangeIds;
@override List<String> get checkpointChangeIds {
  if (_checkpointChangeIds is EqualUnmodifiableListView) return _checkpointChangeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checkpointChangeIds);
}


/// Create a copy of ChangesSincePrevious
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangesSincePreviousCopyWith<_ChangesSincePrevious> get copyWith => __$ChangesSincePreviousCopyWithImpl<_ChangesSincePrevious>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangesSincePrevious&&(identical(other.previousAssessmentId, previousAssessmentId) || other.previousAssessmentId == previousAssessmentId)&&(identical(other.previousSessionAsOf, previousSessionAsOf) || other.previousSessionAsOf == previousSessionAsOf)&&const DeepCollectionEquality().equals(other._missingReportSessions, _missingReportSessions)&&const DeepCollectionEquality().equals(other._thesisChanges, _thesisChanges)&&const DeepCollectionEquality().equals(other._checkpointChangeIds, _checkpointChangeIds));
}


@override
int get hashCode => Object.hash(runtimeType,previousAssessmentId,previousSessionAsOf,const DeepCollectionEquality().hash(_missingReportSessions),const DeepCollectionEquality().hash(_thesisChanges),const DeepCollectionEquality().hash(_checkpointChangeIds));

@override
String toString() {
  return 'ChangesSincePrevious(previousAssessmentId: $previousAssessmentId, previousSessionAsOf: $previousSessionAsOf, missingReportSessions: $missingReportSessions, thesisChanges: $thesisChanges, checkpointChangeIds: $checkpointChangeIds)';
}


}

/// @nodoc
abstract mixin class _$ChangesSincePreviousCopyWith<$Res> implements $ChangesSincePreviousCopyWith<$Res> {
  factory _$ChangesSincePreviousCopyWith(_ChangesSincePrevious value, $Res Function(_ChangesSincePrevious) _then) = __$ChangesSincePreviousCopyWithImpl;
@override @useResult
$Res call({
 String? previousAssessmentId, String? previousSessionAsOf, List<String> missingReportSessions, List<ThesisChange> thesisChanges, List<String> checkpointChangeIds
});




}
/// @nodoc
class __$ChangesSincePreviousCopyWithImpl<$Res>
    implements _$ChangesSincePreviousCopyWith<$Res> {
  __$ChangesSincePreviousCopyWithImpl(this._self, this._then);

  final _ChangesSincePrevious _self;
  final $Res Function(_ChangesSincePrevious) _then;

/// Create a copy of ChangesSincePrevious
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? previousAssessmentId = freezed,Object? previousSessionAsOf = freezed,Object? missingReportSessions = null,Object? thesisChanges = null,Object? checkpointChangeIds = null,}) {
  return _then(_ChangesSincePrevious(
previousAssessmentId: freezed == previousAssessmentId ? _self.previousAssessmentId : previousAssessmentId // ignore: cast_nullable_to_non_nullable
as String?,previousSessionAsOf: freezed == previousSessionAsOf ? _self.previousSessionAsOf : previousSessionAsOf // ignore: cast_nullable_to_non_nullable
as String?,missingReportSessions: null == missingReportSessions ? _self._missingReportSessions : missingReportSessions // ignore: cast_nullable_to_non_nullable
as List<String>,thesisChanges: null == thesisChanges ? _self._thesisChanges : thesisChanges // ignore: cast_nullable_to_non_nullable
as List<ThesisChange>,checkpointChangeIds: null == checkpointChangeIds ? _self._checkpointChangeIds : checkpointChangeIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$ResearchAssessment {

 String get id; int get contractVersion; String? get positionId; int? get positionRevision; String get instrumentId; String get runId; String get evidenceSnapshotId; String get generatedAt; String get sessionAsOf; AssessmentStatus get status; MarketThesis get marketThesis; Recommendation get recommendation; AssessmentPositionContext get positionContext; ChangesSincePrevious? get changesSincePrevious; List<Checkpoint> get checkpoints; List<Outlook> get outlooks; List<String> get missingData; String? get nextReview; Map<String, String> get versions;
/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResearchAssessmentCopyWith<ResearchAssessment> get copyWith => _$ResearchAssessmentCopyWithImpl<ResearchAssessment>(this as ResearchAssessment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResearchAssessment&&(identical(other.id, id) || other.id == id)&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.positionRevision, positionRevision) || other.positionRevision == positionRevision)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.sessionAsOf, sessionAsOf) || other.sessionAsOf == sessionAsOf)&&(identical(other.status, status) || other.status == status)&&(identical(other.marketThesis, marketThesis) || other.marketThesis == marketThesis)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation)&&(identical(other.positionContext, positionContext) || other.positionContext == positionContext)&&(identical(other.changesSincePrevious, changesSincePrevious) || other.changesSincePrevious == changesSincePrevious)&&const DeepCollectionEquality().equals(other.checkpoints, checkpoints)&&const DeepCollectionEquality().equals(other.outlooks, outlooks)&&const DeepCollectionEquality().equals(other.missingData, missingData)&&(identical(other.nextReview, nextReview) || other.nextReview == nextReview)&&const DeepCollectionEquality().equals(other.versions, versions));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,contractVersion,positionId,positionRevision,instrumentId,runId,evidenceSnapshotId,generatedAt,sessionAsOf,status,marketThesis,recommendation,positionContext,changesSincePrevious,const DeepCollectionEquality().hash(checkpoints),const DeepCollectionEquality().hash(outlooks),const DeepCollectionEquality().hash(missingData),nextReview,const DeepCollectionEquality().hash(versions)]);

@override
String toString() {
  return 'ResearchAssessment(id: $id, contractVersion: $contractVersion, positionId: $positionId, positionRevision: $positionRevision, instrumentId: $instrumentId, runId: $runId, evidenceSnapshotId: $evidenceSnapshotId, generatedAt: $generatedAt, sessionAsOf: $sessionAsOf, status: $status, marketThesis: $marketThesis, recommendation: $recommendation, positionContext: $positionContext, changesSincePrevious: $changesSincePrevious, checkpoints: $checkpoints, outlooks: $outlooks, missingData: $missingData, nextReview: $nextReview, versions: $versions)';
}


}

/// @nodoc
abstract mixin class $ResearchAssessmentCopyWith<$Res>  {
  factory $ResearchAssessmentCopyWith(ResearchAssessment value, $Res Function(ResearchAssessment) _then) = _$ResearchAssessmentCopyWithImpl;
@useResult
$Res call({
 String id, int contractVersion, String? positionId, int? positionRevision, String instrumentId, String runId, String evidenceSnapshotId, String generatedAt, String sessionAsOf, AssessmentStatus status, MarketThesis marketThesis, Recommendation recommendation, AssessmentPositionContext positionContext, ChangesSincePrevious? changesSincePrevious, List<Checkpoint> checkpoints, List<Outlook> outlooks, List<String> missingData, String? nextReview, Map<String, String> versions
});


$MarketThesisCopyWith<$Res> get marketThesis;$RecommendationCopyWith<$Res> get recommendation;$AssessmentPositionContextCopyWith<$Res> get positionContext;$ChangesSincePreviousCopyWith<$Res>? get changesSincePrevious;

}
/// @nodoc
class _$ResearchAssessmentCopyWithImpl<$Res>
    implements $ResearchAssessmentCopyWith<$Res> {
  _$ResearchAssessmentCopyWithImpl(this._self, this._then);

  final ResearchAssessment _self;
  final $Res Function(ResearchAssessment) _then;

/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? contractVersion = null,Object? positionId = freezed,Object? positionRevision = freezed,Object? instrumentId = null,Object? runId = null,Object? evidenceSnapshotId = null,Object? generatedAt = null,Object? sessionAsOf = null,Object? status = null,Object? marketThesis = null,Object? recommendation = null,Object? positionContext = null,Object? changesSincePrevious = freezed,Object? checkpoints = null,Object? outlooks = null,Object? missingData = null,Object? nextReview = freezed,Object? versions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as int,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,positionRevision: freezed == positionRevision ? _self.positionRevision : positionRevision // ignore: cast_nullable_to_non_nullable
as int?,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,evidenceSnapshotId: null == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,sessionAsOf: null == sessionAsOf ? _self.sessionAsOf : sessionAsOf // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AssessmentStatus,marketThesis: null == marketThesis ? _self.marketThesis : marketThesis // ignore: cast_nullable_to_non_nullable
as MarketThesis,recommendation: null == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as Recommendation,positionContext: null == positionContext ? _self.positionContext : positionContext // ignore: cast_nullable_to_non_nullable
as AssessmentPositionContext,changesSincePrevious: freezed == changesSincePrevious ? _self.changesSincePrevious : changesSincePrevious // ignore: cast_nullable_to_non_nullable
as ChangesSincePrevious?,checkpoints: null == checkpoints ? _self.checkpoints : checkpoints // ignore: cast_nullable_to_non_nullable
as List<Checkpoint>,outlooks: null == outlooks ? _self.outlooks : outlooks // ignore: cast_nullable_to_non_nullable
as List<Outlook>,missingData: null == missingData ? _self.missingData : missingData // ignore: cast_nullable_to_non_nullable
as List<String>,nextReview: freezed == nextReview ? _self.nextReview : nextReview // ignore: cast_nullable_to_non_nullable
as String?,versions: null == versions ? _self.versions : versions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MarketThesisCopyWith<$Res> get marketThesis {
  
  return $MarketThesisCopyWith<$Res>(_self.marketThesis, (value) {
    return _then(_self.copyWith(marketThesis: value));
  });
}/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecommendationCopyWith<$Res> get recommendation {
  
  return $RecommendationCopyWith<$Res>(_self.recommendation, (value) {
    return _then(_self.copyWith(recommendation: value));
  });
}/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssessmentPositionContextCopyWith<$Res> get positionContext {
  
  return $AssessmentPositionContextCopyWith<$Res>(_self.positionContext, (value) {
    return _then(_self.copyWith(positionContext: value));
  });
}/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChangesSincePreviousCopyWith<$Res>? get changesSincePrevious {
    if (_self.changesSincePrevious == null) {
    return null;
  }

  return $ChangesSincePreviousCopyWith<$Res>(_self.changesSincePrevious!, (value) {
    return _then(_self.copyWith(changesSincePrevious: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResearchAssessment].
extension ResearchAssessmentPatterns on ResearchAssessment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResearchAssessment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResearchAssessment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResearchAssessment value)  $default,){
final _that = this;
switch (_that) {
case _ResearchAssessment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResearchAssessment value)?  $default,){
final _that = this;
switch (_that) {
case _ResearchAssessment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int contractVersion,  String? positionId,  int? positionRevision,  String instrumentId,  String runId,  String evidenceSnapshotId,  String generatedAt,  String sessionAsOf,  AssessmentStatus status,  MarketThesis marketThesis,  Recommendation recommendation,  AssessmentPositionContext positionContext,  ChangesSincePrevious? changesSincePrevious,  List<Checkpoint> checkpoints,  List<Outlook> outlooks,  List<String> missingData,  String? nextReview,  Map<String, String> versions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResearchAssessment() when $default != null:
return $default(_that.id,_that.contractVersion,_that.positionId,_that.positionRevision,_that.instrumentId,_that.runId,_that.evidenceSnapshotId,_that.generatedAt,_that.sessionAsOf,_that.status,_that.marketThesis,_that.recommendation,_that.positionContext,_that.changesSincePrevious,_that.checkpoints,_that.outlooks,_that.missingData,_that.nextReview,_that.versions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int contractVersion,  String? positionId,  int? positionRevision,  String instrumentId,  String runId,  String evidenceSnapshotId,  String generatedAt,  String sessionAsOf,  AssessmentStatus status,  MarketThesis marketThesis,  Recommendation recommendation,  AssessmentPositionContext positionContext,  ChangesSincePrevious? changesSincePrevious,  List<Checkpoint> checkpoints,  List<Outlook> outlooks,  List<String> missingData,  String? nextReview,  Map<String, String> versions)  $default,) {final _that = this;
switch (_that) {
case _ResearchAssessment():
return $default(_that.id,_that.contractVersion,_that.positionId,_that.positionRevision,_that.instrumentId,_that.runId,_that.evidenceSnapshotId,_that.generatedAt,_that.sessionAsOf,_that.status,_that.marketThesis,_that.recommendation,_that.positionContext,_that.changesSincePrevious,_that.checkpoints,_that.outlooks,_that.missingData,_that.nextReview,_that.versions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int contractVersion,  String? positionId,  int? positionRevision,  String instrumentId,  String runId,  String evidenceSnapshotId,  String generatedAt,  String sessionAsOf,  AssessmentStatus status,  MarketThesis marketThesis,  Recommendation recommendation,  AssessmentPositionContext positionContext,  ChangesSincePrevious? changesSincePrevious,  List<Checkpoint> checkpoints,  List<Outlook> outlooks,  List<String> missingData,  String? nextReview,  Map<String, String> versions)?  $default,) {final _that = this;
switch (_that) {
case _ResearchAssessment() when $default != null:
return $default(_that.id,_that.contractVersion,_that.positionId,_that.positionRevision,_that.instrumentId,_that.runId,_that.evidenceSnapshotId,_that.generatedAt,_that.sessionAsOf,_that.status,_that.marketThesis,_that.recommendation,_that.positionContext,_that.changesSincePrevious,_that.checkpoints,_that.outlooks,_that.missingData,_that.nextReview,_that.versions);case _:
  return null;

}
}

}

/// @nodoc


class _ResearchAssessment implements ResearchAssessment {
  const _ResearchAssessment({required this.id, required this.contractVersion, required this.positionId, required this.positionRevision, required this.instrumentId, required this.runId, required this.evidenceSnapshotId, required this.generatedAt, required this.sessionAsOf, required this.status, required this.marketThesis, required this.recommendation, required this.positionContext, required this.changesSincePrevious, required final  List<Checkpoint> checkpoints, required final  List<Outlook> outlooks, required final  List<String> missingData, required this.nextReview, required final  Map<String, String> versions}): _checkpoints = checkpoints,_outlooks = outlooks,_missingData = missingData,_versions = versions;
  

@override final  String id;
@override final  int contractVersion;
@override final  String? positionId;
@override final  int? positionRevision;
@override final  String instrumentId;
@override final  String runId;
@override final  String evidenceSnapshotId;
@override final  String generatedAt;
@override final  String sessionAsOf;
@override final  AssessmentStatus status;
@override final  MarketThesis marketThesis;
@override final  Recommendation recommendation;
@override final  AssessmentPositionContext positionContext;
@override final  ChangesSincePrevious? changesSincePrevious;
 final  List<Checkpoint> _checkpoints;
@override List<Checkpoint> get checkpoints {
  if (_checkpoints is EqualUnmodifiableListView) return _checkpoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checkpoints);
}

 final  List<Outlook> _outlooks;
@override List<Outlook> get outlooks {
  if (_outlooks is EqualUnmodifiableListView) return _outlooks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outlooks);
}

 final  List<String> _missingData;
@override List<String> get missingData {
  if (_missingData is EqualUnmodifiableListView) return _missingData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingData);
}

@override final  String? nextReview;
 final  Map<String, String> _versions;
@override Map<String, String> get versions {
  if (_versions is EqualUnmodifiableMapView) return _versions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_versions);
}


/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResearchAssessmentCopyWith<_ResearchAssessment> get copyWith => __$ResearchAssessmentCopyWithImpl<_ResearchAssessment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResearchAssessment&&(identical(other.id, id) || other.id == id)&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.positionRevision, positionRevision) || other.positionRevision == positionRevision)&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.sessionAsOf, sessionAsOf) || other.sessionAsOf == sessionAsOf)&&(identical(other.status, status) || other.status == status)&&(identical(other.marketThesis, marketThesis) || other.marketThesis == marketThesis)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation)&&(identical(other.positionContext, positionContext) || other.positionContext == positionContext)&&(identical(other.changesSincePrevious, changesSincePrevious) || other.changesSincePrevious == changesSincePrevious)&&const DeepCollectionEquality().equals(other._checkpoints, _checkpoints)&&const DeepCollectionEquality().equals(other._outlooks, _outlooks)&&const DeepCollectionEquality().equals(other._missingData, _missingData)&&(identical(other.nextReview, nextReview) || other.nextReview == nextReview)&&const DeepCollectionEquality().equals(other._versions, _versions));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,contractVersion,positionId,positionRevision,instrumentId,runId,evidenceSnapshotId,generatedAt,sessionAsOf,status,marketThesis,recommendation,positionContext,changesSincePrevious,const DeepCollectionEquality().hash(_checkpoints),const DeepCollectionEquality().hash(_outlooks),const DeepCollectionEquality().hash(_missingData),nextReview,const DeepCollectionEquality().hash(_versions)]);

@override
String toString() {
  return 'ResearchAssessment(id: $id, contractVersion: $contractVersion, positionId: $positionId, positionRevision: $positionRevision, instrumentId: $instrumentId, runId: $runId, evidenceSnapshotId: $evidenceSnapshotId, generatedAt: $generatedAt, sessionAsOf: $sessionAsOf, status: $status, marketThesis: $marketThesis, recommendation: $recommendation, positionContext: $positionContext, changesSincePrevious: $changesSincePrevious, checkpoints: $checkpoints, outlooks: $outlooks, missingData: $missingData, nextReview: $nextReview, versions: $versions)';
}


}

/// @nodoc
abstract mixin class _$ResearchAssessmentCopyWith<$Res> implements $ResearchAssessmentCopyWith<$Res> {
  factory _$ResearchAssessmentCopyWith(_ResearchAssessment value, $Res Function(_ResearchAssessment) _then) = __$ResearchAssessmentCopyWithImpl;
@override @useResult
$Res call({
 String id, int contractVersion, String? positionId, int? positionRevision, String instrumentId, String runId, String evidenceSnapshotId, String generatedAt, String sessionAsOf, AssessmentStatus status, MarketThesis marketThesis, Recommendation recommendation, AssessmentPositionContext positionContext, ChangesSincePrevious? changesSincePrevious, List<Checkpoint> checkpoints, List<Outlook> outlooks, List<String> missingData, String? nextReview, Map<String, String> versions
});


@override $MarketThesisCopyWith<$Res> get marketThesis;@override $RecommendationCopyWith<$Res> get recommendation;@override $AssessmentPositionContextCopyWith<$Res> get positionContext;@override $ChangesSincePreviousCopyWith<$Res>? get changesSincePrevious;

}
/// @nodoc
class __$ResearchAssessmentCopyWithImpl<$Res>
    implements _$ResearchAssessmentCopyWith<$Res> {
  __$ResearchAssessmentCopyWithImpl(this._self, this._then);

  final _ResearchAssessment _self;
  final $Res Function(_ResearchAssessment) _then;

/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? contractVersion = null,Object? positionId = freezed,Object? positionRevision = freezed,Object? instrumentId = null,Object? runId = null,Object? evidenceSnapshotId = null,Object? generatedAt = null,Object? sessionAsOf = null,Object? status = null,Object? marketThesis = null,Object? recommendation = null,Object? positionContext = null,Object? changesSincePrevious = freezed,Object? checkpoints = null,Object? outlooks = null,Object? missingData = null,Object? nextReview = freezed,Object? versions = null,}) {
  return _then(_ResearchAssessment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as int,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,positionRevision: freezed == positionRevision ? _self.positionRevision : positionRevision // ignore: cast_nullable_to_non_nullable
as int?,instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,evidenceSnapshotId: null == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,sessionAsOf: null == sessionAsOf ? _self.sessionAsOf : sessionAsOf // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AssessmentStatus,marketThesis: null == marketThesis ? _self.marketThesis : marketThesis // ignore: cast_nullable_to_non_nullable
as MarketThesis,recommendation: null == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as Recommendation,positionContext: null == positionContext ? _self.positionContext : positionContext // ignore: cast_nullable_to_non_nullable
as AssessmentPositionContext,changesSincePrevious: freezed == changesSincePrevious ? _self.changesSincePrevious : changesSincePrevious // ignore: cast_nullable_to_non_nullable
as ChangesSincePrevious?,checkpoints: null == checkpoints ? _self._checkpoints : checkpoints // ignore: cast_nullable_to_non_nullable
as List<Checkpoint>,outlooks: null == outlooks ? _self._outlooks : outlooks // ignore: cast_nullable_to_non_nullable
as List<Outlook>,missingData: null == missingData ? _self._missingData : missingData // ignore: cast_nullable_to_non_nullable
as List<String>,nextReview: freezed == nextReview ? _self.nextReview : nextReview // ignore: cast_nullable_to_non_nullable
as String?,versions: null == versions ? _self._versions : versions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MarketThesisCopyWith<$Res> get marketThesis {
  
  return $MarketThesisCopyWith<$Res>(_self.marketThesis, (value) {
    return _then(_self.copyWith(marketThesis: value));
  });
}/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecommendationCopyWith<$Res> get recommendation {
  
  return $RecommendationCopyWith<$Res>(_self.recommendation, (value) {
    return _then(_self.copyWith(recommendation: value));
  });
}/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssessmentPositionContextCopyWith<$Res> get positionContext {
  
  return $AssessmentPositionContextCopyWith<$Res>(_self.positionContext, (value) {
    return _then(_self.copyWith(positionContext: value));
  });
}/// Create a copy of ResearchAssessment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChangesSincePreviousCopyWith<$Res>? get changesSincePrevious {
    if (_self.changesSincePrevious == null) {
    return null;
  }

  return $ChangesSincePreviousCopyWith<$Res>(_self.changesSincePrevious!, (value) {
    return _then(_self.copyWith(changesSincePrevious: value));
  });
}
}

/// @nodoc
mixin _$ResearchRun {

 String get id; String get positionId; String get ownerIdInternal; int get positionRevision; RunKind get runKind; String get idempotencyKey; RunStatus get status; String get stage; String get createdAt; String? get startedAt; String? get heartbeatAt; String get deadlineAt; String? get finishedAt; String? get evidenceSnapshotId; String? get assessmentId; String? get errorCode; int get retryCount; Map<String, String> get versions;
/// Create a copy of ResearchRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResearchRunCopyWith<ResearchRun> get copyWith => _$ResearchRunCopyWithImpl<ResearchRun>(this as ResearchRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResearchRun&&(identical(other.id, id) || other.id == id)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.ownerIdInternal, ownerIdInternal) || other.ownerIdInternal == ownerIdInternal)&&(identical(other.positionRevision, positionRevision) || other.positionRevision == positionRevision)&&(identical(other.runKind, runKind) || other.runKind == runKind)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.heartbeatAt, heartbeatAt) || other.heartbeatAt == heartbeatAt)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.assessmentId, assessmentId) || other.assessmentId == assessmentId)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&const DeepCollectionEquality().equals(other.versions, versions));
}


@override
int get hashCode => Object.hash(runtimeType,id,positionId,ownerIdInternal,positionRevision,runKind,idempotencyKey,status,stage,createdAt,startedAt,heartbeatAt,deadlineAt,finishedAt,evidenceSnapshotId,assessmentId,errorCode,retryCount,const DeepCollectionEquality().hash(versions));

@override
String toString() {
  return 'ResearchRun(id: $id, positionId: $positionId, ownerIdInternal: $ownerIdInternal, positionRevision: $positionRevision, runKind: $runKind, idempotencyKey: $idempotencyKey, status: $status, stage: $stage, createdAt: $createdAt, startedAt: $startedAt, heartbeatAt: $heartbeatAt, deadlineAt: $deadlineAt, finishedAt: $finishedAt, evidenceSnapshotId: $evidenceSnapshotId, assessmentId: $assessmentId, errorCode: $errorCode, retryCount: $retryCount, versions: $versions)';
}


}

/// @nodoc
abstract mixin class $ResearchRunCopyWith<$Res>  {
  factory $ResearchRunCopyWith(ResearchRun value, $Res Function(ResearchRun) _then) = _$ResearchRunCopyWithImpl;
@useResult
$Res call({
 String id, String positionId, String ownerIdInternal, int positionRevision, RunKind runKind, String idempotencyKey, RunStatus status, String stage, String createdAt, String? startedAt, String? heartbeatAt, String deadlineAt, String? finishedAt, String? evidenceSnapshotId, String? assessmentId, String? errorCode, int retryCount, Map<String, String> versions
});




}
/// @nodoc
class _$ResearchRunCopyWithImpl<$Res>
    implements $ResearchRunCopyWith<$Res> {
  _$ResearchRunCopyWithImpl(this._self, this._then);

  final ResearchRun _self;
  final $Res Function(ResearchRun) _then;

/// Create a copy of ResearchRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? positionId = null,Object? ownerIdInternal = null,Object? positionRevision = null,Object? runKind = null,Object? idempotencyKey = null,Object? status = null,Object? stage = null,Object? createdAt = null,Object? startedAt = freezed,Object? heartbeatAt = freezed,Object? deadlineAt = null,Object? finishedAt = freezed,Object? evidenceSnapshotId = freezed,Object? assessmentId = freezed,Object? errorCode = freezed,Object? retryCount = null,Object? versions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,ownerIdInternal: null == ownerIdInternal ? _self.ownerIdInternal : ownerIdInternal // ignore: cast_nullable_to_non_nullable
as String,positionRevision: null == positionRevision ? _self.positionRevision : positionRevision // ignore: cast_nullable_to_non_nullable
as int,runKind: null == runKind ? _self.runKind : runKind // ignore: cast_nullable_to_non_nullable
as RunKind,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,heartbeatAt: freezed == heartbeatAt ? _self.heartbeatAt : heartbeatAt // ignore: cast_nullable_to_non_nullable
as String?,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as String,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as String?,evidenceSnapshotId: freezed == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String?,assessmentId: freezed == assessmentId ? _self.assessmentId : assessmentId // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,versions: null == versions ? _self.versions : versions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResearchRun].
extension ResearchRunPatterns on ResearchRun {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResearchRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResearchRun() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResearchRun value)  $default,){
final _that = this;
switch (_that) {
case _ResearchRun():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResearchRun value)?  $default,){
final _that = this;
switch (_that) {
case _ResearchRun() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String positionId,  String ownerIdInternal,  int positionRevision,  RunKind runKind,  String idempotencyKey,  RunStatus status,  String stage,  String createdAt,  String? startedAt,  String? heartbeatAt,  String deadlineAt,  String? finishedAt,  String? evidenceSnapshotId,  String? assessmentId,  String? errorCode,  int retryCount,  Map<String, String> versions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResearchRun() when $default != null:
return $default(_that.id,_that.positionId,_that.ownerIdInternal,_that.positionRevision,_that.runKind,_that.idempotencyKey,_that.status,_that.stage,_that.createdAt,_that.startedAt,_that.heartbeatAt,_that.deadlineAt,_that.finishedAt,_that.evidenceSnapshotId,_that.assessmentId,_that.errorCode,_that.retryCount,_that.versions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String positionId,  String ownerIdInternal,  int positionRevision,  RunKind runKind,  String idempotencyKey,  RunStatus status,  String stage,  String createdAt,  String? startedAt,  String? heartbeatAt,  String deadlineAt,  String? finishedAt,  String? evidenceSnapshotId,  String? assessmentId,  String? errorCode,  int retryCount,  Map<String, String> versions)  $default,) {final _that = this;
switch (_that) {
case _ResearchRun():
return $default(_that.id,_that.positionId,_that.ownerIdInternal,_that.positionRevision,_that.runKind,_that.idempotencyKey,_that.status,_that.stage,_that.createdAt,_that.startedAt,_that.heartbeatAt,_that.deadlineAt,_that.finishedAt,_that.evidenceSnapshotId,_that.assessmentId,_that.errorCode,_that.retryCount,_that.versions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String positionId,  String ownerIdInternal,  int positionRevision,  RunKind runKind,  String idempotencyKey,  RunStatus status,  String stage,  String createdAt,  String? startedAt,  String? heartbeatAt,  String deadlineAt,  String? finishedAt,  String? evidenceSnapshotId,  String? assessmentId,  String? errorCode,  int retryCount,  Map<String, String> versions)?  $default,) {final _that = this;
switch (_that) {
case _ResearchRun() when $default != null:
return $default(_that.id,_that.positionId,_that.ownerIdInternal,_that.positionRevision,_that.runKind,_that.idempotencyKey,_that.status,_that.stage,_that.createdAt,_that.startedAt,_that.heartbeatAt,_that.deadlineAt,_that.finishedAt,_that.evidenceSnapshotId,_that.assessmentId,_that.errorCode,_that.retryCount,_that.versions);case _:
  return null;

}
}

}

/// @nodoc


class _ResearchRun implements ResearchRun {
  const _ResearchRun({required this.id, required this.positionId, required this.ownerIdInternal, required this.positionRevision, required this.runKind, required this.idempotencyKey, required this.status, required this.stage, required this.createdAt, required this.startedAt, required this.heartbeatAt, required this.deadlineAt, required this.finishedAt, required this.evidenceSnapshotId, required this.assessmentId, required this.errorCode, required this.retryCount, required final  Map<String, String> versions}): _versions = versions;
  

@override final  String id;
@override final  String positionId;
@override final  String ownerIdInternal;
@override final  int positionRevision;
@override final  RunKind runKind;
@override final  String idempotencyKey;
@override final  RunStatus status;
@override final  String stage;
@override final  String createdAt;
@override final  String? startedAt;
@override final  String? heartbeatAt;
@override final  String deadlineAt;
@override final  String? finishedAt;
@override final  String? evidenceSnapshotId;
@override final  String? assessmentId;
@override final  String? errorCode;
@override final  int retryCount;
 final  Map<String, String> _versions;
@override Map<String, String> get versions {
  if (_versions is EqualUnmodifiableMapView) return _versions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_versions);
}


/// Create a copy of ResearchRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResearchRunCopyWith<_ResearchRun> get copyWith => __$ResearchRunCopyWithImpl<_ResearchRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResearchRun&&(identical(other.id, id) || other.id == id)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.ownerIdInternal, ownerIdInternal) || other.ownerIdInternal == ownerIdInternal)&&(identical(other.positionRevision, positionRevision) || other.positionRevision == positionRevision)&&(identical(other.runKind, runKind) || other.runKind == runKind)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.heartbeatAt, heartbeatAt) || other.heartbeatAt == heartbeatAt)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.assessmentId, assessmentId) || other.assessmentId == assessmentId)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&const DeepCollectionEquality().equals(other._versions, _versions));
}


@override
int get hashCode => Object.hash(runtimeType,id,positionId,ownerIdInternal,positionRevision,runKind,idempotencyKey,status,stage,createdAt,startedAt,heartbeatAt,deadlineAt,finishedAt,evidenceSnapshotId,assessmentId,errorCode,retryCount,const DeepCollectionEquality().hash(_versions));

@override
String toString() {
  return 'ResearchRun(id: $id, positionId: $positionId, ownerIdInternal: $ownerIdInternal, positionRevision: $positionRevision, runKind: $runKind, idempotencyKey: $idempotencyKey, status: $status, stage: $stage, createdAt: $createdAt, startedAt: $startedAt, heartbeatAt: $heartbeatAt, deadlineAt: $deadlineAt, finishedAt: $finishedAt, evidenceSnapshotId: $evidenceSnapshotId, assessmentId: $assessmentId, errorCode: $errorCode, retryCount: $retryCount, versions: $versions)';
}


}

/// @nodoc
abstract mixin class _$ResearchRunCopyWith<$Res> implements $ResearchRunCopyWith<$Res> {
  factory _$ResearchRunCopyWith(_ResearchRun value, $Res Function(_ResearchRun) _then) = __$ResearchRunCopyWithImpl;
@override @useResult
$Res call({
 String id, String positionId, String ownerIdInternal, int positionRevision, RunKind runKind, String idempotencyKey, RunStatus status, String stage, String createdAt, String? startedAt, String? heartbeatAt, String deadlineAt, String? finishedAt, String? evidenceSnapshotId, String? assessmentId, String? errorCode, int retryCount, Map<String, String> versions
});




}
/// @nodoc
class __$ResearchRunCopyWithImpl<$Res>
    implements _$ResearchRunCopyWith<$Res> {
  __$ResearchRunCopyWithImpl(this._self, this._then);

  final _ResearchRun _self;
  final $Res Function(_ResearchRun) _then;

/// Create a copy of ResearchRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? positionId = null,Object? ownerIdInternal = null,Object? positionRevision = null,Object? runKind = null,Object? idempotencyKey = null,Object? status = null,Object? stage = null,Object? createdAt = null,Object? startedAt = freezed,Object? heartbeatAt = freezed,Object? deadlineAt = null,Object? finishedAt = freezed,Object? evidenceSnapshotId = freezed,Object? assessmentId = freezed,Object? errorCode = freezed,Object? retryCount = null,Object? versions = null,}) {
  return _then(_ResearchRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,ownerIdInternal: null == ownerIdInternal ? _self.ownerIdInternal : ownerIdInternal // ignore: cast_nullable_to_non_nullable
as String,positionRevision: null == positionRevision ? _self.positionRevision : positionRevision // ignore: cast_nullable_to_non_nullable
as int,runKind: null == runKind ? _self.runKind : runKind // ignore: cast_nullable_to_non_nullable
as RunKind,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,heartbeatAt: freezed == heartbeatAt ? _self.heartbeatAt : heartbeatAt // ignore: cast_nullable_to_non_nullable
as String?,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as String,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as String?,evidenceSnapshotId: freezed == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String?,assessmentId: freezed == assessmentId ? _self.assessmentId : assessmentId // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,versions: null == versions ? _self._versions : versions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc
mixin _$ResearchLatest {

 String get positionId; ResearchAssessment? get latestAssessment; ResearchLastSuccess? get lastSuccess; ResearchLatestAttempt? get latestAttempt;
/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResearchLatestCopyWith<ResearchLatest> get copyWith => _$ResearchLatestCopyWithImpl<ResearchLatest>(this as ResearchLatest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResearchLatest&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.latestAssessment, latestAssessment) || other.latestAssessment == latestAssessment)&&(identical(other.lastSuccess, lastSuccess) || other.lastSuccess == lastSuccess)&&(identical(other.latestAttempt, latestAttempt) || other.latestAttempt == latestAttempt));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,latestAssessment,lastSuccess,latestAttempt);

@override
String toString() {
  return 'ResearchLatest(positionId: $positionId, latestAssessment: $latestAssessment, lastSuccess: $lastSuccess, latestAttempt: $latestAttempt)';
}


}

/// @nodoc
abstract mixin class $ResearchLatestCopyWith<$Res>  {
  factory $ResearchLatestCopyWith(ResearchLatest value, $Res Function(ResearchLatest) _then) = _$ResearchLatestCopyWithImpl;
@useResult
$Res call({
 String positionId, ResearchAssessment? latestAssessment, ResearchLastSuccess? lastSuccess, ResearchLatestAttempt? latestAttempt
});


$ResearchAssessmentCopyWith<$Res>? get latestAssessment;$ResearchLastSuccessCopyWith<$Res>? get lastSuccess;$ResearchLatestAttemptCopyWith<$Res>? get latestAttempt;

}
/// @nodoc
class _$ResearchLatestCopyWithImpl<$Res>
    implements $ResearchLatestCopyWith<$Res> {
  _$ResearchLatestCopyWithImpl(this._self, this._then);

  final ResearchLatest _self;
  final $Res Function(ResearchLatest) _then;

/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionId = null,Object? latestAssessment = freezed,Object? lastSuccess = freezed,Object? latestAttempt = freezed,}) {
  return _then(_self.copyWith(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,latestAssessment: freezed == latestAssessment ? _self.latestAssessment : latestAssessment // ignore: cast_nullable_to_non_nullable
as ResearchAssessment?,lastSuccess: freezed == lastSuccess ? _self.lastSuccess : lastSuccess // ignore: cast_nullable_to_non_nullable
as ResearchLastSuccess?,latestAttempt: freezed == latestAttempt ? _self.latestAttempt : latestAttempt // ignore: cast_nullable_to_non_nullable
as ResearchLatestAttempt?,
  ));
}
/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResearchAssessmentCopyWith<$Res>? get latestAssessment {
    if (_self.latestAssessment == null) {
    return null;
  }

  return $ResearchAssessmentCopyWith<$Res>(_self.latestAssessment!, (value) {
    return _then(_self.copyWith(latestAssessment: value));
  });
}/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResearchLastSuccessCopyWith<$Res>? get lastSuccess {
    if (_self.lastSuccess == null) {
    return null;
  }

  return $ResearchLastSuccessCopyWith<$Res>(_self.lastSuccess!, (value) {
    return _then(_self.copyWith(lastSuccess: value));
  });
}/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResearchLatestAttemptCopyWith<$Res>? get latestAttempt {
    if (_self.latestAttempt == null) {
    return null;
  }

  return $ResearchLatestAttemptCopyWith<$Res>(_self.latestAttempt!, (value) {
    return _then(_self.copyWith(latestAttempt: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResearchLatest].
extension ResearchLatestPatterns on ResearchLatest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResearchLatest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResearchLatest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResearchLatest value)  $default,){
final _that = this;
switch (_that) {
case _ResearchLatest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResearchLatest value)?  $default,){
final _that = this;
switch (_that) {
case _ResearchLatest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String positionId,  ResearchAssessment? latestAssessment,  ResearchLastSuccess? lastSuccess,  ResearchLatestAttempt? latestAttempt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResearchLatest() when $default != null:
return $default(_that.positionId,_that.latestAssessment,_that.lastSuccess,_that.latestAttempt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String positionId,  ResearchAssessment? latestAssessment,  ResearchLastSuccess? lastSuccess,  ResearchLatestAttempt? latestAttempt)  $default,) {final _that = this;
switch (_that) {
case _ResearchLatest():
return $default(_that.positionId,_that.latestAssessment,_that.lastSuccess,_that.latestAttempt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String positionId,  ResearchAssessment? latestAssessment,  ResearchLastSuccess? lastSuccess,  ResearchLatestAttempt? latestAttempt)?  $default,) {final _that = this;
switch (_that) {
case _ResearchLatest() when $default != null:
return $default(_that.positionId,_that.latestAssessment,_that.lastSuccess,_that.latestAttempt);case _:
  return null;

}
}

}

/// @nodoc


class _ResearchLatest implements ResearchLatest {
  const _ResearchLatest({required this.positionId, required this.latestAssessment, required this.lastSuccess, required this.latestAttempt});
  

@override final  String positionId;
@override final  ResearchAssessment? latestAssessment;
@override final  ResearchLastSuccess? lastSuccess;
@override final  ResearchLatestAttempt? latestAttempt;

/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResearchLatestCopyWith<_ResearchLatest> get copyWith => __$ResearchLatestCopyWithImpl<_ResearchLatest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResearchLatest&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.latestAssessment, latestAssessment) || other.latestAssessment == latestAssessment)&&(identical(other.lastSuccess, lastSuccess) || other.lastSuccess == lastSuccess)&&(identical(other.latestAttempt, latestAttempt) || other.latestAttempt == latestAttempt));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,latestAssessment,lastSuccess,latestAttempt);

@override
String toString() {
  return 'ResearchLatest(positionId: $positionId, latestAssessment: $latestAssessment, lastSuccess: $lastSuccess, latestAttempt: $latestAttempt)';
}


}

/// @nodoc
abstract mixin class _$ResearchLatestCopyWith<$Res> implements $ResearchLatestCopyWith<$Res> {
  factory _$ResearchLatestCopyWith(_ResearchLatest value, $Res Function(_ResearchLatest) _then) = __$ResearchLatestCopyWithImpl;
@override @useResult
$Res call({
 String positionId, ResearchAssessment? latestAssessment, ResearchLastSuccess? lastSuccess, ResearchLatestAttempt? latestAttempt
});


@override $ResearchAssessmentCopyWith<$Res>? get latestAssessment;@override $ResearchLastSuccessCopyWith<$Res>? get lastSuccess;@override $ResearchLatestAttemptCopyWith<$Res>? get latestAttempt;

}
/// @nodoc
class __$ResearchLatestCopyWithImpl<$Res>
    implements _$ResearchLatestCopyWith<$Res> {
  __$ResearchLatestCopyWithImpl(this._self, this._then);

  final _ResearchLatest _self;
  final $Res Function(_ResearchLatest) _then;

/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionId = null,Object? latestAssessment = freezed,Object? lastSuccess = freezed,Object? latestAttempt = freezed,}) {
  return _then(_ResearchLatest(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,latestAssessment: freezed == latestAssessment ? _self.latestAssessment : latestAssessment // ignore: cast_nullable_to_non_nullable
as ResearchAssessment?,lastSuccess: freezed == lastSuccess ? _self.lastSuccess : lastSuccess // ignore: cast_nullable_to_non_nullable
as ResearchLastSuccess?,latestAttempt: freezed == latestAttempt ? _self.latestAttempt : latestAttempt // ignore: cast_nullable_to_non_nullable
as ResearchLatestAttempt?,
  ));
}

/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResearchAssessmentCopyWith<$Res>? get latestAssessment {
    if (_self.latestAssessment == null) {
    return null;
  }

  return $ResearchAssessmentCopyWith<$Res>(_self.latestAssessment!, (value) {
    return _then(_self.copyWith(latestAssessment: value));
  });
}/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResearchLastSuccessCopyWith<$Res>? get lastSuccess {
    if (_self.lastSuccess == null) {
    return null;
  }

  return $ResearchLastSuccessCopyWith<$Res>(_self.lastSuccess!, (value) {
    return _then(_self.copyWith(lastSuccess: value));
  });
}/// Create a copy of ResearchLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResearchLatestAttemptCopyWith<$Res>? get latestAttempt {
    if (_self.latestAttempt == null) {
    return null;
  }

  return $ResearchLatestAttemptCopyWith<$Res>(_self.latestAttempt!, (value) {
    return _then(_self.copyWith(latestAttempt: value));
  });
}
}

/// @nodoc
mixin _$ResearchLastSuccess {

 String get runId; RunStatus get status; String? get assessmentId; String? get evidenceSnapshotId; String? get finishedAt;
/// Create a copy of ResearchLastSuccess
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResearchLastSuccessCopyWith<ResearchLastSuccess> get copyWith => _$ResearchLastSuccessCopyWithImpl<ResearchLastSuccess>(this as ResearchLastSuccess, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResearchLastSuccess&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.status, status) || other.status == status)&&(identical(other.assessmentId, assessmentId) || other.assessmentId == assessmentId)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,runId,status,assessmentId,evidenceSnapshotId,finishedAt);

@override
String toString() {
  return 'ResearchLastSuccess(runId: $runId, status: $status, assessmentId: $assessmentId, evidenceSnapshotId: $evidenceSnapshotId, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class $ResearchLastSuccessCopyWith<$Res>  {
  factory $ResearchLastSuccessCopyWith(ResearchLastSuccess value, $Res Function(ResearchLastSuccess) _then) = _$ResearchLastSuccessCopyWithImpl;
@useResult
$Res call({
 String runId, RunStatus status, String? assessmentId, String? evidenceSnapshotId, String? finishedAt
});




}
/// @nodoc
class _$ResearchLastSuccessCopyWithImpl<$Res>
    implements $ResearchLastSuccessCopyWith<$Res> {
  _$ResearchLastSuccessCopyWithImpl(this._self, this._then);

  final ResearchLastSuccess _self;
  final $Res Function(ResearchLastSuccess) _then;

/// Create a copy of ResearchLastSuccess
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? status = null,Object? assessmentId = freezed,Object? evidenceSnapshotId = freezed,Object? finishedAt = freezed,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,assessmentId: freezed == assessmentId ? _self.assessmentId : assessmentId // ignore: cast_nullable_to_non_nullable
as String?,evidenceSnapshotId: freezed == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResearchLastSuccess].
extension ResearchLastSuccessPatterns on ResearchLastSuccess {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResearchLastSuccess value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResearchLastSuccess() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResearchLastSuccess value)  $default,){
final _that = this;
switch (_that) {
case _ResearchLastSuccess():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResearchLastSuccess value)?  $default,){
final _that = this;
switch (_that) {
case _ResearchLastSuccess() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  RunStatus status,  String? assessmentId,  String? evidenceSnapshotId,  String? finishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResearchLastSuccess() when $default != null:
return $default(_that.runId,_that.status,_that.assessmentId,_that.evidenceSnapshotId,_that.finishedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  RunStatus status,  String? assessmentId,  String? evidenceSnapshotId,  String? finishedAt)  $default,) {final _that = this;
switch (_that) {
case _ResearchLastSuccess():
return $default(_that.runId,_that.status,_that.assessmentId,_that.evidenceSnapshotId,_that.finishedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  RunStatus status,  String? assessmentId,  String? evidenceSnapshotId,  String? finishedAt)?  $default,) {final _that = this;
switch (_that) {
case _ResearchLastSuccess() when $default != null:
return $default(_that.runId,_that.status,_that.assessmentId,_that.evidenceSnapshotId,_that.finishedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ResearchLastSuccess implements ResearchLastSuccess {
  const _ResearchLastSuccess({required this.runId, required this.status, required this.assessmentId, required this.evidenceSnapshotId, required this.finishedAt});
  

@override final  String runId;
@override final  RunStatus status;
@override final  String? assessmentId;
@override final  String? evidenceSnapshotId;
@override final  String? finishedAt;

/// Create a copy of ResearchLastSuccess
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResearchLastSuccessCopyWith<_ResearchLastSuccess> get copyWith => __$ResearchLastSuccessCopyWithImpl<_ResearchLastSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResearchLastSuccess&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.status, status) || other.status == status)&&(identical(other.assessmentId, assessmentId) || other.assessmentId == assessmentId)&&(identical(other.evidenceSnapshotId, evidenceSnapshotId) || other.evidenceSnapshotId == evidenceSnapshotId)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,runId,status,assessmentId,evidenceSnapshotId,finishedAt);

@override
String toString() {
  return 'ResearchLastSuccess(runId: $runId, status: $status, assessmentId: $assessmentId, evidenceSnapshotId: $evidenceSnapshotId, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class _$ResearchLastSuccessCopyWith<$Res> implements $ResearchLastSuccessCopyWith<$Res> {
  factory _$ResearchLastSuccessCopyWith(_ResearchLastSuccess value, $Res Function(_ResearchLastSuccess) _then) = __$ResearchLastSuccessCopyWithImpl;
@override @useResult
$Res call({
 String runId, RunStatus status, String? assessmentId, String? evidenceSnapshotId, String? finishedAt
});




}
/// @nodoc
class __$ResearchLastSuccessCopyWithImpl<$Res>
    implements _$ResearchLastSuccessCopyWith<$Res> {
  __$ResearchLastSuccessCopyWithImpl(this._self, this._then);

  final _ResearchLastSuccess _self;
  final $Res Function(_ResearchLastSuccess) _then;

/// Create a copy of ResearchLastSuccess
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? status = null,Object? assessmentId = freezed,Object? evidenceSnapshotId = freezed,Object? finishedAt = freezed,}) {
  return _then(_ResearchLastSuccess(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,assessmentId: freezed == assessmentId ? _self.assessmentId : assessmentId // ignore: cast_nullable_to_non_nullable
as String?,evidenceSnapshotId: freezed == evidenceSnapshotId ? _self.evidenceSnapshotId : evidenceSnapshotId // ignore: cast_nullable_to_non_nullable
as String?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ResearchLatestAttempt {

 String get runId; RunStatus get status; String? get stage; String? get startedAt; String? get finishedAt; String? get errorCode; String get deadlineAt;
/// Create a copy of ResearchLatestAttempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResearchLatestAttemptCopyWith<ResearchLatestAttempt> get copyWith => _$ResearchLatestAttemptCopyWithImpl<ResearchLatestAttempt>(this as ResearchLatestAttempt, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResearchLatestAttempt&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.status, status) || other.status == status)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt));
}


@override
int get hashCode => Object.hash(runtimeType,runId,status,stage,startedAt,finishedAt,errorCode,deadlineAt);

@override
String toString() {
  return 'ResearchLatestAttempt(runId: $runId, status: $status, stage: $stage, startedAt: $startedAt, finishedAt: $finishedAt, errorCode: $errorCode, deadlineAt: $deadlineAt)';
}


}

/// @nodoc
abstract mixin class $ResearchLatestAttemptCopyWith<$Res>  {
  factory $ResearchLatestAttemptCopyWith(ResearchLatestAttempt value, $Res Function(ResearchLatestAttempt) _then) = _$ResearchLatestAttemptCopyWithImpl;
@useResult
$Res call({
 String runId, RunStatus status, String? stage, String? startedAt, String? finishedAt, String? errorCode, String deadlineAt
});




}
/// @nodoc
class _$ResearchLatestAttemptCopyWithImpl<$Res>
    implements $ResearchLatestAttemptCopyWith<$Res> {
  _$ResearchLatestAttemptCopyWithImpl(this._self, this._then);

  final ResearchLatestAttempt _self;
  final $Res Function(ResearchLatestAttempt) _then;

/// Create a copy of ResearchLatestAttempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? status = null,Object? stage = freezed,Object? startedAt = freezed,Object? finishedAt = freezed,Object? errorCode = freezed,Object? deadlineAt = null,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ResearchLatestAttempt].
extension ResearchLatestAttemptPatterns on ResearchLatestAttempt {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResearchLatestAttempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResearchLatestAttempt() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResearchLatestAttempt value)  $default,){
final _that = this;
switch (_that) {
case _ResearchLatestAttempt():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResearchLatestAttempt value)?  $default,){
final _that = this;
switch (_that) {
case _ResearchLatestAttempt() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  RunStatus status,  String? stage,  String? startedAt,  String? finishedAt,  String? errorCode,  String deadlineAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResearchLatestAttempt() when $default != null:
return $default(_that.runId,_that.status,_that.stage,_that.startedAt,_that.finishedAt,_that.errorCode,_that.deadlineAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  RunStatus status,  String? stage,  String? startedAt,  String? finishedAt,  String? errorCode,  String deadlineAt)  $default,) {final _that = this;
switch (_that) {
case _ResearchLatestAttempt():
return $default(_that.runId,_that.status,_that.stage,_that.startedAt,_that.finishedAt,_that.errorCode,_that.deadlineAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  RunStatus status,  String? stage,  String? startedAt,  String? finishedAt,  String? errorCode,  String deadlineAt)?  $default,) {final _that = this;
switch (_that) {
case _ResearchLatestAttempt() when $default != null:
return $default(_that.runId,_that.status,_that.stage,_that.startedAt,_that.finishedAt,_that.errorCode,_that.deadlineAt);case _:
  return null;

}
}

}

/// @nodoc


class _ResearchLatestAttempt implements ResearchLatestAttempt {
  const _ResearchLatestAttempt({required this.runId, required this.status, required this.stage, required this.startedAt, required this.finishedAt, required this.errorCode, required this.deadlineAt});
  

@override final  String runId;
@override final  RunStatus status;
@override final  String? stage;
@override final  String? startedAt;
@override final  String? finishedAt;
@override final  String? errorCode;
@override final  String deadlineAt;

/// Create a copy of ResearchLatestAttempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResearchLatestAttemptCopyWith<_ResearchLatestAttempt> get copyWith => __$ResearchLatestAttemptCopyWithImpl<_ResearchLatestAttempt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResearchLatestAttempt&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.status, status) || other.status == status)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt));
}


@override
int get hashCode => Object.hash(runtimeType,runId,status,stage,startedAt,finishedAt,errorCode,deadlineAt);

@override
String toString() {
  return 'ResearchLatestAttempt(runId: $runId, status: $status, stage: $stage, startedAt: $startedAt, finishedAt: $finishedAt, errorCode: $errorCode, deadlineAt: $deadlineAt)';
}


}

/// @nodoc
abstract mixin class _$ResearchLatestAttemptCopyWith<$Res> implements $ResearchLatestAttemptCopyWith<$Res> {
  factory _$ResearchLatestAttemptCopyWith(_ResearchLatestAttempt value, $Res Function(_ResearchLatestAttempt) _then) = __$ResearchLatestAttemptCopyWithImpl;
@override @useResult
$Res call({
 String runId, RunStatus status, String? stage, String? startedAt, String? finishedAt, String? errorCode, String deadlineAt
});




}
/// @nodoc
class __$ResearchLatestAttemptCopyWithImpl<$Res>
    implements _$ResearchLatestAttemptCopyWith<$Res> {
  __$ResearchLatestAttemptCopyWithImpl(this._self, this._then);

  final _ResearchLatestAttempt _self;
  final $Res Function(_ResearchLatestAttempt) _then;

/// Create a copy of ResearchLatestAttempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? status = null,Object? stage = freezed,Object? startedAt = freezed,Object? finishedAt = freezed,Object? errorCode = freezed,Object? deadlineAt = null,}) {
  return _then(_ResearchLatestAttempt(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AssessmentPage {

 List<ResearchAssessment> get assessments; String? get nextCursor;
/// Create a copy of AssessmentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssessmentPageCopyWith<AssessmentPage> get copyWith => _$AssessmentPageCopyWithImpl<AssessmentPage>(this as AssessmentPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssessmentPage&&const DeepCollectionEquality().equals(other.assessments, assessments)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(assessments),nextCursor);

@override
String toString() {
  return 'AssessmentPage(assessments: $assessments, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $AssessmentPageCopyWith<$Res>  {
  factory $AssessmentPageCopyWith(AssessmentPage value, $Res Function(AssessmentPage) _then) = _$AssessmentPageCopyWithImpl;
@useResult
$Res call({
 List<ResearchAssessment> assessments, String? nextCursor
});




}
/// @nodoc
class _$AssessmentPageCopyWithImpl<$Res>
    implements $AssessmentPageCopyWith<$Res> {
  _$AssessmentPageCopyWithImpl(this._self, this._then);

  final AssessmentPage _self;
  final $Res Function(AssessmentPage) _then;

/// Create a copy of AssessmentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assessments = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
assessments: null == assessments ? _self.assessments : assessments // ignore: cast_nullable_to_non_nullable
as List<ResearchAssessment>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssessmentPage].
extension AssessmentPagePatterns on AssessmentPage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssessmentPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssessmentPage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssessmentPage value)  $default,){
final _that = this;
switch (_that) {
case _AssessmentPage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssessmentPage value)?  $default,){
final _that = this;
switch (_that) {
case _AssessmentPage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ResearchAssessment> assessments,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssessmentPage() when $default != null:
return $default(_that.assessments,_that.nextCursor);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ResearchAssessment> assessments,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _AssessmentPage():
return $default(_that.assessments,_that.nextCursor);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ResearchAssessment> assessments,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _AssessmentPage() when $default != null:
return $default(_that.assessments,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc


class _AssessmentPage implements AssessmentPage {
  const _AssessmentPage({required final  List<ResearchAssessment> assessments, required this.nextCursor}): _assessments = assessments;
  

 final  List<ResearchAssessment> _assessments;
@override List<ResearchAssessment> get assessments {
  if (_assessments is EqualUnmodifiableListView) return _assessments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assessments);
}

@override final  String? nextCursor;

/// Create a copy of AssessmentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssessmentPageCopyWith<_AssessmentPage> get copyWith => __$AssessmentPageCopyWithImpl<_AssessmentPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssessmentPage&&const DeepCollectionEquality().equals(other._assessments, _assessments)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_assessments),nextCursor);

@override
String toString() {
  return 'AssessmentPage(assessments: $assessments, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$AssessmentPageCopyWith<$Res> implements $AssessmentPageCopyWith<$Res> {
  factory _$AssessmentPageCopyWith(_AssessmentPage value, $Res Function(_AssessmentPage) _then) = __$AssessmentPageCopyWithImpl;
@override @useResult
$Res call({
 List<ResearchAssessment> assessments, String? nextCursor
});




}
/// @nodoc
class __$AssessmentPageCopyWithImpl<$Res>
    implements _$AssessmentPageCopyWith<$Res> {
  __$AssessmentPageCopyWithImpl(this._self, this._then);

  final _AssessmentPage _self;
  final $Res Function(_AssessmentPage) _then;

/// Create a copy of AssessmentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assessments = null,Object? nextCursor = freezed,}) {
  return _then(_AssessmentPage(
assessments: null == assessments ? _self._assessments : assessments // ignore: cast_nullable_to_non_nullable
as List<ResearchAssessment>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
