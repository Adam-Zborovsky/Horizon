// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MoneyAmount {

 String get amount; String get currency;
/// Create a copy of MoneyAmount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoneyAmountCopyWith<MoneyAmount> get copyWith => _$MoneyAmountCopyWithImpl<MoneyAmount>(this as MoneyAmount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoneyAmount&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}


@override
int get hashCode => Object.hash(runtimeType,amount,currency);

@override
String toString() {
  return 'MoneyAmount(amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $MoneyAmountCopyWith<$Res>  {
  factory $MoneyAmountCopyWith(MoneyAmount value, $Res Function(MoneyAmount) _then) = _$MoneyAmountCopyWithImpl;
@useResult
$Res call({
 String amount, String currency
});




}
/// @nodoc
class _$MoneyAmountCopyWithImpl<$Res>
    implements $MoneyAmountCopyWith<$Res> {
  _$MoneyAmountCopyWithImpl(this._self, this._then);

  final MoneyAmount _self;
  final $Res Function(MoneyAmount) _then;

/// Create a copy of MoneyAmount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? currency = null,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MoneyAmount].
extension MoneyAmountPatterns on MoneyAmount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoneyAmount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoneyAmount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoneyAmount value)  $default,){
final _that = this;
switch (_that) {
case _MoneyAmount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoneyAmount value)?  $default,){
final _that = this;
switch (_that) {
case _MoneyAmount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String amount,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoneyAmount() when $default != null:
return $default(_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String amount,  String currency)  $default,) {final _that = this;
switch (_that) {
case _MoneyAmount():
return $default(_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String amount,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _MoneyAmount() when $default != null:
return $default(_that.amount,_that.currency);case _:
  return null;

}
}

}

/// @nodoc


class _MoneyAmount implements MoneyAmount {
  const _MoneyAmount({required this.amount, required this.currency});
  

@override final  String amount;
@override final  String currency;

/// Create a copy of MoneyAmount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoneyAmountCopyWith<_MoneyAmount> get copyWith => __$MoneyAmountCopyWithImpl<_MoneyAmount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoneyAmount&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}


@override
int get hashCode => Object.hash(runtimeType,amount,currency);

@override
String toString() {
  return 'MoneyAmount(amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$MoneyAmountCopyWith<$Res> implements $MoneyAmountCopyWith<$Res> {
  factory _$MoneyAmountCopyWith(_MoneyAmount value, $Res Function(_MoneyAmount) _then) = __$MoneyAmountCopyWithImpl;
@override @useResult
$Res call({
 String amount, String currency
});




}
/// @nodoc
class __$MoneyAmountCopyWithImpl<$Res>
    implements _$MoneyAmountCopyWith<$Res> {
  __$MoneyAmountCopyWithImpl(this._self, this._then);

  final _MoneyAmount _self;
  final $Res Function(_MoneyAmount) _then;

/// Create a copy of MoneyAmount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? currency = null,}) {
  return _then(_MoneyAmount(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RiskContext {

 List<String> get constraints; String? get portfolioContext; String get declaredAt; String get source;
/// Create a copy of RiskContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskContextCopyWith<RiskContext> get copyWith => _$RiskContextCopyWithImpl<RiskContext>(this as RiskContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskContext&&const DeepCollectionEquality().equals(other.constraints, constraints)&&(identical(other.portfolioContext, portfolioContext) || other.portfolioContext == portfolioContext)&&(identical(other.declaredAt, declaredAt) || other.declaredAt == declaredAt)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(constraints),portfolioContext,declaredAt,source);

@override
String toString() {
  return 'RiskContext(constraints: $constraints, portfolioContext: $portfolioContext, declaredAt: $declaredAt, source: $source)';
}


}

/// @nodoc
abstract mixin class $RiskContextCopyWith<$Res>  {
  factory $RiskContextCopyWith(RiskContext value, $Res Function(RiskContext) _then) = _$RiskContextCopyWithImpl;
@useResult
$Res call({
 List<String> constraints, String? portfolioContext, String declaredAt, String source
});




}
/// @nodoc
class _$RiskContextCopyWithImpl<$Res>
    implements $RiskContextCopyWith<$Res> {
  _$RiskContextCopyWithImpl(this._self, this._then);

  final RiskContext _self;
  final $Res Function(RiskContext) _then;

/// Create a copy of RiskContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? constraints = null,Object? portfolioContext = freezed,Object? declaredAt = null,Object? source = null,}) {
  return _then(_self.copyWith(
constraints: null == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<String>,portfolioContext: freezed == portfolioContext ? _self.portfolioContext : portfolioContext // ignore: cast_nullable_to_non_nullable
as String?,declaredAt: null == declaredAt ? _self.declaredAt : declaredAt // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RiskContext].
extension RiskContextPatterns on RiskContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiskContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiskContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiskContext value)  $default,){
final _that = this;
switch (_that) {
case _RiskContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiskContext value)?  $default,){
final _that = this;
switch (_that) {
case _RiskContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> constraints,  String? portfolioContext,  String declaredAt,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiskContext() when $default != null:
return $default(_that.constraints,_that.portfolioContext,_that.declaredAt,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> constraints,  String? portfolioContext,  String declaredAt,  String source)  $default,) {final _that = this;
switch (_that) {
case _RiskContext():
return $default(_that.constraints,_that.portfolioContext,_that.declaredAt,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> constraints,  String? portfolioContext,  String declaredAt,  String source)?  $default,) {final _that = this;
switch (_that) {
case _RiskContext() when $default != null:
return $default(_that.constraints,_that.portfolioContext,_that.declaredAt,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _RiskContext implements RiskContext {
  const _RiskContext({required final  List<String> constraints, required this.portfolioContext, required this.declaredAt, required this.source}): _constraints = constraints;
  

 final  List<String> _constraints;
@override List<String> get constraints {
  if (_constraints is EqualUnmodifiableListView) return _constraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_constraints);
}

@override final  String? portfolioContext;
@override final  String declaredAt;
@override final  String source;

/// Create a copy of RiskContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiskContextCopyWith<_RiskContext> get copyWith => __$RiskContextCopyWithImpl<_RiskContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiskContext&&const DeepCollectionEquality().equals(other._constraints, _constraints)&&(identical(other.portfolioContext, portfolioContext) || other.portfolioContext == portfolioContext)&&(identical(other.declaredAt, declaredAt) || other.declaredAt == declaredAt)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_constraints),portfolioContext,declaredAt,source);

@override
String toString() {
  return 'RiskContext(constraints: $constraints, portfolioContext: $portfolioContext, declaredAt: $declaredAt, source: $source)';
}


}

/// @nodoc
abstract mixin class _$RiskContextCopyWith<$Res> implements $RiskContextCopyWith<$Res> {
  factory _$RiskContextCopyWith(_RiskContext value, $Res Function(_RiskContext) _then) = __$RiskContextCopyWithImpl;
@override @useResult
$Res call({
 List<String> constraints, String? portfolioContext, String declaredAt, String source
});




}
/// @nodoc
class __$RiskContextCopyWithImpl<$Res>
    implements _$RiskContextCopyWith<$Res> {
  __$RiskContextCopyWithImpl(this._self, this._then);

  final _RiskContext _self;
  final $Res Function(_RiskContext) _then;

/// Create a copy of RiskContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? constraints = null,Object? portfolioContext = freezed,Object? declaredAt = null,Object? source = null,}) {
  return _then(_RiskContext(
constraints: null == constraints ? _self._constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<String>,portfolioContext: freezed == portfolioContext ? _self.portfolioContext : portfolioContext // ignore: cast_nullable_to_non_nullable
as String?,declaredAt: null == declaredAt ? _self.declaredAt : declaredAt // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PositionInstrument {

 String get instrumentId; String get symbol; String? get exchange; String? get currency; String? get providerSymbol;
/// Create a copy of PositionInstrument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionInstrumentCopyWith<PositionInstrument> get copyWith => _$PositionInstrumentCopyWithImpl<PositionInstrument>(this as PositionInstrument, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionInstrument&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.providerSymbol, providerSymbol) || other.providerSymbol == providerSymbol));
}


@override
int get hashCode => Object.hash(runtimeType,instrumentId,symbol,exchange,currency,providerSymbol);

@override
String toString() {
  return 'PositionInstrument(instrumentId: $instrumentId, symbol: $symbol, exchange: $exchange, currency: $currency, providerSymbol: $providerSymbol)';
}


}

/// @nodoc
abstract mixin class $PositionInstrumentCopyWith<$Res>  {
  factory $PositionInstrumentCopyWith(PositionInstrument value, $Res Function(PositionInstrument) _then) = _$PositionInstrumentCopyWithImpl;
@useResult
$Res call({
 String instrumentId, String symbol, String? exchange, String? currency, String? providerSymbol
});




}
/// @nodoc
class _$PositionInstrumentCopyWithImpl<$Res>
    implements $PositionInstrumentCopyWith<$Res> {
  _$PositionInstrumentCopyWithImpl(this._self, this._then);

  final PositionInstrument _self;
  final $Res Function(PositionInstrument) _then;

/// Create a copy of PositionInstrument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instrumentId = null,Object? symbol = null,Object? exchange = freezed,Object? currency = freezed,Object? providerSymbol = freezed,}) {
  return _then(_self.copyWith(
instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,exchange: freezed == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,providerSymbol: freezed == providerSymbol ? _self.providerSymbol : providerSymbol // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionInstrument].
extension PositionInstrumentPatterns on PositionInstrument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionInstrument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionInstrument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionInstrument value)  $default,){
final _that = this;
switch (_that) {
case _PositionInstrument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionInstrument value)?  $default,){
final _that = this;
switch (_that) {
case _PositionInstrument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String instrumentId,  String symbol,  String? exchange,  String? currency,  String? providerSymbol)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionInstrument() when $default != null:
return $default(_that.instrumentId,_that.symbol,_that.exchange,_that.currency,_that.providerSymbol);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String instrumentId,  String symbol,  String? exchange,  String? currency,  String? providerSymbol)  $default,) {final _that = this;
switch (_that) {
case _PositionInstrument():
return $default(_that.instrumentId,_that.symbol,_that.exchange,_that.currency,_that.providerSymbol);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String instrumentId,  String symbol,  String? exchange,  String? currency,  String? providerSymbol)?  $default,) {final _that = this;
switch (_that) {
case _PositionInstrument() when $default != null:
return $default(_that.instrumentId,_that.symbol,_that.exchange,_that.currency,_that.providerSymbol);case _:
  return null;

}
}

}

/// @nodoc


class _PositionInstrument implements PositionInstrument {
  const _PositionInstrument({required this.instrumentId, required this.symbol, required this.exchange, required this.currency, required this.providerSymbol});
  

@override final  String instrumentId;
@override final  String symbol;
@override final  String? exchange;
@override final  String? currency;
@override final  String? providerSymbol;

/// Create a copy of PositionInstrument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionInstrumentCopyWith<_PositionInstrument> get copyWith => __$PositionInstrumentCopyWithImpl<_PositionInstrument>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionInstrument&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.providerSymbol, providerSymbol) || other.providerSymbol == providerSymbol));
}


@override
int get hashCode => Object.hash(runtimeType,instrumentId,symbol,exchange,currency,providerSymbol);

@override
String toString() {
  return 'PositionInstrument(instrumentId: $instrumentId, symbol: $symbol, exchange: $exchange, currency: $currency, providerSymbol: $providerSymbol)';
}


}

/// @nodoc
abstract mixin class _$PositionInstrumentCopyWith<$Res> implements $PositionInstrumentCopyWith<$Res> {
  factory _$PositionInstrumentCopyWith(_PositionInstrument value, $Res Function(_PositionInstrument) _then) = __$PositionInstrumentCopyWithImpl;
@override @useResult
$Res call({
 String instrumentId, String symbol, String? exchange, String? currency, String? providerSymbol
});




}
/// @nodoc
class __$PositionInstrumentCopyWithImpl<$Res>
    implements _$PositionInstrumentCopyWith<$Res> {
  __$PositionInstrumentCopyWithImpl(this._self, this._then);

  final _PositionInstrument _self;
  final $Res Function(_PositionInstrument) _then;

/// Create a copy of PositionInstrument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instrumentId = null,Object? symbol = null,Object? exchange = freezed,Object? currency = freezed,Object? providerSymbol = freezed,}) {
  return _then(_PositionInstrument(
instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,exchange: freezed == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,providerSymbol: freezed == providerSymbol ? _self.providerSymbol : providerSymbol // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Position {

 String get id; PositionInstrument get instrument; PositionState get state; MoneyAmount? get averageCost; String? get quantity; String? get openedOn; int get preferredHorizonMonths; String? get originalThesis; List<String> get reviewConditions; RiskContext? get riskContext; bool get archived; int get revision; String get createdAt; String get updatedAt;
/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionCopyWith<Position> get copyWith => _$PositionCopyWithImpl<Position>(this as Position, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Position&&(identical(other.id, id) || other.id == id)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.state, state) || other.state == state)&&(identical(other.averageCost, averageCost) || other.averageCost == averageCost)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.preferredHorizonMonths, preferredHorizonMonths) || other.preferredHorizonMonths == preferredHorizonMonths)&&(identical(other.originalThesis, originalThesis) || other.originalThesis == originalThesis)&&const DeepCollectionEquality().equals(other.reviewConditions, reviewConditions)&&(identical(other.riskContext, riskContext) || other.riskContext == riskContext)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,instrument,state,averageCost,quantity,openedOn,preferredHorizonMonths,originalThesis,const DeepCollectionEquality().hash(reviewConditions),riskContext,archived,revision,createdAt,updatedAt);

@override
String toString() {
  return 'Position(id: $id, instrument: $instrument, state: $state, averageCost: $averageCost, quantity: $quantity, openedOn: $openedOn, preferredHorizonMonths: $preferredHorizonMonths, originalThesis: $originalThesis, reviewConditions: $reviewConditions, riskContext: $riskContext, archived: $archived, revision: $revision, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PositionCopyWith<$Res>  {
  factory $PositionCopyWith(Position value, $Res Function(Position) _then) = _$PositionCopyWithImpl;
@useResult
$Res call({
 String id, PositionInstrument instrument, PositionState state, MoneyAmount? averageCost, String? quantity, String? openedOn, int preferredHorizonMonths, String? originalThesis, List<String> reviewConditions, RiskContext? riskContext, bool archived, int revision, String createdAt, String updatedAt
});


$PositionInstrumentCopyWith<$Res> get instrument;$MoneyAmountCopyWith<$Res>? get averageCost;$RiskContextCopyWith<$Res>? get riskContext;

}
/// @nodoc
class _$PositionCopyWithImpl<$Res>
    implements $PositionCopyWith<$Res> {
  _$PositionCopyWithImpl(this._self, this._then);

  final Position _self;
  final $Res Function(Position) _then;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? instrument = null,Object? state = null,Object? averageCost = freezed,Object? quantity = freezed,Object? openedOn = freezed,Object? preferredHorizonMonths = null,Object? originalThesis = freezed,Object? reviewConditions = null,Object? riskContext = freezed,Object? archived = null,Object? revision = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as PositionInstrument,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PositionState,averageCost: freezed == averageCost ? _self.averageCost : averageCost // ignore: cast_nullable_to_non_nullable
as MoneyAmount?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,preferredHorizonMonths: null == preferredHorizonMonths ? _self.preferredHorizonMonths : preferredHorizonMonths // ignore: cast_nullable_to_non_nullable
as int,originalThesis: freezed == originalThesis ? _self.originalThesis : originalThesis // ignore: cast_nullable_to_non_nullable
as String?,reviewConditions: null == reviewConditions ? _self.reviewConditions : reviewConditions // ignore: cast_nullable_to_non_nullable
as List<String>,riskContext: freezed == riskContext ? _self.riskContext : riskContext // ignore: cast_nullable_to_non_nullable
as RiskContext?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionInstrumentCopyWith<$Res> get instrument {
  
  return $PositionInstrumentCopyWith<$Res>(_self.instrument, (value) {
    return _then(_self.copyWith(instrument: value));
  });
}/// Create a copy of Position
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
}/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RiskContextCopyWith<$Res>? get riskContext {
    if (_self.riskContext == null) {
    return null;
  }

  return $RiskContextCopyWith<$Res>(_self.riskContext!, (value) {
    return _then(_self.copyWith(riskContext: value));
  });
}
}


/// Adds pattern-matching-related methods to [Position].
extension PositionPatterns on Position {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Position value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Position() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Position value)  $default,){
final _that = this;
switch (_that) {
case _Position():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Position value)?  $default,){
final _that = this;
switch (_that) {
case _Position() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PositionInstrument instrument,  PositionState state,  MoneyAmount? averageCost,  String? quantity,  String? openedOn,  int preferredHorizonMonths,  String? originalThesis,  List<String> reviewConditions,  RiskContext? riskContext,  bool archived,  int revision,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Position() when $default != null:
return $default(_that.id,_that.instrument,_that.state,_that.averageCost,_that.quantity,_that.openedOn,_that.preferredHorizonMonths,_that.originalThesis,_that.reviewConditions,_that.riskContext,_that.archived,_that.revision,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PositionInstrument instrument,  PositionState state,  MoneyAmount? averageCost,  String? quantity,  String? openedOn,  int preferredHorizonMonths,  String? originalThesis,  List<String> reviewConditions,  RiskContext? riskContext,  bool archived,  int revision,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Position():
return $default(_that.id,_that.instrument,_that.state,_that.averageCost,_that.quantity,_that.openedOn,_that.preferredHorizonMonths,_that.originalThesis,_that.reviewConditions,_that.riskContext,_that.archived,_that.revision,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PositionInstrument instrument,  PositionState state,  MoneyAmount? averageCost,  String? quantity,  String? openedOn,  int preferredHorizonMonths,  String? originalThesis,  List<String> reviewConditions,  RiskContext? riskContext,  bool archived,  int revision,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Position() when $default != null:
return $default(_that.id,_that.instrument,_that.state,_that.averageCost,_that.quantity,_that.openedOn,_that.preferredHorizonMonths,_that.originalThesis,_that.reviewConditions,_that.riskContext,_that.archived,_that.revision,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Position implements Position {
  const _Position({required this.id, required this.instrument, required this.state, required this.averageCost, required this.quantity, required this.openedOn, required this.preferredHorizonMonths, required this.originalThesis, required final  List<String> reviewConditions, required this.riskContext, required this.archived, required this.revision, required this.createdAt, required this.updatedAt}): _reviewConditions = reviewConditions;
  

@override final  String id;
@override final  PositionInstrument instrument;
@override final  PositionState state;
@override final  MoneyAmount? averageCost;
@override final  String? quantity;
@override final  String? openedOn;
@override final  int preferredHorizonMonths;
@override final  String? originalThesis;
 final  List<String> _reviewConditions;
@override List<String> get reviewConditions {
  if (_reviewConditions is EqualUnmodifiableListView) return _reviewConditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reviewConditions);
}

@override final  RiskContext? riskContext;
@override final  bool archived;
@override final  int revision;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionCopyWith<_Position> get copyWith => __$PositionCopyWithImpl<_Position>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Position&&(identical(other.id, id) || other.id == id)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.state, state) || other.state == state)&&(identical(other.averageCost, averageCost) || other.averageCost == averageCost)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.preferredHorizonMonths, preferredHorizonMonths) || other.preferredHorizonMonths == preferredHorizonMonths)&&(identical(other.originalThesis, originalThesis) || other.originalThesis == originalThesis)&&const DeepCollectionEquality().equals(other._reviewConditions, _reviewConditions)&&(identical(other.riskContext, riskContext) || other.riskContext == riskContext)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,instrument,state,averageCost,quantity,openedOn,preferredHorizonMonths,originalThesis,const DeepCollectionEquality().hash(_reviewConditions),riskContext,archived,revision,createdAt,updatedAt);

@override
String toString() {
  return 'Position(id: $id, instrument: $instrument, state: $state, averageCost: $averageCost, quantity: $quantity, openedOn: $openedOn, preferredHorizonMonths: $preferredHorizonMonths, originalThesis: $originalThesis, reviewConditions: $reviewConditions, riskContext: $riskContext, archived: $archived, revision: $revision, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PositionCopyWith<$Res> implements $PositionCopyWith<$Res> {
  factory _$PositionCopyWith(_Position value, $Res Function(_Position) _then) = __$PositionCopyWithImpl;
@override @useResult
$Res call({
 String id, PositionInstrument instrument, PositionState state, MoneyAmount? averageCost, String? quantity, String? openedOn, int preferredHorizonMonths, String? originalThesis, List<String> reviewConditions, RiskContext? riskContext, bool archived, int revision, String createdAt, String updatedAt
});


@override $PositionInstrumentCopyWith<$Res> get instrument;@override $MoneyAmountCopyWith<$Res>? get averageCost;@override $RiskContextCopyWith<$Res>? get riskContext;

}
/// @nodoc
class __$PositionCopyWithImpl<$Res>
    implements _$PositionCopyWith<$Res> {
  __$PositionCopyWithImpl(this._self, this._then);

  final _Position _self;
  final $Res Function(_Position) _then;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? instrument = null,Object? state = null,Object? averageCost = freezed,Object? quantity = freezed,Object? openedOn = freezed,Object? preferredHorizonMonths = null,Object? originalThesis = freezed,Object? reviewConditions = null,Object? riskContext = freezed,Object? archived = null,Object? revision = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Position(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as PositionInstrument,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PositionState,averageCost: freezed == averageCost ? _self.averageCost : averageCost // ignore: cast_nullable_to_non_nullable
as MoneyAmount?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,preferredHorizonMonths: null == preferredHorizonMonths ? _self.preferredHorizonMonths : preferredHorizonMonths // ignore: cast_nullable_to_non_nullable
as int,originalThesis: freezed == originalThesis ? _self.originalThesis : originalThesis // ignore: cast_nullable_to_non_nullable
as String?,reviewConditions: null == reviewConditions ? _self._reviewConditions : reviewConditions // ignore: cast_nullable_to_non_nullable
as List<String>,riskContext: freezed == riskContext ? _self.riskContext : riskContext // ignore: cast_nullable_to_non_nullable
as RiskContext?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionInstrumentCopyWith<$Res> get instrument {
  
  return $PositionInstrumentCopyWith<$Res>(_self.instrument, (value) {
    return _then(_self.copyWith(instrument: value));
  });
}/// Create a copy of Position
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
}/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RiskContextCopyWith<$Res>? get riskContext {
    if (_self.riskContext == null) {
    return null;
  }

  return $RiskContextCopyWith<$Res>(_self.riskContext!, (value) {
    return _then(_self.copyWith(riskContext: value));
  });
}
}

// dart format on
