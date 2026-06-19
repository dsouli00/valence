import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/pages/auth/onboarding_carousel.dart';
import 'package:valence/pages/auth/signup_screen.dart';

/// Pre-signup intro for coaches — three slides that preview the real product,
/// then on into signup → the coach intake. Built on [OnboardingCarousel].
class CoachOnboardingScreen extends StatelessWidget {
  const CoachOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      OnboardingSlide(
        preview: OnboardingPreview.coachRoster,
        title: l10n.obCoachRosterTitle,
        body: l10n.obCoachRosterBody,
      ),
      OnboardingSlide(
        preview: OnboardingPreview.coachWorkout,
        title: l10n.obCoachProgramTitle,
        body: l10n.obCoachProgramBody,
      ),
      OnboardingSlide(
        preview: OnboardingPreview.coachPulse,
        title: l10n.obCoachGrowTitle,
        body: l10n.obCoachGrowBody,
      ),
    ];
    return OnboardingCarousel(
      slides: slides,
      finishLabel: l10n.obCoachFinish,
      onFinish: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupScreen(userRole: UserRole.coach)),
      ),
    );
  }
}
