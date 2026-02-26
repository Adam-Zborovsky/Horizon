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
  scanner(3),
  profile(4);

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
  // Track the last step value we acted on so we don't double-trigger.
  int? _lastKnownStep;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCurrentStep());
  }

  /// Reads the current step and starts the tutorial if it matches this screen.
  /// Called on first mount and also when the provider value changes.
  void _checkCurrentStep() async {
    if (!mounted) return;
    final currentStep = await ref.read(onboardingProvider.future);
    if (!mounted) return;
    if (currentStep == widget.step.value && _lastKnownStep != widget.step.value) {
      _lastKnownStep = widget.step.value;
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

    // Profile items are near the bottom — scroll them into view first.
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
      case OnboardingStep.scanner:
        return TutorialService.getScannerTargets();
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
    // Watch the provider so this widget rebuilds whenever the step changes.
    // This is the most reliable way to catch resets on already-mounted screens
    // (e.g. DashboardScreen sitting behind the Profile route in the nav stack).
    final stepAsync = ref.watch(onboardingProvider);

    stepAsync.whenData((step) {
      if (step == widget.step.value && _lastKnownStep != widget.step.value) {
        _lastKnownStep = widget.step.value;
        // Schedule outside the build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scheduleTutorial();
        });
      } else if (step != widget.step.value) {
        // Step moved away from our value — allow re-trigger on next reset.
        _lastKnownStep = step;
      }
    });

    return widget.child;
  }
}
