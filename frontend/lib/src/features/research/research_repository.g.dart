// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'research_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(researchRepository)
final researchRepositoryProvider = ResearchRepositoryProvider._();

final class ResearchRepositoryProvider
    extends
        $FunctionalProvider<
          ResearchRepository,
          ResearchRepository,
          ResearchRepository
        >
    with $Provider<ResearchRepository> {
  ResearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'researchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$researchRepositoryHash();

  @$internal
  @override
  $ProviderElement<ResearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResearchRepository create(Ref ref) {
    return researchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResearchRepository>(value),
    );
  }
}

String _$researchRepositoryHash() =>
    r'441119e70ff8d015478936ddfaaaf35664bfd258';
