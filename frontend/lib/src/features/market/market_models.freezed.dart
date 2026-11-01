// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InstrumentIdentity {

 String get instrumentId; String get symbol; String get exchange; String get currency; String get providerSymbol;
/// Create a copy of InstrumentIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstrumentIdentityCopyWith<InstrumentIdentity> get copyWith => _$InstrumentIdentityCopyWithImpl<InstrumentIdentity>(this as InstrumentIdentity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstrumentIdentity&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.providerSymbol, providerSymbol) || other.providerSymbol == providerSymbol));
}


@override
int get hashCode => Object.hash(runtimeType,instrumentId,symbol,exchange,currency,providerSymbol);

@override
String toString() {
  return 'InstrumentIdentity(instrumentId: $instrumentId, symbol: $symbol, exchange: $exchange, currency: $currency, providerSymbol: $providerSymbol)';
}


}

/// @nodoc
abstract mixin class $InstrumentIdentityCopyWith<$Res>  {
  factory $InstrumentIdentityCopyWith(InstrumentIdentity value, $Res Function(InstrumentIdentity) _then) = _$InstrumentIdentityCopyWithImpl;
@useResult
$Res call({
 String instrumentId, String symbol, String exchange, String currency, String providerSymbol
});




}
/// @nodoc
class _$InstrumentIdentityCopyWithImpl<$Res>
    implements $InstrumentIdentityCopyWith<$Res> {
  _$InstrumentIdentityCopyWithImpl(this._self, this._then);

  final InstrumentIdentity _self;
  final $Res Function(InstrumentIdentity) _then;

/// Create a copy of InstrumentIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instrumentId = null,Object? symbol = null,Object? exchange = null,Object? currency = null,Object? providerSymbol = null,}) {
  return _then(_self.copyWith(
instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,providerSymbol: null == providerSymbol ? _self.providerSymbol : providerSymbol // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InstrumentIdentity].
extension InstrumentIdentityPatterns on InstrumentIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstrumentIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstrumentIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstrumentIdentity value)  $default,){
final _that = this;
switch (_that) {
case _InstrumentIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstrumentIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _InstrumentIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String instrumentId,  String symbol,  String exchange,  String currency,  String providerSymbol)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstrumentIdentity() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String instrumentId,  String symbol,  String exchange,  String currency,  String providerSymbol)  $default,) {final _that = this;
switch (_that) {
case _InstrumentIdentity():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String instrumentId,  String symbol,  String exchange,  String currency,  String providerSymbol)?  $default,) {final _that = this;
switch (_that) {
case _InstrumentIdentity() when $default != null:
return $default(_that.instrumentId,_that.symbol,_that.exchange,_that.currency,_that.providerSymbol);case _:
  return null;

}
}

}

/// @nodoc


class _InstrumentIdentity implements InstrumentIdentity {
  const _InstrumentIdentity({required this.instrumentId, required this.symbol, required this.exchange, required this.currency, required this.providerSymbol});
  

@override final  String instrumentId;
@override final  String symbol;
@override final  String exchange;
@override final  String currency;
@override final  String providerSymbol;

/// Create a copy of InstrumentIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstrumentIdentityCopyWith<_InstrumentIdentity> get copyWith => __$InstrumentIdentityCopyWithImpl<_InstrumentIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstrumentIdentity&&(identical(other.instrumentId, instrumentId) || other.instrumentId == instrumentId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.providerSymbol, providerSymbol) || other.providerSymbol == providerSymbol));
}


@override
int get hashCode => Object.hash(runtimeType,instrumentId,symbol,exchange,currency,providerSymbol);

@override
String toString() {
  return 'InstrumentIdentity(instrumentId: $instrumentId, symbol: $symbol, exchange: $exchange, currency: $currency, providerSymbol: $providerSymbol)';
}


}

/// @nodoc
abstract mixin class _$InstrumentIdentityCopyWith<$Res> implements $InstrumentIdentityCopyWith<$Res> {
  factory _$InstrumentIdentityCopyWith(_InstrumentIdentity value, $Res Function(_InstrumentIdentity) _then) = __$InstrumentIdentityCopyWithImpl;
@override @useResult
$Res call({
 String instrumentId, String symbol, String exchange, String currency, String providerSymbol
});




}
/// @nodoc
class __$InstrumentIdentityCopyWithImpl<$Res>
    implements _$InstrumentIdentityCopyWith<$Res> {
  __$InstrumentIdentityCopyWithImpl(this._self, this._then);

  final _InstrumentIdentity _self;
  final $Res Function(_InstrumentIdentity) _then;

/// Create a copy of InstrumentIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instrumentId = null,Object? symbol = null,Object? exchange = null,Object? currency = null,Object? providerSymbol = null,}) {
  return _then(_InstrumentIdentity(
instrumentId: null == instrumentId ? _self.instrumentId : instrumentId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,providerSymbol: null == providerSymbol ? _self.providerSymbol : providerSymbol // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MarketBar {

 String get time; String get sessionDate; double get open; double get high; double get low; double get close; int? get volume; double? get adjustedClose; bool get isFinal;
/// Create a copy of MarketBar
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketBarCopyWith<MarketBar> get copyWith => _$MarketBarCopyWithImpl<MarketBar>(this as MarketBar, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketBar&&(identical(other.time, time) || other.time == time)&&(identical(other.sessionDate, sessionDate) || other.sessionDate == sessionDate)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.close, close) || other.close == close)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.adjustedClose, adjustedClose) || other.adjustedClose == adjustedClose)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal));
}


@override
int get hashCode => Object.hash(runtimeType,time,sessionDate,open,high,low,close,volume,adjustedClose,isFinal);

@override
String toString() {
  return 'MarketBar(time: $time, sessionDate: $sessionDate, open: $open, high: $high, low: $low, close: $close, volume: $volume, adjustedClose: $adjustedClose, isFinal: $isFinal)';
}


}

/// @nodoc
abstract mixin class $MarketBarCopyWith<$Res>  {
  factory $MarketBarCopyWith(MarketBar value, $Res Function(MarketBar) _then) = _$MarketBarCopyWithImpl;
@useResult
$Res call({
 String time, String sessionDate, double open, double high, double low, double close, int? volume, double? adjustedClose, bool isFinal
});




}
/// @nodoc
class _$MarketBarCopyWithImpl<$Res>
    implements $MarketBarCopyWith<$Res> {
  _$MarketBarCopyWithImpl(this._self, this._then);

  final MarketBar _self;
  final $Res Function(MarketBar) _then;

/// Create a copy of MarketBar
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? sessionDate = null,Object? open = null,Object? high = null,Object? low = null,Object? close = null,Object? volume = freezed,Object? adjustedClose = freezed,Object? isFinal = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,sessionDate: null == sessionDate ? _self.sessionDate : sessionDate // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as double,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as double,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as double,close: null == close ? _self.close : close // ignore: cast_nullable_to_non_nullable
as double,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int?,adjustedClose: freezed == adjustedClose ? _self.adjustedClose : adjustedClose // ignore: cast_nullable_to_non_nullable
as double?,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketBar].
extension MarketBarPatterns on MarketBar {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketBar value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketBar() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketBar value)  $default,){
final _that = this;
switch (_that) {
case _MarketBar():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketBar value)?  $default,){
final _that = this;
switch (_that) {
case _MarketBar() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String time,  String sessionDate,  double open,  double high,  double low,  double close,  int? volume,  double? adjustedClose,  bool isFinal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketBar() when $default != null:
return $default(_that.time,_that.sessionDate,_that.open,_that.high,_that.low,_that.close,_that.volume,_that.adjustedClose,_that.isFinal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String time,  String sessionDate,  double open,  double high,  double low,  double close,  int? volume,  double? adjustedClose,  bool isFinal)  $default,) {final _that = this;
switch (_that) {
case _MarketBar():
return $default(_that.time,_that.sessionDate,_that.open,_that.high,_that.low,_that.close,_that.volume,_that.adjustedClose,_that.isFinal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String time,  String sessionDate,  double open,  double high,  double low,  double close,  int? volume,  double? adjustedClose,  bool isFinal)?  $default,) {final _that = this;
switch (_that) {
case _MarketBar() when $default != null:
return $default(_that.time,_that.sessionDate,_that.open,_that.high,_that.low,_that.close,_that.volume,_that.adjustedClose,_that.isFinal);case _:
  return null;

}
}

}

/// @nodoc


class _MarketBar implements MarketBar {
  const _MarketBar({required this.time, required this.sessionDate, required this.open, required this.high, required this.low, required this.close, required this.volume, required this.adjustedClose, required this.isFinal});
  

@override final  String time;
@override final  String sessionDate;
@override final  double open;
@override final  double high;
@override final  double low;
@override final  double close;
@override final  int? volume;
@override final  double? adjustedClose;
@override final  bool isFinal;

/// Create a copy of MarketBar
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketBarCopyWith<_MarketBar> get copyWith => __$MarketBarCopyWithImpl<_MarketBar>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketBar&&(identical(other.time, time) || other.time == time)&&(identical(other.sessionDate, sessionDate) || other.sessionDate == sessionDate)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.close, close) || other.close == close)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.adjustedClose, adjustedClose) || other.adjustedClose == adjustedClose)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal));
}


@override
int get hashCode => Object.hash(runtimeType,time,sessionDate,open,high,low,close,volume,adjustedClose,isFinal);

@override
String toString() {
  return 'MarketBar(time: $time, sessionDate: $sessionDate, open: $open, high: $high, low: $low, close: $close, volume: $volume, adjustedClose: $adjustedClose, isFinal: $isFinal)';
}


}

/// @nodoc
abstract mixin class _$MarketBarCopyWith<$Res> implements $MarketBarCopyWith<$Res> {
  factory _$MarketBarCopyWith(_MarketBar value, $Res Function(_MarketBar) _then) = __$MarketBarCopyWithImpl;
@override @useResult
$Res call({
 String time, String sessionDate, double open, double high, double low, double close, int? volume, double? adjustedClose, bool isFinal
});




}
/// @nodoc
class __$MarketBarCopyWithImpl<$Res>
    implements _$MarketBarCopyWith<$Res> {
  __$MarketBarCopyWithImpl(this._self, this._then);

  final _MarketBar _self;
  final $Res Function(_MarketBar) _then;

/// Create a copy of MarketBar
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? sessionDate = null,Object? open = null,Object? high = null,Object? low = null,Object? close = null,Object? volume = freezed,Object? adjustedClose = freezed,Object? isFinal = null,}) {
  return _then(_MarketBar(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,sessionDate: null == sessionDate ? _self.sessionDate : sessionDate // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as double,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as double,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as double,close: null == close ? _self.close : close // ignore: cast_nullable_to_non_nullable
as double,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int?,adjustedClose: freezed == adjustedClose ? _self.adjustedClose : adjustedClose // ignore: cast_nullable_to_non_nullable
as double?,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$MarketWarning {

 String get code; Map<String, dynamic> get extra;
/// Create a copy of MarketWarning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketWarningCopyWith<MarketWarning> get copyWith => _$MarketWarningCopyWithImpl<MarketWarning>(this as MarketWarning, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketWarning&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other.extra, extra));
}


@override
int get hashCode => Object.hash(runtimeType,code,const DeepCollectionEquality().hash(extra));

@override
String toString() {
  return 'MarketWarning(code: $code, extra: $extra)';
}


}

/// @nodoc
abstract mixin class $MarketWarningCopyWith<$Res>  {
  factory $MarketWarningCopyWith(MarketWarning value, $Res Function(MarketWarning) _then) = _$MarketWarningCopyWithImpl;
@useResult
$Res call({
 String code, Map<String, dynamic> extra
});




}
/// @nodoc
class _$MarketWarningCopyWithImpl<$Res>
    implements $MarketWarningCopyWith<$Res> {
  _$MarketWarningCopyWithImpl(this._self, this._then);

  final MarketWarning _self;
  final $Res Function(MarketWarning) _then;

/// Create a copy of MarketWarning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? extra = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketWarning].
extension MarketWarningPatterns on MarketWarning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketWarning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketWarning() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketWarning value)  $default,){
final _that = this;
switch (_that) {
case _MarketWarning():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketWarning value)?  $default,){
final _that = this;
switch (_that) {
case _MarketWarning() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  Map<String, dynamic> extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketWarning() when $default != null:
return $default(_that.code,_that.extra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  Map<String, dynamic> extra)  $default,) {final _that = this;
switch (_that) {
case _MarketWarning():
return $default(_that.code,_that.extra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  Map<String, dynamic> extra)?  $default,) {final _that = this;
switch (_that) {
case _MarketWarning() when $default != null:
return $default(_that.code,_that.extra);case _:
  return null;

}
}

}

/// @nodoc


class _MarketWarning implements MarketWarning {
  const _MarketWarning({required this.code, required final  Map<String, dynamic> extra}): _extra = extra;
  

@override final  String code;
 final  Map<String, dynamic> _extra;
@override Map<String, dynamic> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}


/// Create a copy of MarketWarning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketWarningCopyWith<_MarketWarning> get copyWith => __$MarketWarningCopyWithImpl<_MarketWarning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketWarning&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other._extra, _extra));
}


@override
int get hashCode => Object.hash(runtimeType,code,const DeepCollectionEquality().hash(_extra));

@override
String toString() {
  return 'MarketWarning(code: $code, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$MarketWarningCopyWith<$Res> implements $MarketWarningCopyWith<$Res> {
  factory _$MarketWarningCopyWith(_MarketWarning value, $Res Function(_MarketWarning) _then) = __$MarketWarningCopyWithImpl;
@override @useResult
$Res call({
 String code, Map<String, dynamic> extra
});




}
/// @nodoc
class __$MarketWarningCopyWithImpl<$Res>
    implements _$MarketWarningCopyWith<$Res> {
  __$MarketWarningCopyWithImpl(this._self, this._then);

  final _MarketWarning _self;
  final $Res Function(_MarketWarning) _then;

/// Create a copy of MarketWarning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? extra = null,}) {
  return _then(_MarketWarning(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$HistoryResponse {

 int get contractVersion; InstrumentIdentity get instrument; String? get snapshotId; MarketRange get range; String get requestedResolution; String get actualResolution; String get exchangeTimezone; SessionMode get sessionMode; String get adjustmentBasis; String? get asOf; String get fetchedAt; DataStatus get dataStatus; DelayStatus get delayStatus; bool get isStale; List<MarketRange> get availableRanges; List<MarketBar> get bars; List<MarketWarning> get warnings; String? get nextCursor; String? get unavailableReason;
/// Create a copy of HistoryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryResponseCopyWith<HistoryResponse> get copyWith => _$HistoryResponseCopyWithImpl<HistoryResponse>(this as HistoryResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryResponse&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&(identical(other.range, range) || other.range == range)&&(identical(other.requestedResolution, requestedResolution) || other.requestedResolution == requestedResolution)&&(identical(other.actualResolution, actualResolution) || other.actualResolution == actualResolution)&&(identical(other.exchangeTimezone, exchangeTimezone) || other.exchangeTimezone == exchangeTimezone)&&(identical(other.sessionMode, sessionMode) || other.sessionMode == sessionMode)&&(identical(other.adjustmentBasis, adjustmentBasis) || other.adjustmentBasis == adjustmentBasis)&&(identical(other.asOf, asOf) || other.asOf == asOf)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.dataStatus, dataStatus) || other.dataStatus == dataStatus)&&(identical(other.delayStatus, delayStatus) || other.delayStatus == delayStatus)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&const DeepCollectionEquality().equals(other.availableRanges, availableRanges)&&const DeepCollectionEquality().equals(other.bars, bars)&&const DeepCollectionEquality().equals(other.warnings, warnings)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.unavailableReason, unavailableReason) || other.unavailableReason == unavailableReason));
}


@override
int get hashCode => Object.hashAll([runtimeType,contractVersion,instrument,snapshotId,range,requestedResolution,actualResolution,exchangeTimezone,sessionMode,adjustmentBasis,asOf,fetchedAt,dataStatus,delayStatus,isStale,const DeepCollectionEquality().hash(availableRanges),const DeepCollectionEquality().hash(bars),const DeepCollectionEquality().hash(warnings),nextCursor,unavailableReason]);

@override
String toString() {
  return 'HistoryResponse(contractVersion: $contractVersion, instrument: $instrument, snapshotId: $snapshotId, range: $range, requestedResolution: $requestedResolution, actualResolution: $actualResolution, exchangeTimezone: $exchangeTimezone, sessionMode: $sessionMode, adjustmentBasis: $adjustmentBasis, asOf: $asOf, fetchedAt: $fetchedAt, dataStatus: $dataStatus, delayStatus: $delayStatus, isStale: $isStale, availableRanges: $availableRanges, bars: $bars, warnings: $warnings, nextCursor: $nextCursor, unavailableReason: $unavailableReason)';
}


}

/// @nodoc
abstract mixin class $HistoryResponseCopyWith<$Res>  {
  factory $HistoryResponseCopyWith(HistoryResponse value, $Res Function(HistoryResponse) _then) = _$HistoryResponseCopyWithImpl;
@useResult
$Res call({
 int contractVersion, InstrumentIdentity instrument, String? snapshotId, MarketRange range, String requestedResolution, String actualResolution, String exchangeTimezone, SessionMode sessionMode, String adjustmentBasis, String? asOf, String fetchedAt, DataStatus dataStatus, DelayStatus delayStatus, bool isStale, List<MarketRange> availableRanges, List<MarketBar> bars, List<MarketWarning> warnings, String? nextCursor, String? unavailableReason
});


$InstrumentIdentityCopyWith<$Res> get instrument;

}
/// @nodoc
class _$HistoryResponseCopyWithImpl<$Res>
    implements $HistoryResponseCopyWith<$Res> {
  _$HistoryResponseCopyWithImpl(this._self, this._then);

  final HistoryResponse _self;
  final $Res Function(HistoryResponse) _then;

/// Create a copy of HistoryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractVersion = null,Object? instrument = null,Object? snapshotId = freezed,Object? range = null,Object? requestedResolution = null,Object? actualResolution = null,Object? exchangeTimezone = null,Object? sessionMode = null,Object? adjustmentBasis = null,Object? asOf = freezed,Object? fetchedAt = null,Object? dataStatus = null,Object? delayStatus = null,Object? isStale = null,Object? availableRanges = null,Object? bars = null,Object? warnings = null,Object? nextCursor = freezed,Object? unavailableReason = freezed,}) {
  return _then(_self.copyWith(
contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as int,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as InstrumentIdentity,snapshotId: freezed == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String?,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as MarketRange,requestedResolution: null == requestedResolution ? _self.requestedResolution : requestedResolution // ignore: cast_nullable_to_non_nullable
as String,actualResolution: null == actualResolution ? _self.actualResolution : actualResolution // ignore: cast_nullable_to_non_nullable
as String,exchangeTimezone: null == exchangeTimezone ? _self.exchangeTimezone : exchangeTimezone // ignore: cast_nullable_to_non_nullable
as String,sessionMode: null == sessionMode ? _self.sessionMode : sessionMode // ignore: cast_nullable_to_non_nullable
as SessionMode,adjustmentBasis: null == adjustmentBasis ? _self.adjustmentBasis : adjustmentBasis // ignore: cast_nullable_to_non_nullable
as String,asOf: freezed == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String?,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as String,dataStatus: null == dataStatus ? _self.dataStatus : dataStatus // ignore: cast_nullable_to_non_nullable
as DataStatus,delayStatus: null == delayStatus ? _self.delayStatus : delayStatus // ignore: cast_nullable_to_non_nullable
as DelayStatus,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,availableRanges: null == availableRanges ? _self.availableRanges : availableRanges // ignore: cast_nullable_to_non_nullable
as List<MarketRange>,bars: null == bars ? _self.bars : bars // ignore: cast_nullable_to_non_nullable
as List<MarketBar>,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<MarketWarning>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,unavailableReason: freezed == unavailableReason ? _self.unavailableReason : unavailableReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of HistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstrumentIdentityCopyWith<$Res> get instrument {
  
  return $InstrumentIdentityCopyWith<$Res>(_self.instrument, (value) {
    return _then(_self.copyWith(instrument: value));
  });
}
}


/// Adds pattern-matching-related methods to [HistoryResponse].
extension HistoryResponsePatterns on HistoryResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryResponse value)  $default,){
final _that = this;
switch (_that) {
case _HistoryResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryResponse value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int contractVersion,  InstrumentIdentity instrument,  String? snapshotId,  MarketRange range,  String requestedResolution,  String actualResolution,  String exchangeTimezone,  SessionMode sessionMode,  String adjustmentBasis,  String? asOf,  String fetchedAt,  DataStatus dataStatus,  DelayStatus delayStatus,  bool isStale,  List<MarketRange> availableRanges,  List<MarketBar> bars,  List<MarketWarning> warnings,  String? nextCursor,  String? unavailableReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryResponse() when $default != null:
return $default(_that.contractVersion,_that.instrument,_that.snapshotId,_that.range,_that.requestedResolution,_that.actualResolution,_that.exchangeTimezone,_that.sessionMode,_that.adjustmentBasis,_that.asOf,_that.fetchedAt,_that.dataStatus,_that.delayStatus,_that.isStale,_that.availableRanges,_that.bars,_that.warnings,_that.nextCursor,_that.unavailableReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int contractVersion,  InstrumentIdentity instrument,  String? snapshotId,  MarketRange range,  String requestedResolution,  String actualResolution,  String exchangeTimezone,  SessionMode sessionMode,  String adjustmentBasis,  String? asOf,  String fetchedAt,  DataStatus dataStatus,  DelayStatus delayStatus,  bool isStale,  List<MarketRange> availableRanges,  List<MarketBar> bars,  List<MarketWarning> warnings,  String? nextCursor,  String? unavailableReason)  $default,) {final _that = this;
switch (_that) {
case _HistoryResponse():
return $default(_that.contractVersion,_that.instrument,_that.snapshotId,_that.range,_that.requestedResolution,_that.actualResolution,_that.exchangeTimezone,_that.sessionMode,_that.adjustmentBasis,_that.asOf,_that.fetchedAt,_that.dataStatus,_that.delayStatus,_that.isStale,_that.availableRanges,_that.bars,_that.warnings,_that.nextCursor,_that.unavailableReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int contractVersion,  InstrumentIdentity instrument,  String? snapshotId,  MarketRange range,  String requestedResolution,  String actualResolution,  String exchangeTimezone,  SessionMode sessionMode,  String adjustmentBasis,  String? asOf,  String fetchedAt,  DataStatus dataStatus,  DelayStatus delayStatus,  bool isStale,  List<MarketRange> availableRanges,  List<MarketBar> bars,  List<MarketWarning> warnings,  String? nextCursor,  String? unavailableReason)?  $default,) {final _that = this;
switch (_that) {
case _HistoryResponse() when $default != null:
return $default(_that.contractVersion,_that.instrument,_that.snapshotId,_that.range,_that.requestedResolution,_that.actualResolution,_that.exchangeTimezone,_that.sessionMode,_that.adjustmentBasis,_that.asOf,_that.fetchedAt,_that.dataStatus,_that.delayStatus,_that.isStale,_that.availableRanges,_that.bars,_that.warnings,_that.nextCursor,_that.unavailableReason);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryResponse implements HistoryResponse {
  const _HistoryResponse({required this.contractVersion, required this.instrument, required this.snapshotId, required this.range, required this.requestedResolution, required this.actualResolution, required this.exchangeTimezone, required this.sessionMode, required this.adjustmentBasis, required this.asOf, required this.fetchedAt, required this.dataStatus, required this.delayStatus, required this.isStale, required final  List<MarketRange> availableRanges, required final  List<MarketBar> bars, required final  List<MarketWarning> warnings, required this.nextCursor, required this.unavailableReason}): _availableRanges = availableRanges,_bars = bars,_warnings = warnings;
  

@override final  int contractVersion;
@override final  InstrumentIdentity instrument;
@override final  String? snapshotId;
@override final  MarketRange range;
@override final  String requestedResolution;
@override final  String actualResolution;
@override final  String exchangeTimezone;
@override final  SessionMode sessionMode;
@override final  String adjustmentBasis;
@override final  String? asOf;
@override final  String fetchedAt;
@override final  DataStatus dataStatus;
@override final  DelayStatus delayStatus;
@override final  bool isStale;
 final  List<MarketRange> _availableRanges;
@override List<MarketRange> get availableRanges {
  if (_availableRanges is EqualUnmodifiableListView) return _availableRanges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableRanges);
}

 final  List<MarketBar> _bars;
@override List<MarketBar> get bars {
  if (_bars is EqualUnmodifiableListView) return _bars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bars);
}

 final  List<MarketWarning> _warnings;
@override List<MarketWarning> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}

@override final  String? nextCursor;
@override final  String? unavailableReason;

/// Create a copy of HistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryResponseCopyWith<_HistoryResponse> get copyWith => __$HistoryResponseCopyWithImpl<_HistoryResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryResponse&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&(identical(other.range, range) || other.range == range)&&(identical(other.requestedResolution, requestedResolution) || other.requestedResolution == requestedResolution)&&(identical(other.actualResolution, actualResolution) || other.actualResolution == actualResolution)&&(identical(other.exchangeTimezone, exchangeTimezone) || other.exchangeTimezone == exchangeTimezone)&&(identical(other.sessionMode, sessionMode) || other.sessionMode == sessionMode)&&(identical(other.adjustmentBasis, adjustmentBasis) || other.adjustmentBasis == adjustmentBasis)&&(identical(other.asOf, asOf) || other.asOf == asOf)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.dataStatus, dataStatus) || other.dataStatus == dataStatus)&&(identical(other.delayStatus, delayStatus) || other.delayStatus == delayStatus)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&const DeepCollectionEquality().equals(other._availableRanges, _availableRanges)&&const DeepCollectionEquality().equals(other._bars, _bars)&&const DeepCollectionEquality().equals(other._warnings, _warnings)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.unavailableReason, unavailableReason) || other.unavailableReason == unavailableReason));
}


@override
int get hashCode => Object.hashAll([runtimeType,contractVersion,instrument,snapshotId,range,requestedResolution,actualResolution,exchangeTimezone,sessionMode,adjustmentBasis,asOf,fetchedAt,dataStatus,delayStatus,isStale,const DeepCollectionEquality().hash(_availableRanges),const DeepCollectionEquality().hash(_bars),const DeepCollectionEquality().hash(_warnings),nextCursor,unavailableReason]);

@override
String toString() {
  return 'HistoryResponse(contractVersion: $contractVersion, instrument: $instrument, snapshotId: $snapshotId, range: $range, requestedResolution: $requestedResolution, actualResolution: $actualResolution, exchangeTimezone: $exchangeTimezone, sessionMode: $sessionMode, adjustmentBasis: $adjustmentBasis, asOf: $asOf, fetchedAt: $fetchedAt, dataStatus: $dataStatus, delayStatus: $delayStatus, isStale: $isStale, availableRanges: $availableRanges, bars: $bars, warnings: $warnings, nextCursor: $nextCursor, unavailableReason: $unavailableReason)';
}


}

/// @nodoc
abstract mixin class _$HistoryResponseCopyWith<$Res> implements $HistoryResponseCopyWith<$Res> {
  factory _$HistoryResponseCopyWith(_HistoryResponse value, $Res Function(_HistoryResponse) _then) = __$HistoryResponseCopyWithImpl;
@override @useResult
$Res call({
 int contractVersion, InstrumentIdentity instrument, String? snapshotId, MarketRange range, String requestedResolution, String actualResolution, String exchangeTimezone, SessionMode sessionMode, String adjustmentBasis, String? asOf, String fetchedAt, DataStatus dataStatus, DelayStatus delayStatus, bool isStale, List<MarketRange> availableRanges, List<MarketBar> bars, List<MarketWarning> warnings, String? nextCursor, String? unavailableReason
});


@override $InstrumentIdentityCopyWith<$Res> get instrument;

}
/// @nodoc
class __$HistoryResponseCopyWithImpl<$Res>
    implements _$HistoryResponseCopyWith<$Res> {
  __$HistoryResponseCopyWithImpl(this._self, this._then);

  final _HistoryResponse _self;
  final $Res Function(_HistoryResponse) _then;

/// Create a copy of HistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractVersion = null,Object? instrument = null,Object? snapshotId = freezed,Object? range = null,Object? requestedResolution = null,Object? actualResolution = null,Object? exchangeTimezone = null,Object? sessionMode = null,Object? adjustmentBasis = null,Object? asOf = freezed,Object? fetchedAt = null,Object? dataStatus = null,Object? delayStatus = null,Object? isStale = null,Object? availableRanges = null,Object? bars = null,Object? warnings = null,Object? nextCursor = freezed,Object? unavailableReason = freezed,}) {
  return _then(_HistoryResponse(
contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as int,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as InstrumentIdentity,snapshotId: freezed == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String?,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as MarketRange,requestedResolution: null == requestedResolution ? _self.requestedResolution : requestedResolution // ignore: cast_nullable_to_non_nullable
as String,actualResolution: null == actualResolution ? _self.actualResolution : actualResolution // ignore: cast_nullable_to_non_nullable
as String,exchangeTimezone: null == exchangeTimezone ? _self.exchangeTimezone : exchangeTimezone // ignore: cast_nullable_to_non_nullable
as String,sessionMode: null == sessionMode ? _self.sessionMode : sessionMode // ignore: cast_nullable_to_non_nullable
as SessionMode,adjustmentBasis: null == adjustmentBasis ? _self.adjustmentBasis : adjustmentBasis // ignore: cast_nullable_to_non_nullable
as String,asOf: freezed == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String?,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as String,dataStatus: null == dataStatus ? _self.dataStatus : dataStatus // ignore: cast_nullable_to_non_nullable
as DataStatus,delayStatus: null == delayStatus ? _self.delayStatus : delayStatus // ignore: cast_nullable_to_non_nullable
as DelayStatus,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,availableRanges: null == availableRanges ? _self._availableRanges : availableRanges // ignore: cast_nullable_to_non_nullable
as List<MarketRange>,bars: null == bars ? _self._bars : bars // ignore: cast_nullable_to_non_nullable
as List<MarketBar>,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<MarketWarning>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,unavailableReason: freezed == unavailableReason ? _self.unavailableReason : unavailableReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of HistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstrumentIdentityCopyWith<$Res> get instrument {
  
  return $InstrumentIdentityCopyWith<$Res>(_self.instrument, (value) {
    return _then(_self.copyWith(instrument: value));
  });
}
}

// dart format on
