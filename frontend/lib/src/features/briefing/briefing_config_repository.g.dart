// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'briefing_config_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BriefingConfigRepository)
final briefingConfigRepositoryProvider = BriefingConfigRepositoryProvider._();

final class BriefingConfigRepositoryProvider
    extends $AsyncNotifierProvider<BriefingConfigRepository, BriefingConfig> {
  BriefingConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'briefingConfigRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$briefingConfigRepositoryHash();

  @$internal
  @override
  BriefingConfigRepository create() => BriefingConfigRepository();
}

String _$briefingConfigRepositoryHash() =>
    r'e1915fe1f36e9030f914a960fbe9359532da079c';

abstract class _$BriefingConfigRepository
    extends $AsyncNotifier<BriefingConfig> {
  FutureOr<BriefingConfig> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BriefingConfig>, BriefingConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BriefingConfig>, BriefingConfig>,
              AsyncValue<BriefingConfig>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(recommendedTopics)
final recommendedTopicsProvider = RecommendedTopicsProvider._();

final class RecommendedTopicsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  RecommendedTopicsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendedTopicsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendedTopicsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return recommendedTopics(ref);
  }
}

String _$recommendedTopicsHash() => r'8bf1e2f9594addfd547b6245216dcd032eb1b53c';
