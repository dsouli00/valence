import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/coach_intake_screen.dart';
import 'package:valence/pages/auth/role_intro_screen.dart';
import 'package:valence/ui/ui.dart';

/// Pre-signup intro for coaches — one scannable "how Valence works for you"
/// screen, then straight into the personalize-first flow (set up your studio →
/// create account). Built on [RoleIntroScreen].
class CoachOnboardingScreen extends StatelessWidget {
  const CoachOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return RoleIntroScreen(
      title: l10n.coachIntroTitle,
      subtitle: l10n.introSubtitle,
      features: [
        (PhosphorIconsFill.users, t.gold, l10n.obCoachRosterTitle, l10n.obCoachRosterBody),
        (PhosphorIconsFill.barbell, t.clay, l10n.obCoachProgramTitle, l10n.obCoachProgramBody),
        (PhosphorIconsFill.chartLineUp, t.teal, l10n.obCoachGrowTitle, l10n.obCoachGrowBody),
      ],
      ctaLabel: l10n.coachIntroCta,
      onContinue: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CoachIntakeScreen(newUser: true)),
      ),
    );
  }
}
