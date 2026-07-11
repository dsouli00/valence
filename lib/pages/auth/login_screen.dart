import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/auth/link_coach_screen.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.welcomeBackToast)),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.localizedMessage(context.l10n))),
      );
    }
  }

  /// Sends a real Firebase reset email to whatever is typed in the email
  /// field — no separate screen; the field doubles as the input.
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.forgotPasswordEnterEmail)),
      );
      return;
    }
    final result = await context.read<AuthProvider>().sendPasswordResetEmail(email: email);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(result.success ? context.l10n.resetLinkSent(email) : result.localizedMessage(context.l10n))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: colorScheme.secondary,
                        ),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  // Logo
                  Container(
                    height: 80.h,
                    child: SvgPicture.asset(
                      "assets/logo/valence_logo.svg",
                      colorFilter: ColorFilter.mode(
                        colorScheme.secondary,
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Headers
                  Text(
                    l10n.welcomeBackTitle,
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.p4),
                  Text(
                    l10n.loginSubtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppSpacing.p24),

                  Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return l10n.emailRequired;
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: l10n.emailHint,
                        ),
                      ),
                      SizedBox(height: AppSpacing.p16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        validator: (val) {
                          if (val == null || val.isEmpty) return l10n.passwordRequired;
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                          ),
                          hintText: l10n.passwordHint,
                        ),
                      ),
                    ],
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: Text(
                        l10n.forgotPassword,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.p24),
                  _isLoading
                      ? CircularProgressIndicator(color: colorScheme.secondary)
                      : GestureDetector(
                          onTap: _handleLogin,
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
                            child: Text(
                              l10n.signIn,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                  SizedBox(height: AppSpacing.p16),
                  // Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.dontHaveAccount,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
                        ),
                        child: Text(
                          l10n.signUp,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}