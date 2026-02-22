// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'briefing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BriefingData {

 Map<String, CategoryData> get data; String? get message; bool get success;
/// Create a copy of BriefingData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefingDataCopyWith<BriefingData> get copyWith => _$BriefingDataCopyWithImpl<BriefingData>(this as BriefingData, _$identity);

  /// Serializes this BriefingData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefingData&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.message, message) || other.message == message)&&(identical(other.success, success) || other.success == success));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),message,success);

@override
String toString() {
  return 'BriefingData(data: $data, message: $message, success: $success)';
}


}

/// @nodoc
abstract mixin class $BriefingDataCopyWith<$Res>  {
  factory $BriefingDataCopyWith(BriefingData value, $Res Function(BriefingData) _then) = _$BriefingDataCopyWithImpl;
@useResult
$Res call({
 Map<String, CategoryData> data, String? message, bool success
});




}
/// @nodoc
class _$BriefingDataCopyWithImpl<$Res>
    implements $BriefingDataCopyWith<$Res> {
  _$BriefingDataCopyWithImpl(this._self, this._then);

  final BriefingData _self;
  final $Res Function(BriefingData) _then;

/// Create a copy of BriefingData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? message = freezed,Object? success = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, CategoryData>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefingData].
extension BriefingDataPatterns on BriefingData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefingData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefingData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefingData value)  $default,){
final _that = this;
switch (_that) {
case _BriefingData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefingData value)?  $default,){
final _that = this;
switch (_that) {
case _BriefingData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, CategoryData> data,  String? message,  bool success)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefingData() when $default != null:
return $default(_that.data,_that.message,_that.success);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, CategoryData> data,  String? message,  bool success)  $default,) {final _that = this;
switch (_that) {
case _BriefingData():
return $default(_that.data,_that.message,_that.success);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, CategoryData> data,  String? message,  bool success)?  $default,) {final _that = this;
switch (_that) {
case _BriefingData() when $default != null:
return $default(_that.data,_that.message,_that.success);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefingData implements BriefingData {
  const _BriefingData({required final  Map<String, CategoryData> data, this.message, required this.success}): _data = data;
  factory _BriefingData.fromJson(Map<String, dynamic> json) => _$BriefingDataFromJson(json);

 final  Map<String, CategoryData> _data;
@override Map<String, CategoryData> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

@override final  String? message;
@override final  bool success;

/// Create a copy of BriefingData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefingDataCopyWith<_BriefingData> get copyWith => __$BriefingDataCopyWithImpl<_BriefingData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefingDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefingData&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.message, message) || other.message == message)&&(identical(other.success, success) || other.success == success));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),message,success);

@override
String toString() {
  return 'BriefingData(data: $data, message: $message, success: $success)';
}


}

/// @nodoc
abstract mixin class _$BriefingDataCopyWith<$Res> implements $BriefingDataCopyWith<$Res> {
  factory _$BriefingDataCopyWith(_BriefingData value, $Res Function(_BriefingData) _then) = __$BriefingDataCopyWithImpl;
@override @useResult
$Res call({
 Map<String, CategoryData> data, String? message, bool success
});




}
/// @nodoc
class __$BriefingDataCopyWithImpl<$Res>
    implements _$BriefingDataCopyWith<$Res> {
  __$BriefingDataCopyWithImpl(this._self, this._then);

  final _BriefingData _self;
  final $Res Function(_BriefingData) _then;

/// Create a copy of BriefingData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? message = freezed,Object? success = null,}) {
  return _then(_BriefingData(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, CategoryData>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CategoryData {

@JsonKey(name: 'sentiment_score') double get sentimentScore; String get summary; List<BriefingItem> get items;
/// Create a copy of CategoryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryDataCopyWith<CategoryData> get copyWith => _$CategoryDataCopyWithImpl<CategoryData>(this as CategoryData, _$identity);

  /// Serializes this CategoryData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryData&&(identical(other.sentimentScore, sentimentScore) || other.sentimentScore == sentimentScore)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sentimentScore,summary,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'CategoryData(sentimentScore: $sentimentScore, summary: $summary, items: $items)';
}


}

/// @nodoc
abstract mixin class $CategoryDataCopyWith<$Res>  {
  factory $CategoryDataCopyWith(CategoryData value, $Res Function(CategoryData) _then) = _$CategoryDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'sentiment_score') double sentimentScore, String summary, List<BriefingItem> items
});




}
/// @nodoc
class _$CategoryDataCopyWithImpl<$Res>
    implements $CategoryDataCopyWith<$Res> {
  _$CategoryDataCopyWithImpl(this._self, this._then);

  final CategoryData _self;
  final $Res Function(CategoryData) _then;

/// Create a copy of CategoryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sentimentScore = null,Object? summary = null,Object? items = null,}) {
  return _then(_self.copyWith(
sentimentScore: null == sentimentScore ? _self.sentimentScore : sentimentScore // ignore: cast_nullable_to_non_nullable
as double,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BriefingItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryData].
extension CategoryDataPatterns on CategoryData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryData value)  $default,){
final _that = this;
switch (_that) {
case _CategoryData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryData value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'sentiment_score')  double sentimentScore,  String summary,  List<BriefingItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryData() when $default != null:
return $default(_that.sentimentScore,_that.summary,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'sentiment_score')  double sentimentScore,  String summary,  List<BriefingItem> items)  $default,) {final _that = this;
switch (_that) {
case _CategoryData():
return $default(_that.sentimentScore,_that.summary,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'sentiment_score')  double sentimentScore,  String summary,  List<BriefingItem> items)?  $default,) {final _that = this;
switch (_that) {
case _CategoryData() when $default != null:
return $default(_that.sentimentScore,_that.summary,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryData implements CategoryData {
  const _CategoryData({@JsonKey(name: 'sentiment_score') this.sentimentScore = 0.0, this.summary = '', final  List<BriefingItem> items = const []}): _items = items;
  factory _CategoryData.fromJson(Map<String, dynamic> json) => _$CategoryDataFromJson(json);

@override@JsonKey(name: 'sentiment_score') final  double sentimentScore;
@override@JsonKey() final  String summary;
 final  List<BriefingItem> _items;
@override@JsonKey() List<BriefingItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of CategoryData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryDataCopyWith<_CategoryData> get copyWith => __$CategoryDataCopyWithImpl<_CategoryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryData&&(identical(other.sentimentScore, sentimentScore) || other.sentimentScore == sentimentScore)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sentimentScore,summary,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'CategoryData(sentimentScore: $sentimentScore, summary: $summary, items: $items)';
}


}

/// @nodoc
abstract mixin class _$CategoryDataCopyWith<$Res> implements $CategoryDataCopyWith<$Res> {
  factory _$CategoryDataCopyWith(_CategoryData value, $Res Function(_CategoryData) _then) = __$CategoryDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'sentiment_score') double sentimentScore, String summary, List<BriefingItem> items
});




}
/// @nodoc
class __$CategoryDataCopyWithImpl<$Res>
    implements _$CategoryDataCopyWith<$Res> {
  __$CategoryDataCopyWithImpl(this._self, this._then);

  final _CategoryData _self;
  final $Res Function(_CategoryData) _then;

/// Create a copy of CategoryData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sentimentScore = null,Object? summary = null,Object? items = null,}) {
  return _then(_CategoryData(
sentimentScore: null == sentimentScore ? _self.sentimentScore : sentimentScore // ignore: cast_nullable_to_non_nullable
as double,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BriefingItem>,
  ));
}


}


/// @nodoc
mixin _$BriefingItem {

 String? get title; String? get l; double? get sentiment; String? get img; String? get takeaway; String? get ticker; String? get name; String? get price; String? get change; String? get analysis; String? get explanation; String? get horizon;
/// Create a copy of BriefingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefingItemCopyWith<BriefingItem> get copyWith => _$BriefingItemCopyWithImpl<BriefingItem>(this as BriefingItem, _$identity);

  /// Serializes this BriefingItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefingItem&&(identical(other.title, title) || other.title == title)&&(identical(other.l, l) || other.l == l)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.img, img) || other.img == img)&&(identical(other.takeaway, takeaway) || other.takeaway == takeaway)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.horizon, horizon) || other.horizon == horizon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,l,sentiment,img,takeaway,ticker,name,price,change,analysis,explanation,horizon);

@override
String toString() {
  return 'BriefingItem(title: $title, l: $l, sentiment: $sentiment, img: $img, takeaway: $takeaway, ticker: $ticker, name: $name, price: $price, change: $change, analysis: $analysis, explanation: $explanation, horizon: $horizon)';
}


}

/// @nodoc
abstract mixin class $BriefingItemCopyWith<$Res>  {
  factory $BriefingItemCopyWith(BriefingItem value, $Res Function(BriefingItem) _then) = _$BriefingItemCopyWithImpl;
@useResult
$Res call({
 String? title, String? l, double? sentiment, String? img, String? takeaway, String? ticker, String? name, String? price, String? change, String? analysis, String? explanation, String? horizon
});




}
/// @nodoc
class _$BriefingItemCopyWithImpl<$Res>
    implements $BriefingItemCopyWith<$Res> {
  _$BriefingItemCopyWithImpl(this._self, this._then);

  final BriefingItem _self;
  final $Res Function(BriefingItem) _then;

/// Create a copy of BriefingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? l = freezed,Object? sentiment = freezed,Object? img = freezed,Object? takeaway = freezed,Object? ticker = freezed,Object? name = freezed,Object? price = freezed,Object? change = freezed,Object? analysis = freezed,Object? explanation = freezed,Object? horizon = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,l: freezed == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as String?,sentiment: freezed == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as double?,img: freezed == img ? _self.img : img // ignore: cast_nullable_to_non_nullable
as String?,takeaway: freezed == takeaway ? _self.takeaway : takeaway // ignore: cast_nullable_to_non_nullable
as String?,ticker: freezed == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,change: freezed == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String?,analysis: freezed == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as String?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,horizon: freezed == horizon ? _self.horizon : horizon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefingItem].
extension BriefingItemPatterns on BriefingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefingItem value)  $default,){
final _that = this;
switch (_that) {
case _BriefingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefingItem value)?  $default,){
final _that = this;
switch (_that) {
case _BriefingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? l,  double? sentiment,  String? img,  String? takeaway,  String? ticker,  String? name,  String? price,  String? change,  String? analysis,  String? explanation,  String? horizon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefingItem() when $default != null:
return $default(_that.title,_that.l,_that.sentiment,_that.img,_that.takeaway,_that.ticker,_that.name,_that.price,_that.change,_that.analysis,_that.explanation,_that.horizon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? l,  double? sentiment,  String? img,  String? takeaway,  String? ticker,  String? name,  String? price,  String? change,  String? analysis,  String? explanation,  String? horizon)  $default,) {final _that = this;
switch (_that) {
case _BriefingItem():
return $default(_that.title,_that.l,_that.sentiment,_that.img,_that.takeaway,_that.ticker,_that.name,_that.price,_that.change,_that.analysis,_that.explanation,_that.horizon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? l,  double? sentiment,  String? img,  String? takeaway,  String? ticker,  String? name,  String? price,  String? change,  String? analysis,  String? explanation,  String? horizon)?  $default,) {final _that = this;
switch (_that) {
case _BriefingItem() when $default != null:
return $default(_that.title,_that.l,_that.sentiment,_that.img,_that.takeaway,_that.ticker,_that.name,_that.price,_that.change,_that.analysis,_that.explanation,_that.horizon);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefingItem implements BriefingItem {
  const _BriefingItem({this.title, this.l, this.sentiment, this.img, this.takeaway, this.ticker, this.name, this.price, this.change, this.analysis, this.explanation, this.horizon});
  factory _BriefingItem.fromJson(Map<String, dynamic> json) => _$BriefingItemFromJson(json);

@override final  String? title;
@override final  String? l;
@override final  double? sentiment;
@override final  String? img;
@override final  String? takeaway;
@override final  String? ticker;
@override final  String? name;
@override final  String? price;
@override final  String? change;
@override final  String? analysis;
@override final  String? explanation;
@override final  String? horizon;

/// Create a copy of BriefingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefingItemCopyWith<_BriefingItem> get copyWith => __$BriefingItemCopyWithImpl<_BriefingItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefingItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefingItem&&(identical(other.title, title) || other.title == title)&&(identical(other.l, l) || other.l == l)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.img, img) || other.img == img)&&(identical(other.takeaway, takeaway) || other.takeaway == takeaway)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.horizon, horizon) || other.horizon == horizon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,l,sentiment,img,takeaway,ticker,name,price,change,analysis,explanation,horizon);

@override
String toString() {
  return 'BriefingItem(title: $title, l: $l, sentiment: $sentiment, img: $img, takeaway: $takeaway, ticker: $ticker, name: $name, price: $price, change: $change, analysis: $analysis, explanation: $explanation, horizon: $horizon)';
}


}

/// @nodoc
abstract mixin class _$BriefingItemCopyWith<$Res> implements $BriefingItemCopyWith<$Res> {
  factory _$BriefingItemCopyWith(_BriefingItem value, $Res Function(_BriefingItem) _then) = __$BriefingItemCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? l, double? sentiment, String? img, String? takeaway, String? ticker, String? name, String? price, String? change, String? analysis, String? explanation, String? horizon
});




}
/// @nodoc
class __$BriefingItemCopyWithImpl<$Res>
    implements _$BriefingItemCopyWith<$Res> {
  __$BriefingItemCopyWithImpl(this._self, this._then);

  final _BriefingItem _self;
  final $Res Function(_BriefingItem) _then;

/// Create a copy of BriefingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? l = freezed,Object? sentiment = freezed,Object? img = freezed,Object? takeaway = freezed,Object? ticker = freezed,Object? name = freezed,Object? price = freezed,Object? change = freezed,Object? analysis = freezed,Object? explanation = freezed,Object? horizon = freezed,}) {
  return _then(_BriefingItem(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,l: freezed == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as String?,sentiment: freezed == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as double?,img: freezed == img ? _self.img : img // ignore: cast_nullable_to_non_nullable
as String?,takeaway: freezed == takeaway ? _self.takeaway : takeaway // ignore: cast_nullable_to_non_nullable
as String?,ticker: freezed == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,change: freezed == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String?,analysis: freezed == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as String?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,horizon: freezed == horizon ? _self.horizon : horizon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
