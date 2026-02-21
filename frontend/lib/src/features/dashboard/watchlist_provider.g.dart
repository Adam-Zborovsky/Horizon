// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Watchlist)
final watchlistProvider = WatchlistProvider._();

final class WatchlistProvider
    extends $NotifierProvider<Watchlist, Set<String>> {
  WatchlistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchlistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchlistHash();

  @$internal
  @override
  Watchlist create() => Watchlist();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$watchlistHash() => r'dbb253de45261e2721d3434afa12b06d68f33c65';

abstract class _$Watchlist extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FollowedTopics)
final followedTopicsProvider = FollowedTopicsProvider._();

final class FollowedTopicsProvider
    extends $NotifierProvider<FollowedTopics, Set<String>> {
  FollowedTopicsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followedTopicsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followedTopicsHash();

  @$internal
  @override
  FollowedTopics create() => FollowedTopics();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$followedTopicsHash() => r'7e0aa79f861c42ac8ead02f75b30d70a82ea9525';

abstract class _$FollowedTopics extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
