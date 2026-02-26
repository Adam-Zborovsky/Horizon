import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isTutorialShowing = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  void _checkOnboarding() async {
    final currentStep = await ref.read(onboardingProvider.future);
    if (currentStep == widget.step.value) {
      Future.delayed(const Duration(milliseconds: 1500), () {
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

    setState(() {
      _isTutorialShowing = true;
    });

    _tutorial = TutorialService.createTutorial(
      context: context,
      targets: targets,
      onFinish: () {
        if (!mounted) return;
        setState(() => _isTutorialShowing = false);
        ref.read(onboardingProvider.notifier).completeStep(widget.step.value);
        if (widget.step == OnboardingStep.profile) {
          ref.read(onboardingProvider.notifier).completeAll();
        }
      },
      onSkip: () {
        if (!mounted) return true;
        setState(() => _isTutorialShowing = false);
        ref.read(onboardingProvider.notifier).completeAll();
        return true;
      },
    );

    _tutorial?.show(context: context);
  }

  @override
  void dispose() {
    _tutorial = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTutorialShowing) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
