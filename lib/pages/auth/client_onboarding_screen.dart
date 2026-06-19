import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/pages/auth/onboarding_carousel.dart';
import 'package:valence/pages/auth/signup_screen.dart';

/// Pre-signup intro for clients — three slides that preview the real product,
/// then on into signup → the client intake. Built on [OnboardingCarousel].
class ClientOnboardingScreen extends StatelessWidget {
  const ClientOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      OnboardingSlide(
        preview: OnboardingPreview.clientNutrition,
        title: l10n.obClientLogTitle,
        body: l10n.obClientLogBody,
      ),
      OnboardingSlide(
        preview: OnboardingPreview.clientHabits,
        title: l10n.obClientHabitsTitle,
        body: l10n.obClientHabitsBody,
      ),
      OnboardingSlide(
        preview: OnboardingPreview.clientNote,
        title: l10n.obClientCoachTitle,
        body: l10n.obClientCoachBody,
      ),
    ];
    return OnboardingCarousel(
      slides: slides,
      finishLabel: l10n.obClientFinish,
      onFinish: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupScreen(userRole: UserRole.client)),
      ),
    );
  }
}
