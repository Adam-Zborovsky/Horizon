import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/dashboard/dashboard_screen.dart';
import 'src/features/nexus/market_nexus_screen.dart';
import 'src/features/vault/intelligence_vault_screen.dart';
import 'src/features/scanner/alpha_scanner_screen.dart';
import 'src/features/stock/stock_detail_screen.dart';
import 'src/features/nexus/management/manage_watchlist_screen.dart';
import 'src/features/vault/management/manage_topics_screen.dart';
import 'src/features/profile/profile_screen.dart';
import 'src/features/notifications/notifications_screen.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/auth/auth_provider.dart';
import 'src/core/widgets/glass_card.dart';
import 'src/features/onboarding/tutorial_keys.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AlphaHorizonApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/nexus',
            builder: (context, state) => const MarketNexusScreen(),
          ),
          GoRoute(
            path: '/vault',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return IntelligenceVaultScreen(initialCategory: category);
            },
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) => AlphaScannerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/manage-watchlist',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageWatchlistScreen(),
      ),
      GoRoute(
        path: '/manage-topics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageTopicsScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/stock/:ticker',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final ticker = state.pathParameters['ticker']!;
          return StockDetailScreen(ticker: ticker);
        },
      ),
    ],
  );
});

class AlphaHorizonApp extends ConsumerWidget {
  const AlphaHorizonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    
    return MaterialApp.router(
      title: 'Alpha Horizon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          borderRadius: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                key: TutorialKeys.navDash,
                icon: Icons.dashboard_rounded, 
                label: 'Dash', 
                location: '/',
              ),
              _NavItem(
                key: TutorialKeys.navVault,
                icon: Icons.analytics_rounded, 
                label: 'Vault', 
                location: '/vault',
              ),
              _NavItem(
                key: TutorialKeys.navNexus,
                icon: Icons.show_chart_rounded, 
                label: 'Nexus', 
                location: '/nexus',
              ),
              _NavItem(
                key: TutorialKeys.navScan,
                icon: Icons.radar_rounded, 
                label: 'Scan', 
                location: '/scanner',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String location;

  const _NavItem({
    super.key,
    required this.icon, 
    required this.label, 
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String matchedLocation = state.matchedLocation;
    // Special handling for home path
    final bool isActive = matchedLocation == location || (location == '/' && matchedLocation == '');

    return GestureDetector(
      onTap: () => context.go(location),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.goldAmber : Colors.white24,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.goldAmber : Colors.white24,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
