import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../briefing/briefing_config_repository.dart';
import '../briefing/briefing_config_model.dart';

part 'watchlist_provider.g.dart';

@riverpod
class Watchlist extends _$Watchlist {
  @override
  Set<String> build() {
    // We watch the config repository to keep our local state in sync
    final configAsync = ref.watch(briefingConfigRepositoryProvider);
    
    return configAsync.maybeWhen(
      data: (config) => config.tickers.toSet(),
      orElse: () => <String>{},
    );
  }

  Future<void> add(String ticker) async {
    final currentTickers = state;
    final newTickers = {...currentTickers, ticker.toUpperCase()};
    
    // We update the backend config, which will then trigger an update to this provider's state
    // because we are watching briefingConfigRepositoryProvider in build()
    await _updateBackend(newTickers.toList());
  }

  Future<void> remove(String ticker) async {
    final currentTickers = state;
    final newTickers = {...currentTickers}..remove(ticker.toUpperCase());
    
    await _updateBackend(newTickers.toList());
  }

  bool contains(String ticker) => state.contains(ticker.toUpperCase());

  Future<void> _updateBackend(List<String> tickers) async {
    final configRepo = ref.read(briefingConfigRepositoryProvider.notifier);
    final currentConfig = await ref.read(briefingConfigRepositoryProvider.future);
    
    await configRepo.updateConfig(currentConfig.copyWith(tickers: tickers));
  }
}
