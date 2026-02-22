// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'briefing_config_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BriefingConfig {

 List<Topic> get topics; List<String> get tickers;
/// Create a copy of BriefingConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefingConfigCopyWith<BriefingConfig> get copyWith => _$BriefingConfigCopyWithImpl<BriefingConfig>(this as BriefingConfig, _$identity);

  /// Serializes this BriefingConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefingConfig&&const DeepCollectionEquality().equals(other.topics, topics)&&const DeepCollectionEquality().equals(other.tickers, tickers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(topics),const DeepCollectionEquality().hash(tickers));

@override
String toString() {
  return 'BriefingConfig(topics: $topics, tickers: $tickers)';
}


}

/// @nodoc
abstract mixin class $BriefingConfigCopyWith<$Res>  {
  factory $BriefingConfigCopyWith(BriefingConfig value, $Res Function(BriefingConfig) _then) = _$BriefingConfigCopyWithImpl;
@useResult
$Res call({
 List<Topic> topics, List<String> tickers
});




}
/// @nodoc
class _$BriefingConfigCopyWithImpl<$Res>
    implements $BriefingConfigCopyWith<$Res> {
  _$BriefingConfigCopyWithImpl(this._self, this._then);

  final BriefingConfig _self;
  final $Res Function(BriefingConfig) _then;

/// Create a copy of BriefingConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topics = null,Object? tickers = null,}) {
  return _then(_self.copyWith(
topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<Topic>,tickers: null == tickers ? _self.tickers : tickers // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefingConfig].
extension BriefingConfigPatterns on BriefingConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefingConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefingConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefingConfig value)  $default,){
final _that = this;
switch (_that) {
case _BriefingConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefingConfig value)?  $default,){
final _that = this;
switch (_that) {
case _BriefingConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Topic> topics,  List<String> tickers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefingConfig() when $default != null:
return $default(_that.topics,_that.tickers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Topic> topics,  List<String> tickers)  $default,) {final _that = this;
switch (_that) {
case _BriefingConfig():
return $default(_that.topics,_that.tickers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Topic> topics,  List<String> tickers)?  $default,) {final _that = this;
switch (_that) {
case _BriefingConfig() when $default != null:
return $default(_that.topics,_that.tickers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefingConfig implements BriefingConfig {
  const _BriefingConfig({final  List<Topic> topics = const [], final  List<String> tickers = const []}): _topics = topics,_tickers = tickers;
  factory _BriefingConfig.fromJson(Map<String, dynamic> json) => _$BriefingConfigFromJson(json);

 final  List<Topic> _topics;
@override@JsonKey() List<Topic> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}

 final  List<String> _tickers;
@override@JsonKey() List<String> get tickers {
  if (_tickers is EqualUnmodifiableListView) return _tickers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tickers);
}


/// Create a copy of BriefingConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefingConfigCopyWith<_BriefingConfig> get copyWith => __$BriefingConfigCopyWithImpl<_BriefingConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefingConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefingConfig&&const DeepCollectionEquality().equals(other._topics, _topics)&&const DeepCollectionEquality().equals(other._tickers, _tickers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_topics),const DeepCollectionEquality().hash(_tickers));

@override
String toString() {
  return 'BriefingConfig(topics: $topics, tickers: $tickers)';
}


}

/// @nodoc
abstract mixin class _$BriefingConfigCopyWith<$Res> implements $BriefingConfigCopyWith<$Res> {
  factory _$BriefingConfigCopyWith(_BriefingConfig value, $Res Function(_BriefingConfig) _then) = __$BriefingConfigCopyWithImpl;
@override @useResult
$Res call({
 List<Topic> topics, List<String> tickers
});




}
/// @nodoc
class __$BriefingConfigCopyWithImpl<$Res>
    implements _$BriefingConfigCopyWith<$Res> {
  __$BriefingConfigCopyWithImpl(this._self, this._then);

  final _BriefingConfig _self;
  final $Res Function(_BriefingConfig) _then;

/// Create a copy of BriefingConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topics = null,Object? tickers = null,}) {
  return _then(_BriefingConfig(
topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<Topic>,tickers: null == tickers ? _self._tickers : tickers // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Topic {

 String get name; bool get enabled;
/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopicCopyWith<Topic> get copyWith => _$TopicCopyWithImpl<Topic>(this as Topic, _$identity);

  /// Serializes this Topic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Topic&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,enabled);

@override
String toString() {
  return 'Topic(name: $name, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $TopicCopyWith<$Res>  {
  factory $TopicCopyWith(Topic value, $Res Function(Topic) _then) = _$TopicCopyWithImpl;
@useResult
$Res call({
 String name, bool enabled
});




}
/// @nodoc
class _$TopicCopyWithImpl<$Res>
    implements $TopicCopyWith<$Res> {
  _$TopicCopyWithImpl(this._self, this._then);

  final Topic _self;
  final $Res Function(Topic) _then;

/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Topic].
extension TopicPatterns on Topic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Topic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Topic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Topic value)  $default,){
final _that = this;
switch (_that) {
case _Topic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Topic value)?  $default,){
final _that = this;
switch (_that) {
case _Topic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Topic() when $default != null:
return $default(_that.name,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _Topic():
return $default(_that.name,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _Topic() when $default != null:
return $default(_that.name,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Topic implements Topic {
  const _Topic({required this.name, required this.enabled});
  factory _Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);

@override final  String name;
@override final  bool enabled;

/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopicCopyWith<_Topic> get copyWith => __$TopicCopyWithImpl<_Topic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Topic&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,enabled);

@override
String toString() {
  return 'Topic(name: $name, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$TopicCopyWith<$Res> implements $TopicCopyWith<$Res> {
  factory _$TopicCopyWith(_Topic value, $Res Function(_Topic) _then) = __$TopicCopyWithImpl;
@override @useResult
$Res call({
 String name, bool enabled
});




}
/// @nodoc
class __$TopicCopyWithImpl<$Res>
    implements _$TopicCopyWith<$Res> {
  __$TopicCopyWithImpl(this._self, this._then);

  final _Topic _self;
  final $Res Function(_Topic) _then;

/// Create a copy of Topic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? enabled = null,}) {
  return _then(_Topic(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
