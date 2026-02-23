// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockData {

 String get ticker; String get name; double get currentPrice; double get changePercent; List<double> get history;// Last 24 hours/points for sparkline
 double get sentiment; String? get analysis; List<String>? get catalysts; List<String>? get risks; String? get potentialPriceAction;
/// Create a copy of StockData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockDataCopyWith<StockData> get copyWith => _$StockDataCopyWithImpl<StockData>(this as StockData, _$identity);

  /// Serializes this StockData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockData&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.changePercent, changePercent) || other.changePercent == changePercent)&&const DeepCollectionEquality().equals(other.history, history)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&const DeepCollectionEquality().equals(other.catalysts, catalysts)&&const DeepCollectionEquality().equals(other.risks, risks)&&(identical(other.potentialPriceAction, potentialPriceAction) || other.potentialPriceAction == potentialPriceAction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticker,name,currentPrice,changePercent,const DeepCollectionEquality().hash(history),sentiment,analysis,const DeepCollectionEquality().hash(catalysts),const DeepCollectionEquality().hash(risks),potentialPriceAction);

@override
String toString() {
  return 'StockData(ticker: $ticker, name: $name, currentPrice: $currentPrice, changePercent: $changePercent, history: $history, sentiment: $sentiment, analysis: $analysis, catalysts: $catalysts, risks: $risks, potentialPriceAction: $potentialPriceAction)';
}


}

/// @nodoc
abstract mixin class $StockDataCopyWith<$Res>  {
  factory $StockDataCopyWith(StockData value, $Res Function(StockData) _then) = _$StockDataCopyWithImpl;
@useResult
$Res call({
 String ticker, String name, double currentPrice, double changePercent, List<double> history, double sentiment, String? analysis, List<String>? catalysts, List<String>? risks, String? potentialPriceAction
});




}
/// @nodoc
class _$StockDataCopyWithImpl<$Res>
    implements $StockDataCopyWith<$Res> {
  _$StockDataCopyWithImpl(this._self, this._then);

  final StockData _self;
  final $Res Function(StockData) _then;

/// Create a copy of StockData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticker = null,Object? name = null,Object? currentPrice = null,Object? changePercent = null,Object? history = null,Object? sentiment = null,Object? analysis = freezed,Object? catalysts = freezed,Object? risks = freezed,Object? potentialPriceAction = freezed,}) {
  return _then(_self.copyWith(
ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as double,changePercent: null == changePercent ? _self.changePercent : changePercent // ignore: cast_nullable_to_non_nullable
as double,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<double>,sentiment: null == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as double,analysis: freezed == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as String?,catalysts: freezed == catalysts ? _self.catalysts : catalysts // ignore: cast_nullable_to_non_nullable
as List<String>?,risks: freezed == risks ? _self.risks : risks // ignore: cast_nullable_to_non_nullable
as List<String>?,potentialPriceAction: freezed == potentialPriceAction ? _self.potentialPriceAction : potentialPriceAction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StockData].
extension StockDataPatterns on StockData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockData value)  $default,){
final _that = this;
switch (_that) {
case _StockData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockData value)?  $default,){
final _that = this;
switch (_that) {
case _StockData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ticker,  String name,  double currentPrice,  double changePercent,  List<double> history,  double sentiment,  String? analysis,  List<String>? catalysts,  List<String>? risks,  String? potentialPriceAction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockData() when $default != null:
return $default(_that.ticker,_that.name,_that.currentPrice,_that.changePercent,_that.history,_that.sentiment,_that.analysis,_that.catalysts,_that.risks,_that.potentialPriceAction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ticker,  String name,  double currentPrice,  double changePercent,  List<double> history,  double sentiment,  String? analysis,  List<String>? catalysts,  List<String>? risks,  String? potentialPriceAction)  $default,) {final _that = this;
switch (_that) {
case _StockData():
return $default(_that.ticker,_that.name,_that.currentPrice,_that.changePercent,_that.history,_that.sentiment,_that.analysis,_that.catalysts,_that.risks,_that.potentialPriceAction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ticker,  String name,  double currentPrice,  double changePercent,  List<double> history,  double sentiment,  String? analysis,  List<String>? catalysts,  List<String>? risks,  String? potentialPriceAction)?  $default,) {final _that = this;
switch (_that) {
case _StockData() when $default != null:
return $default(_that.ticker,_that.name,_that.currentPrice,_that.changePercent,_that.history,_that.sentiment,_that.analysis,_that.catalysts,_that.risks,_that.potentialPriceAction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockData implements StockData {
  const _StockData({required this.ticker, required this.name, required this.currentPrice, required this.changePercent, required final  List<double> history, required this.sentiment, this.analysis, final  List<String>? catalysts, final  List<String>? risks, this.potentialPriceAction}): _history = history,_catalysts = catalysts,_risks = risks;
  factory _StockData.fromJson(Map<String, dynamic> json) => _$StockDataFromJson(json);

@override final  String ticker;
@override final  String name;
@override final  double currentPrice;
@override final  double changePercent;
 final  List<double> _history;
@override List<double> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

// Last 24 hours/points for sparkline
@override final  double sentiment;
@override final  String? analysis;
 final  List<String>? _catalysts;
@override List<String>? get catalysts {
  final value = _catalysts;
  if (value == null) return null;
  if (_catalysts is EqualUnmodifiableListView) return _catalysts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _risks;
@override List<String>? get risks {
  final value = _risks;
  if (value == null) return null;
  if (_risks is EqualUnmodifiableListView) return _risks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? potentialPriceAction;

/// Create a copy of StockData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockDataCopyWith<_StockData> get copyWith => __$StockDataCopyWithImpl<_StockData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockData&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.changePercent, changePercent) || other.changePercent == changePercent)&&const DeepCollectionEquality().equals(other._history, _history)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&const DeepCollectionEquality().equals(other._catalysts, _catalysts)&&const DeepCollectionEquality().equals(other._risks, _risks)&&(identical(other.potentialPriceAction, potentialPriceAction) || other.potentialPriceAction == potentialPriceAction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticker,name,currentPrice,changePercent,const DeepCollectionEquality().hash(_history),sentiment,analysis,const DeepCollectionEquality().hash(_catalysts),const DeepCollectionEquality().hash(_risks),potentialPriceAction);

@override
String toString() {
  return 'StockData(ticker: $ticker, name: $name, currentPrice: $currentPrice, changePercent: $changePercent, history: $history, sentiment: $sentiment, analysis: $analysis, catalysts: $catalysts, risks: $risks, potentialPriceAction: $potentialPriceAction)';
}


}

/// @nodoc
abstract mixin class _$StockDataCopyWith<$Res> implements $StockDataCopyWith<$Res> {
  factory _$StockDataCopyWith(_StockData value, $Res Function(_StockData) _then) = __$StockDataCopyWithImpl;
@override @useResult
$Res call({
 String ticker, String name, double currentPrice, double changePercent, List<double> history, double sentiment, String? analysis, List<String>? catalysts, List<String>? risks, String? potentialPriceAction
});




}
/// @nodoc
class __$StockDataCopyWithImpl<$Res>
    implements _$StockDataCopyWith<$Res> {
  __$StockDataCopyWithImpl(this._self, this._then);

  final _StockData _self;
  final $Res Function(_StockData) _then;

/// Create a copy of StockData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticker = null,Object? name = null,Object? currentPrice = null,Object? changePercent = null,Object? history = null,Object? sentiment = null,Object? analysis = freezed,Object? catalysts = freezed,Object? risks = freezed,Object? potentialPriceAction = freezed,}) {
  return _then(_StockData(
ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as double,changePercent: null == changePercent ? _self.changePercent : changePercent // ignore: cast_nullable_to_non_nullable
as double,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<double>,sentiment: null == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as double,analysis: freezed == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as String?,catalysts: freezed == catalysts ? _self._catalysts : catalysts // ignore: cast_nullable_to_non_nullable
as List<String>?,risks: freezed == risks ? _self._risks : risks // ignore: cast_nullable_to_non_nullable
as List<String>?,potentialPriceAction: freezed == potentialPriceAction ? _self.potentialPriceAction : potentialPriceAction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
