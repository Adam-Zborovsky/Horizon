// ... (existing imports)

class AlphaScannerScreen extends ConsumerWidget {
  const AlphaScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return Scaffold(
      body: Container(
        // ... (existing decoration)
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const _ScannerHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ScannerPulse(),
                    const SizedBox(height: 30),
                    
                    // New Strategic Opportunities Section
                    const _ScannerSectionHeader(title: 'Strategic Opportunities'),
                    const SizedBox(height: 8),
                    const Text(
                      'High-conviction ideas scouted from across the market.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    briefingAsync.when(
                      data: (briefing) {
                        final opportunities = briefing.data['strategic_opportunities']?.items ?? [];
                        if (opportunities.isEmpty) {
                          return const _EmptyScannerState(message: 'No new opportunities scouted.');
                        }
                        return Column(
                          children: opportunities.map((item) => _StrategicOpportunityCard(item: item)).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppTheme.goldAmber),
                      error: (e, s) => const _EmptyScannerState(message: 'Opportunity feed offline.'),
                    ),

                    const SizedBox(height: 30),
                    const _ScannerSectionHeader(title: 'High-Signal Divergences'),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Sentiment is high, but price action remains flat/down.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    stocksAsync.when(
                      data: (stocks) {
                        final divergences = stocks.where((s) => s.sentiment > 0.5 && s.changePercent <= 0.5).toList();
                        if (divergences.isEmpty) {
                          return const _EmptyScannerState(message: 'No active divergences detected.');
                        }
                        return Column(
                          children: divergences.map((s) => _DivergenceCard(stock: s)).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppTheme.goldAmber),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 30),
                    const _ScannerSectionHeader(title: 'Strategic Catalysts'),
                    const SizedBox(height: 8),
                    const Text(
                      'Deep-intelligence anchors extracted from daily briefing.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    briefingAsync.when(
                      data: (briefing) {
                        final List<BriefingItem> catalysts = [];
                        briefing.data.forEach((key, cat) {
                          if (key != 'strategic_opportunities') { // Exclude new opportunities
                            catalysts.addAll(cat.items.where((i) => i.takeaway != null));
                          }
                        });
                        
                        if (catalysts.isEmpty) {
                          return const _EmptyScannerState(message: 'No catalysts identified.');
                        }
                            
                        return Column(
                          children: catalysts.take(5).map((i) => _CatalystCard(item: i)).toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... (existing _ScannerHeader, _ScannerPulse, _ScannerSectionHeader)

// New Card for Strategic Opportunities
class _StrategicOpportunityCard extends StatelessWidget {
  final BriefingItem item;

  const _StrategicOpportunityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/stock/${item.ticker}'),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ticker ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Text(
                        item.name?.toUpperCase() ?? 'UNKNOWN ASSET',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(item.sentiment ?? 0).toStringAsFixed(1)} SNT',
                        style: const TextStyle(
                          color: AppTheme.goldAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.horizon?.toUpperCase() ?? 'MID-TERM',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'SCOUT ANALYSIS',
                style: TextStyle(
                  color: AppTheme.goldAmber,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.explanation ?? 'No analysis provided.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (existing _DivergenceCard, _CatalystCard, _EmptyScannerState, etc.)
// Note: I will remove the _MacroImpactMap as it's being replaced functionally
// by the new Strategic Opportunities section.
