import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/client_onboarding_screen.dart';
import 'package:valence/pages/auth/coach_onboarding_screen.dart';
import 'package:valence/pages/shared/language_picker.dart';
import 'package:valence/ui/ui.dart';

import 'login_screen.dart';

/// The landing screen for signed-out users (design.md §5.1, adapted): a warm
/// welcome that speaks to coaches AND clients, the coach/client role choice,
/// then into that role's onboarding journey. The language pill stays top-right
/// (language must be settable before any copy-heavy screen).
///
/// Theme-responsive: everything resolves from `context.tokens`, so the screen
/// follows the app's light/dark mode. The role choice only picks which
/// onboarding carousel to show — the real role is fixed at signup, at the END
/// of that journey (personalize-first).
class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;

  // One-time entrance (fade + 8px rise, §1.7-①).
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: VDuration.entrance,
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    HapticFeedback.selectionClick();
    setState(() => _selectedRole = role);
  }

  void _continue() {
    if (_selectedRole == null) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _selectedRole == 'coach'
            ? const CoachOnboardingScreen()
            : const ClientOnboardingScreen(),
      ),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: VSkyGlow(alpha: 0.10)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                        child: _entranceWrap(
                          reduceMotion,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: _LanguageButton(),
                              ),
                              const Spacer(flex: 2),
                              // Brand + welcome.
                              SizedBox(
                                height: 60,
                                child: SvgPicture.asset(
                                  'assets/logo/valence_logo.svg',
                                  colorFilter:
                                      ColorFilter.mode(t.gold, BlendMode.srcIn),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),
                              VTextScaleCap(
                                child: Text(
                                  l10n.welcomeTitle,
                                  textAlign: TextAlign.center,
                                  style:
                                      VType.serifDisplay.copyWith(color: t.ink),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.landingSubtitle,
                                textAlign: TextAlign.center,
                                style: VType.body.copyWith(color: t.inkSecondary),
                              ),
                              const Spacer(flex: 2),
                              // Role choice.
                              Text(
                                l10n.coverRolePrompt,
                                style: VType.title2.copyWith(color: t.ink),
                              ),
                              const SizedBox(height: 14),
                              VOptionCard(
                                // A person who instructs, not a barbell. The
                                // pair mismatched levels — an OBJECT for the
                                // coach against a PERSON for the athlete — and
                                // a barbell says "gym", not "the one guiding
                                // you". Both are people now, told apart by what
                                // they are doing.
                                icon: PhosphorIconsFill.chalkboardTeacher,
                                label: l10n.roleCoach,
                                subtitle: l10n.roleCoachDesc,
                                tint: t.gold,
                                selected: _selectedRole == 'coach',
                                onTap: () => _selectRole('coach'),
                              ),
                              const SizedBox(height: 12),
                              VOptionCard(
                                icon: PhosphorIconsFill.personSimpleRun,
                                label: l10n.roleAthlete,
                                subtitle: l10n.roleClientDesc,
                                tint: t.teal,
                                selected: _selectedRole == 'client',
                                onTap: () => _selectRole('client'),
                              ),
                              const Spacer(flex: 3),
                              // Continue + login.
                              VPillButton.primary(
                                label: l10n.getStarted,
                                onPressed:
                                    _selectedRole == null ? null : _continue,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.alreadyHaveAccount,
                                    style: VType.subhead
                                        .copyWith(color: t.inkSecondary),
                                  ),
                                  VTextAction(
                                    label: l10n.signIn,
                                    onTap: _goToLogin,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _entranceWrap(bool reduceMotion, Widget child) {
    if (reduceMotion) return child;
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, c) {
        final v = VMotion.curve.transform(_entrance.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: c),
        );
      },
      child: child,
    );
  }
}

// ===========================================================================
// Language pill (top-right). Theme-responsive via tokens.
// ===========================================================================

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VPressable(
      onTap: () => showLanguagePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.surfaceSubtle,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(color: t.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsBold.globe, size: 16, color: t.inkSecondary),
            const SizedBox(width: 6),
            Text(
              currentLanguageLabel(context),
              style: VType.subhead.copyWith(
                color: t.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
