import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/auth/link_coach_screen.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import 'package:valence/ui/ui.dart';

import '../../models/enums.dart';
import '../../providers/auth_provider.dart';

/// Email/password sign-in for RETURNING users (new users go through the
/// role-specific onboarding from GetStarted instead). After a successful
/// login it applies the same routing rules as SplashScreen — a coach-less
/// client is sent to LinkCoachScreen, everyone else to their role's tabs.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      final user = authProvider.currentUser;

      showVToast(context, context.l10n.welcomeBackToast);

      if (authProvider.needsCoachLink) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LinkCoachScreen()),
          (route) => false,
        );
      } else if (user?.role == UserRole.coach) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CoachPersistantTabs()),
          (route) => false,
        );
      } else {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ClientPersistantTabs()),
          (route) => false,
        );
      }
    } else {
      showVToast(context, result.localizedMessage(context.l10n));
    }
  }

  /// Sends a real Firebase reset email to whatever is typed in the email
  /// field — no separate screen; the field doubles as the input.
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showVToast(context, context.l10n.forgotPasswordEnterEmail);
      return;
    }
    final result = await context.read<AuthProvider>().sendPasswordResetEmail(email: email);
    if (!mounted) return;
    showVToast(
      context,
      result.success
          ? context.l10n.resetLinkSent(email)
          : result.localizedMessage(context.l10n),
    );
  }

  void _toGetStarted() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: VIconCircle(
                    icon: PhosphorIconsBold.caretLeft,
                    onTap: _toGetStarted,
                    semanticLabel: l10n.back,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: SvgPicture.asset(
                    'assets/logo/valence_logo.svg',
                    colorFilter: ColorFilter.mode(t.gold, BlendMode.srcIn),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.welcomeBackTitle,
                    textAlign: TextAlign.center,
                    style: VType.title1.copyWith(color: t.ink)),
                const SizedBox(height: 6),
                Text(l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: VType.subhead.copyWith(color: t.inkSecondary)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  cursorColor: t.gold,
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? l10n.emailRequired : null,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                    prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple,
                        size: 18, color: t.inkTertiary),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  cursorColor: t.gold,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? l10n.passwordRequired : null,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordHint,
                    prefixIcon:
                        Icon(PhosphorIconsRegular.lock, size: 18, color: t.inkTertiary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? PhosphorIconsRegular.eyeSlash
                            : PhosphorIconsRegular.eye,
                        size: 18,
                        color: t.inkTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _isPasswordObscured = !_isPasswordObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: VTextAction(label: l10n.forgotPassword, onTap: _forgotPassword),
                ),
                const SizedBox(height: 20),
                VPillButton.primary(
                  label: l10n.signIn,
                  loading: _isLoading,
                  onPressed: _isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.dontHaveAccount,
                        style: VType.subhead.copyWith(color: t.inkSecondary)),
                    VTextAction(label: l10n.signUp, onTap: _toGetStarted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
