import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/client_intake_screen.dart';
import 'package:valence/pages/auth/coach_intake_screen.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/auth/link_coach_screen.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.initializeAuth();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.needsCoachLink) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LinkCoachScreen()),
        );
        return;
      }

      if (authProvider.needsIntake) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientIntakeScreen()),
        );
        return;
      }

      if (authProvider.needsCoachIntake) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CoachIntakeScreen()),
        );
        return;
      }

      // Redirect based on role
      final role = authProvider.currentUser?.role;

      if (role == UserRole.coach) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CoachPersistantTabs()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClientPersistantTabs()));
      }
    } else {
      // No user? Send them to the very beginning
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GettingStartedScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    height: 100.h,
                    child: SvgPicture.asset(
                      "assets/logo/valence_logo.svg",
                      colorFilter: ColorFilter.mode(
                        colorScheme.secondary,
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: AppSpacing.p24),
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.secondary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
