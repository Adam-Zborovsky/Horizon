import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'onboarding_provider.dart';
import 'tutorial_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  void _checkOnboarding() async {
    final currentStep = await ref.read(onboardingProvider.future);
    if (currentStep == widget.step.value) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showTutorial();
        }
      });
    }
  }

  void _showTutorial() {
    List<TargetFocus> targets = [];

    switch (widget.step) {
      case OnboardingStep.dashboard:
        targets = [
          ...TutorialService.getNavigationTargets(),
          ...TutorialService.getDashboardTargets(),
        ];
        break;
      case OnboardingStep.vault:
        targets = TutorialService.getVaultTargets();
        break;
      case OnboardingStep.nexus:
        targets = TutorialService.getNexusTargets();
        break;
      case OnboardingStep.profile:
        targets = TutorialService.getProfileTargets();
        break;
    }

    if (targets.isEmpty) return;

    _tutorial = TutorialService.createTutorial(
      context: context,
      targets: targets,
      onFinish: () {
        if (!mounted) return;
        ref.read(onboardingProvider.notifier).completeStep(widget.step.value);
        _navigateToNextStep();
      },
      onSkip: () {
        if (!mounted) return true;
        ref.read(onboardingProvider.notifier).completeAll();
        return true;
      },
    );

    _tutorial?.show(context: context);
  }

  void _navigateToNextStep() {
    if (!mounted) return;
    switch (widget.step) {
      case OnboardingStep.dashboard:
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.go('/vault');
        });
        break;
      case OnboardingStep.vault:
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.go('/nexus');
        });
        break;
      case OnboardingStep.nexus:
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.push('/profile');
        });
        break;
      case OnboardingStep.profile:
        ref.read(onboardingProvider.notifier).completeAll();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.go('/');
        });
        break;
    }
  }

  @override
  void dispose() {
    _tutorial = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
