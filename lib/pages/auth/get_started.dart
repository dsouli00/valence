import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/client_onboarding_screen.dart';
import 'package:valence/pages/auth/coach_onboarding_screen.dart';
import 'package:valence/pages/shared/language_picker.dart';
import 'login_screen.dart';
import '../../theme/app_theme.dart';

/// The landing screen for signed-out users: brand lockup, "I am a
/// coach/client" role selection, and the entry into each role's onboarding
/// journey. The language switcher lives here (top-right) because language
/// must be settable BEFORE any copy-heavy onboarding text is shown.
///
/// The role choice only picks which onboarding carousel to show — the actual
/// role is fixed at signup, which sits at the END of that journey
/// (personalize-first, signup wall last).
class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  String? _selectedRole;

  void _selectRole(String role) {
    HapticFeedback.selectionClick();
    setState(() => _selectedRole = role);
  }

  void _goToOnboarding() {
    if (_selectedRole == null) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _selectedRole == 'coach' ? const CoachOnboardingScreen() : const ClientOnboardingScreen(),
      ),
    );
  }

  void _goToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Subtle ambient wash — atmosphere, not a halo.
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryColor.withValues(alpha: 0.10),
                      AppColors.secondaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            AppSpacing.p24, AppSpacing.p8, AppSpacing.p24, AppSpacing.p16),
                        child: Column(
                          children: [
                            // Language switcher.
                            Align(
                              alignment: Alignment.centerRight,
                              child: _LanguageButton(theme: theme),
                            ),
                            const Spacer(flex: 2),
                            // Clean logo lockup — no chip, no ring.
                            SizedBox(
                              height: 88,
                              child: SvgPicture.asset(
                                'assets/logo/valence_logo.svg',
                                colorFilter: ColorFilter.mode(cs.secondary, BlendMode.srcIn),
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: AppSpacing.p20),
                            Text(
                              'VALENCE',
                              style: textTheme.headlineLarge?.copyWith(
                                color: cs.secondary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 5,
                              ),
                            ),
                            SizedBox(height: AppSpacing.p8),
                            Text(
                              l10n.appTagline,
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.landingSubtitle,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const Spacer(flex: 2),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.iAmA,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                  letterSpacing: 1.5,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSpacing.p12),
                            _RoleCard(
                              theme: theme,
                              selected: _selectedRole == 'coach',
                              icon: PhosphorIconsFill.barbell,
                              title: l10n.roleCoach,
                              description: l10n.roleCoachDesc,
                              onTap: () => _selectRole('coach'),
                            ),
                            SizedBox(height: AppSpacing.p12),
                            _RoleCard(
                              theme: theme,
                              selected: _selectedRole == 'client',
                              icon: PhosphorIconsFill.personSimpleRun,
                              title: l10n.roleClient,
                              description: l10n.roleClientDesc,
                              onTap: () => _selectRole('client'),
                            ),
                            const Spacer(flex: 3),
                            _PrimaryCta(
                              theme: theme,
                              label: l10n.getStarted,
                              enabled: _selectedRole != null,
                              onTap: _goToOnboarding,
                            ),
                            SizedBox(height: AppSpacing.p12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.alreadyHaveAccount,
                                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                TextButton(
                                  onPressed: _goToLogin,
                                  child: Text(
                                    l10n.signIn,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: cs.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
}

// ===========================================================================
// Language switcher pill
// ===========================================================================

class _LanguageButton extends StatelessWidget {
  final ThemeData theme;
  const _LanguageButton({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return _Pressable(
      onTap: () => showLanguagePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsBold.globe, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              currentLanguageLabel(context),
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Role card — stacked, descriptive, selectable
// ===========================================================================

class _RoleCard extends StatelessWidget {
  final ThemeData theme;
  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.theme,
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryColor.withValues(alpha: 0.12) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.secondaryColor.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.secondaryColor.withValues(alpha: 0.18)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 26, color: selected ? AppColors.secondaryColor : cs.onSurfaceVariant),
            ),
            SizedBox(width: AppSpacing.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.secondaryColor : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.secondaryColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.secondaryColor : cs.outlineVariant.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(PhosphorIconsBold.check, size: 13, color: AppColors.primaryColor)
          : null,
    );
  }
}

// ===========================================================================
// Primary CTA — always present, disabled until a role is chosen
// ===========================================================================

class _PrimaryCta extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryCta({
    required this.theme,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;
    return _Pressable(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(PhosphorIconsBold.arrowRight, size: 18, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Press-scale wrapper — the app's standard iOS-feel tap affordance
// (AnimatedScale to 0.97 on press). Several screens carry their own copy of
// this; if it ever changes, change them together.
// ===========================================================================

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
