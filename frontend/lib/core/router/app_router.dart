import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horizon/core/theme/app_theme.dart';
import 'package:horizon/ui/dashboard/dashboard_view.dart';
import 'package:horizon/ui/intelligence/intelligence_detail_view.dart';
import 'package:horizon/ui/intelligence/intelligence_feed_view.dart';
import 'package:horizon/ui/analysis/analysis_view.dart';
import 'package:horizon/ui/stock_detail/stock_detail_view.dart';
import 'package:horizon/ui/watchlist/watchlist_view.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  
  return GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardView(),
                routes: [
                  GoRoute(
                    path: 'watchlist',
                    builder: (context, state) => const WatchlistView(),
                  ),
                  GoRoute(
                    path: 'intelligence/:category',
                    builder: (context, state) {
                      final category = state.pathParameters['category']!;
                      return IntelligenceDetailView(category: category);
                    },
                  ),
                  GoRoute(
                    path: 'stock/:ticker',
                    builder: (context, state) {
                      final ticker = state.pathParameters['ticker']!;
                      return StockDetailView(ticker: ticker);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/intelligence-feed',
                builder: (context, state) => const IntelligenceFeedView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analysis',
                builder: (context, state) => const AnalysisView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        backgroundColor: AppTheme.darkBg,
        selectedItemColor: AppTheme.neutralBlue,
        unselectedItemColor: AppTheme.textDim,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.public_rounded), label: 'Intelligence'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analysis'),
        ],
      ),
    );
  }
}
