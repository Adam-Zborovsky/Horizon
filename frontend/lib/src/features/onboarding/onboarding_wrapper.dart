import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'onboarding_provider.dart';
import 'tutorial_service.dart';
import 'tutorial_keys.dart';

enum OnboardingStep {
  dashboard(0),
  vault(1),
  nexus(2),
  profile(3);

  final int value;
  const OnboardingStep(this.value);
}

class OnboardingWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final OnboardingStep step;
  const OnboardingWrapper({super.key, required this.child, required this.step});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  TutorialCoachMark? _tutorial;
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    // Wait until the first frame so all widget keys are laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCurrentStep());
  }

  void _checkCurrentStep() async {
    if (!mounted) return;
    final currentStep = await ref.read(onboardingProvider.future);
    if (mounted && currentStep == widget.step.value) {
      _scheduleTutorial();
    }
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled) return;
    _tutorialScheduled = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _showTutorial();
    });
  }

  Future<void> _showTutorial() async {
    if (!mounted) return;

    // For the profile screen, the highlighted items (Refresh, Logout) are
    // near the bottom. Scroll them into view before the tutorial starts.
    if (widget.step == OnboardingStep.profile) {
      final ctx = TutorialKeys.profileRefresh.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.4,
        );
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    if (!mounted) return;

    final targets = _buildTargets();
    if (targets.isEmpty) return;

    _tutorial = TutorialService.createTutorial(
      context: context,
      targets: targets,
      onFinish: () {
        if (!mounted) return;
        // Advance the step counter. The next screen's tutorial fires
        // automatically when the user navigates there for the first time.
        if (widget.step == OnboardingStep.profile) {
          ref.read(onboardingProvider.notifier).completeAll();
        } else {
          ref.read(onboardingProvider.notifier).completeStep(widget.step.value);
        }
      },
      onSkip: () {
        if (!mounted) return true;
        ref.read(onboardingProvider.notifier).completeAll();
        return true;
      },
    );

    _tutorial?.show(context: context);
  }

  List<TargetFocus> _buildTargets() {
    switch (widget.step) {
      case OnboardingStep.dashboard:
        return TutorialService.getDashboardTargets();
      case OnboardingStep.vault:
        return TutorialService.getVaultTargets();
      case OnboardingStep.nexus:
        return TutorialService.getNexusTargets();
      case OnboardingStep.profile:
        return TutorialService.getProfileTargets();
    }
  }

  @override
  void dispose() {
    _tutorial = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to onboarding step changes on already-mounted screens.
    // This handles "Restart Tutorial" from the profile screen — the
    // DashboardScreen stays mounted in the ShellRoute and its initState
    // won't re-fire, so we catch the reset (e.g. 100 → 0) here instead.
    ref.listen<AsyncValue<int>>(onboardingProvider, (previous, next) {
      final prev = previous?.value;
      final curr = next.value;
      if (curr == widget.step.value && prev != widget.step.value) {
        _tutorialScheduled = false;
        _scheduleTutorial();
      }
    });

    return widget.child;
  }
}
