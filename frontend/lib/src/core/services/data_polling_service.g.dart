// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_polling_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Periodically polls the backend for new briefing data.
/// When a newer timestamp is detected, fires a notification and
/// invalidates the briefing provider so the UI auto-refreshes.

@ProviderFor(DataPollingService)
final dataPollingServiceProvider = DataPollingServiceProvider._();

/// Periodically polls the backend for new briefing data.
/// When a newer timestamp is detected, fires a notification and
/// invalidates the briefing provider so the UI auto-refreshes.
final class DataPollingServiceProvider
    extends $NotifierProvider<DataPollingService, void> {
  /// Periodically polls the backend for new briefing data.
  /// When a newer timestamp is detected, fires a notification and
  /// invalidates the briefing provider so the UI auto-refreshes.
  DataPollingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataPollingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataPollingServiceHash();

  @$internal
  @override
  DataPollingService create() => DataPollingService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$dataPollingServiceHash() =>
    r'7f497177b63dc31dfd9de29ba0ef85af0ecc2393';

/// Periodically polls the backend for new briefing data.
/// When a newer timestamp is detected, fires a notification and
/// invalidates the briefing provider so the UI auto-refreshes.

abstract class _$DataPollingService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
