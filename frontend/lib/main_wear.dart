import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/auth_provider.dart';
import 'src/wear/wear_home_screen.dart';
import 'src/wear/wear_login_screen.dart';

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
          if (user == null) return const WearLoginScreen();
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
        error: (_, __) => const WearLoginScreen(),
      ),
    );
  }
}
