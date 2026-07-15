import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/client_intake_screen.dart';
import 'package:valence/pages/auth/role_intro_screen.dart';
import 'package:valence/ui/ui.dart';

/// Pre-signup intro for clients — one scannable "how Valence works for you"
/// screen, then straight into the personalize-first journey (build your plan →
/// create account). Built on [RoleIntroScreen].
class ClientOnboardingScreen extends StatelessWidget {
  const ClientOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return RoleIntroScreen(
      title: l10n.clientIntroTitle,
      subtitle: l10n.introSubtitle,
      features: [
        (PhosphorIconsFill.fire, t.gold, l10n.obClientLogTitle, l10n.obClientLogBody),
        (PhosphorIconsFill.heartbeat, t.sage, l10n.obClientHabitsTitle, l10n.obClientHabitsBody),
        (PhosphorIconsFill.chatCircle, t.steel, l10n.obClientCoachTitle, l10n.obClientCoachBody),
      ],
      ctaLabel: l10n.clientIntroCta,
      onContinue: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClientIntakeScreen(newUser: true)),
      ),
    );
  }
}
