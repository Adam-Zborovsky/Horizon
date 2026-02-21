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
    r'48eec27c362534c53487663f3cc9b46ca74d014d';

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
