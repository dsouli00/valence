import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/auth/client_intake_screen.dart';
import 'package:valence/pages/auth/coach_intake_screen.dart';
import 'package:valence/pages/auth/link_coach_screen.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';


class SignupScreen extends StatefulWidget {
  final UserRole userRole;

  const SignupScreen({
    super.key, required this.userRole,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Client onboarding is invite-only so every client account is linked to a coach.
    if (widget.userRole == UserRole.client &&
        _inviteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.inviteLinkRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await context.read<AuthProvider>().signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: widget.userRole,
      inviteToken:
          widget.userRole == UserRole.client ? _inviteController.text.trim() : null,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      final user = context.read<AuthProvider>().currentUser;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountCreated)),
      );
      if (context.read<AuthProvider>().needsCoachLink) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LinkCoachScreen()),
          (route) => false,
        );
      } else if (context.read<AuthProvider>().needsIntake) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ClientIntakeScreen()),
          (route) => false,
        );
      } else if (context.read<AuthProvider>().needsCoachIntake) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CoachIntakeScreen()),
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
        SnackBar(
          content: Text(result.message.isEmpty ? context.l10n.couldNotCreateAccount : result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    final String roleDisplay = widget.userRole == UserRole.coach ? l10n.roleCoach : l10n.roleClient;

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
                          MaterialPageRoute(builder: (_) => GettingStartedScreen()),
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

                  // Headers (Relying purely on your textTheme)
                  Text(
                    l10n.joinValence,
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.p4),
                  Text(
                    l10n.signupSubtitle(roleDisplay),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppSpacing.p24),

                  Column(
                    children: [
                      if (widget.userRole == UserRole.client) ...[
                        // A short code from the coach links the client securely.
                        TextFormField(
                          controller: _inviteController,
                          autovalidateMode: AutovalidateMode.onUnfocus,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                          validator: (val) {
                            if (widget.userRole == UserRole.client &&
                                (val == null || val.trim().isEmpty)) {
                              return l10n.inviteCodeRequired;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: l10n.inviteCode,
                            prefixIcon: const Icon(Icons.confirmation_number_outlined),
                            hintText: l10n.inviteCodeHint,
                          ),
                        ),
                        SizedBox(height: AppSpacing.p16),
                      ],
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return l10n.fullNameRequired;
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: l10n.fullName,
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: l10n.fullNameHint,
                        ),
                      ),
                      SizedBox(height: AppSpacing.p16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return l10n.emailRequired;
                          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val)) {
                            return l10n.emailInvalid;
                          }
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
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        validator: (val) {
                          if (val == null || val.isEmpty) return l10n.passwordRequired;
                          if (val.length < 6) return l10n.passwordTooShort;
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
                          hintText: l10n.passwordCreateHint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.p32),
                  _isLoading
                      ? CircularProgressIndicator(color: colorScheme.secondary)
                      : GestureDetector(
                          onTap: _handleSignup,
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
                              l10n.createAccount,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                  SizedBox(height: AppSpacing.p16),
                  // Footer Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          l10n.signIn,
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
