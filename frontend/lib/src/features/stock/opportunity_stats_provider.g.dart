// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opportunity_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(opportunityStats)
final opportunityStatsProvider = OpportunityStatsFamily._();

final class OpportunityStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<OpportunityStats>,
          OpportunityStats,
          FutureOr<OpportunityStats>
        >
    with $FutureModifier<OpportunityStats>, $FutureProvider<OpportunityStats> {
  OpportunityStatsProvider._({
    required OpportunityStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'opportunityStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$opportunityStatsHash();

  @override
  String toString() {
    return r'opportunityStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OpportunityStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OpportunityStats> create(Ref ref) {
    final argument = this.argument as String;
    return opportunityStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OpportunityStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$opportunityStatsHash() => r'93200db7e1e909ce3b8e2571c2ce6844391f1379';

final class OpportunityStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OpportunityStats>, String> {
  OpportunityStatsFamily._()
    : super(
        retry: null,
        name: r'opportunityStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OpportunityStatsProvider call(String ticker) =>
      OpportunityStatsProvider._(argument: ticker, from: this);

  @override
  String toString() => r'opportunityStatsProvider';
}
