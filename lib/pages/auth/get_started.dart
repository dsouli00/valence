import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/coach_onboarding_screen.dart';
import 'client_onboarding_screen.dart';
import 'login_screen.dart';
import '../../theme/app_theme.dart';

class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  String? _selectedRole;

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _goToOnboarding() {
    if (_selectedRole == null) return;
    _selectedRole == "coach"
        ? Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CoachOnboardingScreen()),
    )
        : Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientOnboardingScreen()),
    );

  }
  void _goToLogin(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Ambient gold glow.
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryColor.withValues(alpha: 0.13),
                      AppColors.secondaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.p24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Gradient-ring logo.
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryColor,
                          AppColors.secondaryColor.withValues(alpha: 0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryColor.withValues(alpha: 0.3),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: colorScheme.surface,
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: SvgPicture.asset(
                          "assets/logo/valence_logo.svg",
                          colorFilter: ColorFilter.mode(colorScheme.secondary, BlendMode.srcIn),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.p16),
                  Text(
                    'VALENCE',
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: AppSpacing.p8),
                  Text(
                    l10n.appTagline,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.landingSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
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
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.p12),
                  Row(
                    children: [
                      Expanded(
                        child: _roleCard(theme, 'coach', l10n.roleCoach, PhosphorIconsFill.barbell),
                      ),
                      SizedBox(width: AppSpacing.p12),
                      Expanded(
                        child: _roleCard(theme, 'client', l10n.roleClient, PhosphorIconsFill.personSimpleRun),
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
                            .animate(animation),
                        child: child,
                      ),
                    ),
                    child: _selectedRole != null
                        ? Column(
                            key: const ValueKey('cta_visible'),
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _goToOnboarding();
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 54,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondaryColor.withValues(alpha: 0.3),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.getStarted,
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(PhosphorIconsBold.arrowRight,
                                          size: 18, color: AppColors.primaryColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(key: ValueKey('cta_hidden'), height: 54),
                  ),
                  SizedBox(height: AppSpacing.p12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: _goToLogin,
                        child: Text(
                          l10n.signIn,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.p16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard(ThemeData theme, String role, String label, IconData icon) {
    final cs = theme.colorScheme;
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _selectRole(role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 22),
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
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryColor.withValues(alpha: selected ? 1 : 0.5),
                    AppColors.secondaryColor.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: cs.surface,
                child: Icon(icon, size: 26, color: AppColors.secondaryColor),
              ),
            ),
            SizedBox(height: AppSpacing.p12),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.secondaryColor : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

