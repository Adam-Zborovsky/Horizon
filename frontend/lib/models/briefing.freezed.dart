// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'briefing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BriefingCategory {

@JsonKey(name: 'sentiment_score') double get sentimentScore; String get summary; List<BriefingItem> get items;
/// Create a copy of BriefingCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefingCategoryCopyWith<BriefingCategory> get copyWith => _$BriefingCategoryCopyWithImpl<BriefingCategory>(this as BriefingCategory, _$identity);

  /// Serializes this BriefingCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefingCategory&&(identical(other.sentimentScore, sentimentScore) || other.sentimentScore == sentimentScore)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sentimentScore,summary,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'BriefingCategory(sentimentScore: $sentimentScore, summary: $summary, items: $items)';
}


}

/// @nodoc
abstract mixin class $BriefingCategoryCopyWith<$Res>  {
  factory $BriefingCategoryCopyWith(BriefingCategory value, $Res Function(BriefingCategory) _then) = _$BriefingCategoryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'sentiment_score') double sentimentScore, String summary, List<BriefingItem> items
});




}
/// @nodoc
class _$BriefingCategoryCopyWithImpl<$Res>
    implements $BriefingCategoryCopyWith<$Res> {
  _$BriefingCategoryCopyWithImpl(this._self, this._then);

  final BriefingCategory _self;
  final $Res Function(BriefingCategory) _then;

/// Create a copy of BriefingCategory
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


/// Adds pattern-matching-related methods to [BriefingCategory].
extension BriefingCategoryPatterns on BriefingCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefingCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefingCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefingCategory value)  $default,){
final _that = this;
switch (_that) {
case _BriefingCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefingCategory value)?  $default,){
final _that = this;
switch (_that) {
case _BriefingCategory() when $default != null:
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
case _BriefingCategory() when $default != null:
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
case _BriefingCategory():
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
case _BriefingCategory() when $default != null:
return $default(_that.sentimentScore,_that.summary,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefingCategory implements BriefingCategory {
  const _BriefingCategory({@JsonKey(name: 'sentiment_score') required this.sentimentScore, required this.summary, required final  List<BriefingItem> items}): _items = items;
  factory _BriefingCategory.fromJson(Map<String, dynamic> json) => _$BriefingCategoryFromJson(json);

@override@JsonKey(name: 'sentiment_score') final  double sentimentScore;
@override final  String summary;
 final  List<BriefingItem> _items;
@override List<BriefingItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BriefingCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefingCategoryCopyWith<_BriefingCategory> get copyWith => __$BriefingCategoryCopyWithImpl<_BriefingCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefingCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefingCategory&&(identical(other.sentimentScore, sentimentScore) || other.sentimentScore == sentimentScore)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sentimentScore,summary,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'BriefingCategory(sentimentScore: $sentimentScore, summary: $summary, items: $items)';
}


}

/// @nodoc
abstract mixin class _$BriefingCategoryCopyWith<$Res> implements $BriefingCategoryCopyWith<$Res> {
  factory _$BriefingCategoryCopyWith(_BriefingCategory value, $Res Function(_BriefingCategory) _then) = __$BriefingCategoryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'sentiment_score') double sentimentScore, String summary, List<BriefingItem> items
});




}
/// @nodoc
class __$BriefingCategoryCopyWithImpl<$Res>
    implements _$BriefingCategoryCopyWith<$Res> {
  __$BriefingCategoryCopyWithImpl(this._self, this._then);

  final _BriefingCategory _self;
  final $Res Function(_BriefingCategory) _then;

/// Create a copy of BriefingCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sentimentScore = null,Object? summary = null,Object? items = null,}) {
  return _then(_BriefingCategory(
sentimentScore: null == sentimentScore ? _self.sentimentScore : sentimentScore // ignore: cast_nullable_to_non_nullable
as double,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BriefingItem>,
  ));
}


}


/// @nodoc
mixin _$BriefingItem {

 String? get ticker; String? get name; double? get price; double? get change; double? get sentiment; String? get analysis; String? get title; String? get l; String? get img; String? get takeaway; String? get source; String? get timestamp;
/// Create a copy of BriefingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefingItemCopyWith<BriefingItem> get copyWith => _$BriefingItemCopyWithImpl<BriefingItem>(this as BriefingItem, _$identity);

  /// Serializes this BriefingItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefingItem&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&(identical(other.title, title) || other.title == title)&&(identical(other.l, l) || other.l == l)&&(identical(other.img, img) || other.img == img)&&(identical(other.takeaway, takeaway) || other.takeaway == takeaway)&&(identical(other.source, source) || other.source == source)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticker,name,price,change,sentiment,analysis,title,l,img,takeaway,source,timestamp);

@override
String toString() {
  return 'BriefingItem(ticker: $ticker, name: $name, price: $price, change: $change, sentiment: $sentiment, analysis: $analysis, title: $title, l: $l, img: $img, takeaway: $takeaway, source: $source, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $BriefingItemCopyWith<$Res>  {
  factory $BriefingItemCopyWith(BriefingItem value, $Res Function(BriefingItem) _then) = _$BriefingItemCopyWithImpl;
@useResult
$Res call({
 String? ticker, String? name, double? price, double? change, double? sentiment, String? analysis, String? title, String? l, String? img, String? takeaway, String? source, String? timestamp
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
@pragma('vm:prefer-inline') @override $Res call({Object? ticker = freezed,Object? name = freezed,Object? price = freezed,Object? change = freezed,Object? sentiment = freezed,Object? analysis = freezed,Object? title = freezed,Object? l = freezed,Object? img = freezed,Object? takeaway = freezed,Object? source = freezed,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
ticker: freezed == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,change: freezed == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as double?,sentiment: freezed == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as double?,analysis: freezed == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,l: freezed == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as String?,img: freezed == img ? _self.img : img // ignore: cast_nullable_to_non_nullable
as String?,takeaway: freezed == takeaway ? _self.takeaway : takeaway // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? ticker,  String? name,  double? price,  double? change,  double? sentiment,  String? analysis,  String? title,  String? l,  String? img,  String? takeaway,  String? source,  String? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefingItem() when $default != null:
return $default(_that.ticker,_that.name,_that.price,_that.change,_that.sentiment,_that.analysis,_that.title,_that.l,_that.img,_that.takeaway,_that.source,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? ticker,  String? name,  double? price,  double? change,  double? sentiment,  String? analysis,  String? title,  String? l,  String? img,  String? takeaway,  String? source,  String? timestamp)  $default,) {final _that = this;
switch (_that) {
case _BriefingItem():
return $default(_that.ticker,_that.name,_that.price,_that.change,_that.sentiment,_that.analysis,_that.title,_that.l,_that.img,_that.takeaway,_that.source,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? ticker,  String? name,  double? price,  double? change,  double? sentiment,  String? analysis,  String? title,  String? l,  String? img,  String? takeaway,  String? source,  String? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _BriefingItem() when $default != null:
return $default(_that.ticker,_that.name,_that.price,_that.change,_that.sentiment,_that.analysis,_that.title,_that.l,_that.img,_that.takeaway,_that.source,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefingItem implements BriefingItem {
  const _BriefingItem({this.ticker, this.name, this.price, this.change, this.sentiment, this.analysis, this.title, this.l, this.img, this.takeaway, this.source, this.timestamp});
  factory _BriefingItem.fromJson(Map<String, dynamic> json) => _$BriefingItemFromJson(json);

@override final  String? ticker;
@override final  String? name;
@override final  double? price;
@override final  double? change;
@override final  double? sentiment;
@override final  String? analysis;
@override final  String? title;
@override final  String? l;
@override final  String? img;
@override final  String? takeaway;
@override final  String? source;
@override final  String? timestamp;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefingItem&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&(identical(other.title, title) || other.title == title)&&(identical(other.l, l) || other.l == l)&&(identical(other.img, img) || other.img == img)&&(identical(other.takeaway, takeaway) || other.takeaway == takeaway)&&(identical(other.source, source) || other.source == source)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticker,name,price,change,sentiment,analysis,title,l,img,takeaway,source,timestamp);

@override
String toString() {
  return 'BriefingItem(ticker: $ticker, name: $name, price: $price, change: $change, sentiment: $sentiment, analysis: $analysis, title: $title, l: $l, img: $img, takeaway: $takeaway, source: $source, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$BriefingItemCopyWith<$Res> implements $BriefingItemCopyWith<$Res> {
  factory _$BriefingItemCopyWith(_BriefingItem value, $Res Function(_BriefingItem) _then) = __$BriefingItemCopyWithImpl;
@override @useResult
$Res call({
 String? ticker, String? name, double? price, double? change, double? sentiment, String? analysis, String? title, String? l, String? img, String? takeaway, String? source, String? timestamp
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
@override @pragma('vm:prefer-inline') $Res call({Object? ticker = freezed,Object? name = freezed,Object? price = freezed,Object? change = freezed,Object? sentiment = freezed,Object? analysis = freezed,Object? title = freezed,Object? l = freezed,Object? img = freezed,Object? takeaway = freezed,Object? source = freezed,Object? timestamp = freezed,}) {
  return _then(_BriefingItem(
ticker: freezed == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,change: freezed == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as double?,sentiment: freezed == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as double?,analysis: freezed == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,l: freezed == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as String?,img: freezed == img ? _self.img : img // ignore: cast_nullable_to_non_nullable
as String?,takeaway: freezed == takeaway ? _self.takeaway : takeaway // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
