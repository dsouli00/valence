import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/client_intake_screen.dart';
import 'package:valence/pages/auth/onboarding_carousel.dart';

/// Pre-signup intro for clients — three slides that preview the real product,
/// then into the personalize-first journey (build your plan → create account).
/// Built on [OnboardingCarousel].
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
        MaterialPageRoute(builder: (_) => const ClientIntakeScreen(newUser: true)),
      ),
    );
  }
}
