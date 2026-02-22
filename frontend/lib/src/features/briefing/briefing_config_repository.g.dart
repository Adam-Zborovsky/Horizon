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
    r'39dc07581b11b6000688fc3bf585497cdb12b3aa';

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
