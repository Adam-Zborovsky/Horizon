// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_articles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SavedArticles)
final savedArticlesProvider = SavedArticlesProvider._();

final class SavedArticlesProvider
    extends $NotifierProvider<SavedArticles, Set<String>> {
  SavedArticlesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedArticlesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedArticlesHash();

  @$internal
  @override
  SavedArticles create() => SavedArticles();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$savedArticlesHash() => r'915c710a0a0a7914c764ad3d620bf76f0c63d42a';

abstract class _$SavedArticles extends $Notifier<Set<String>> {
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
