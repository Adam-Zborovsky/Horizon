// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'briefing_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BriefingRepository)
final briefingRepositoryProvider = BriefingRepositoryProvider._();

final class BriefingRepositoryProvider
    extends $AsyncNotifierProvider<BriefingRepository, BriefingData> {
  BriefingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'briefingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$briefingRepositoryHash();

  @$internal
  @override
  BriefingRepository create() => BriefingRepository();
}

String _$briefingRepositoryHash() =>
    r'eabb922bc2740154d73edfa0341ee494b5ebb5e2';

abstract class _$BriefingRepository extends $AsyncNotifier<BriefingData> {
  FutureOr<BriefingData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BriefingData>, BriefingData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BriefingData>, BriefingData>,
              AsyncValue<BriefingData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
