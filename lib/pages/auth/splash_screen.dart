import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/auth_routing.dart';
import '../../providers/auth_provider.dart';
import '../../ui/ui.dart';

/// First screen on every cold start — the app's ROUTING GATE.
///
/// Shows the logo while restoring the Firebase session, then routes by
/// priority: not signed in → GetStarted; client without coach → LinkCoach;
/// client without a plan → ClientIntake; coach not onboarded → CoachIntake;
/// otherwise the role's main tabs. This ordering must match the `needs*`
/// getters on AuthProvider — signup and link-coach apply the same rules so a
/// user can never land in the app half-set-up.
///
/// DESIGN (§5.5): the gold logo on flat canvas. Nothing else.
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
    // Minimum brand moment — lets the logo animation play instead of
    // flashing straight past it on fast devices.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.initializeAuth();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => landingScreenFor(authProvider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Center(
        child: TweenAnimationBuilder<double>(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 800),
          curve: VMotion.curve,
          tween: Tween<double>(begin: 0.85, end: 1.0),
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: SizedBox(
            height: 96,
            child: SvgPicture.asset(
              'assets/logo/valence_logo.svg',
              colorFilter: ColorFilter.mode(t.gold, BlendMode.srcIn),
              fit: BoxFit.contain,
              semanticsLabel: 'Valence',
            ),
          ),
        ),
      ),
    );
  }
}
