import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

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

    final result = await context.read<AuthProvider>().signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Welcome back!")),
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Welcome back!")),
        );

        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        if (user?.role == UserRole.coach) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const CoachPersistantTabs()),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ClientPersistantTabs()),
                (route) => false,
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
                    "Welcome Back",
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.p4),
                  Text(
                    "Sign in to continue your journey.",
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
                          if (val == null || val.trim().isEmpty) return "Email is required";
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: "Enter your email address",
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
                          if (val == null || val.isEmpty) return "Password is required";
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                          ),
                          hintText: "Enter your password",
                        ),
                      ),
                    ],
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
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
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      child: Text(
                        "Sign In",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.p16),
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.p12),
                        child: Text(
                          "or continue with",
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  SizedBox(height: AppSpacing.p16),
                  // Social Buttons
                  OutlinedButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: theme.brightness == Brightness.dark
                              ? SvgPicture.asset("assets/icons/apple_logo_white.svg")
                              : SvgPicture.asset("assets/icons/apple_logo_black.svg"),
                        ),
                        SizedBox(width: AppSpacing.p12),
                        const Text("Sign in with Apple"),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.p12),
                  OutlinedButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: SvgPicture.asset("assets/icons/google_logo.svg"),
                        ),
                        SizedBox(width: AppSpacing.p12),
                        const Text("Sign in with Google"),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacing.p16),
                  // Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
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
                          "Sign up",
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