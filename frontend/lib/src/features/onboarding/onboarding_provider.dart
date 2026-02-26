import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

@riverpod
class Onboarding extends _$Onboarding {
  static const _keyCompleted = 'onboarding_completed';
  static const _keyStep = 'onboarding_step';

  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyCompleted) ?? false) {
      return 100; // 100 means all done
    }
    return prefs.getInt(_keyStep) ?? 0;
  }

  Future<void> completeStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final currentStep = state.value ?? 0;
    if (step >= currentStep) {
      await prefs.setInt(_keyStep, step + 1);
      if (!ref.mounted) return;
      state = AsyncValue.data(step + 1);
    }
  }

  Future<void> completeAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    await prefs.setBool(_keyCompleted, true);
    if (!ref.mounted) return;
    state = const AsyncValue.data(100);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    await prefs.remove(_keyCompleted);
    await prefs.remove(_keyStep);
    if (!ref.mounted) return;
    state = const AsyncValue.data(0);
  }
}
