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
      return 100;
    }
    return prefs.getInt(_keyStep) ?? 0;
  }

  Future<void> completeStep(int step) async {
    if (!ref.mounted) return;
    final currentStep = state.value ?? 0;
    if (step >= currentStep) {
      // Update in-memory state immediately so any screen that mounts right
      // after sees the correct step without waiting for prefs I/O.
      state = AsyncValue.data(step + 1);
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      await prefs.setInt(_keyStep, step + 1);
    }
  }

  Future<void> completeAll() async {
    if (!ref.mounted) return;
    state = const AsyncValue.data(100);
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    await prefs.setBool(_keyCompleted, true);
  }

  Future<void> resetOnboarding() async {
    if (!ref.mounted) return;
    // Update in-memory state first so ref.listen callbacks on already-mounted
    // screens fire immediately — before the async prefs I/O completes.
    state = const AsyncValue.data(0);
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    await prefs.remove(_keyCompleted);
    await prefs.remove(_keyStep);
  }
}
