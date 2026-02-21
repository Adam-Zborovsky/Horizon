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
    extends
        $AsyncNotifierProvider<
          BriefingRepository,
          Map<String, BriefingCategory>
        > {
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
    r'ba1390505289ad1312fa9ceed500c34cebd2e9da';

abstract class _$BriefingRepository
    extends $AsyncNotifier<Map<String, BriefingCategory>> {
  FutureOr<Map<String, BriefingCategory>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, BriefingCategory>>,
              Map<String, BriefingCategory>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, BriefingCategory>>,
                Map<String, BriefingCategory>
              >,
              AsyncValue<Map<String, BriefingCategory>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
