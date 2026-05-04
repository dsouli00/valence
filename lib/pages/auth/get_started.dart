import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.p16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  SizedBox(height: AppSpacing.p16),
                  Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        child: SvgPicture.asset(
                          "assets/logo/valence_logo.svg",
                          colorFilter: ColorFilter.mode(
                            colorScheme.secondary,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: AppSpacing.p8),

                      // App name
                      Text(
                        'VALENCE',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      SizedBox(height: AppSpacing.p8),

                      // Slogan
                      Text(
                        'The Power of Connection',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      SizedBox(height: AppSpacing.p8),
                      Text(
                        'Connect coaches and athletes to\nachieve extraordinary results',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.p16),
                  Column(
                    children: [
                      Text(
                        'I AM A:',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: AppSpacing.p8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectRole('coach'),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'coach'
                                      ? colorScheme.secondary.withOpacity(0.2)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedRole == 'coach'
                                        ? colorScheme.secondary
                                        : colorScheme.onSurface.withOpacity(
                                            0.1,
                                          ),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      size: 32,
                                      color: colorScheme.secondary,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "COACH",
                                      style: textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectRole('client'),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'client'
                                      ? colorScheme.secondary.withOpacity(0.2)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedRole == 'client'
                                        ? colorScheme.secondary
                                        : colorScheme.onSurface.withOpacity(
                                            0.1,
                                          ),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_run,
                                      size: 32,
                                      color: colorScheme.secondary,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "CLIENT",
                                      style: textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.p16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1000),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slide,
                          child: child,
                        ),
                      );
                    },
                    child: _selectedRole != null
                        ? Column(
                      key: const ValueKey('cta_visible'),
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _goToOnboarding,
                            child: Text(
                              'GET STARTED',
                              style: textTheme.titleMedium?.copyWith(

                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.p4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: _goToLogin,
                              child: Text(
                                'Sign in',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        : const SizedBox(
                      key: ValueKey('cta_hidden'),
                    ),
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


}

