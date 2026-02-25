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
    r'af27bb562738d879fb205ae6490643ab9873fef7';

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

String _$recommendedTopicsHash() => r'394ee2a1109dc219dd20a7cbd1d690371c5c8566';
