import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/auth_provider.dart';
import 'src/wear/wear_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: HorizonWearApp(),
    ),
  );
}

class HorizonWearApp extends ConsumerWidget {
  const HorizonWearApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Horizon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        // Smaller text for watch
        textTheme: AppTheme.darkTheme.textTheme.copyWith(
          displayLarge: AppTheme.darkTheme.textTheme.displayLarge?.copyWith(fontSize: 18),
          displayMedium: AppTheme.darkTheme.textTheme.displayMedium?.copyWith(fontSize: 16),
          titleLarge: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(fontSize: 14),
          bodyLarge: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(fontSize: 12),
          bodyMedium: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ),
      home: authState.when(
        data: (user) {
          if (user == null) return const _WearLoginPrompt();
          return const WearHomeScreen();
        },
        loading: () => const Scaffold(
          backgroundColor: AppTheme.obsidian,
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.goldAmber,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, __) => const _WearLoginPrompt(),
      ),
    );
  }
}

class _WearLoginPrompt extends StatelessWidget {
  const _WearLoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.watch_rounded,
                color: AppTheme.goldAmber,
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'HORIZON',
                style: TextStyle(
                  color: AppTheme.goldAmber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open Horizon on your\nphone to sign in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
