import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:valence/pages/auth/get_started.dart';
import '../../theme/app_theme.dart';
// import 'package:valence/pages/auth/login_screen.dart'; // TODO: Update import


class SignupScreen extends StatefulWidget {
  final String userRole;

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
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement actual Signup Logic here using your provider
    // final success = await provider.signup(
    //   role: widget.role.name,
    //   name: _nameController.text.trim(),
    //   email: _emailController.text.trim(),
    //   password: _passwordController.text,
    // );

    await Future.delayed(const Duration(seconds: 2)); // Simulated delay

    if (mounted) setState(() => _isLoading = false);

    // TODO: Handle success/error navigation
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String roleDisplay = widget.userRole == "coach" ? "Coach" : "Client";

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
                    "Join Valence",
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.p4),
                  Text(
                    "Create your premium $roleDisplay account.",
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppSpacing.p24),

                  Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Full Name is required";
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: "Full Name",

                          prefixIcon: Icon(Icons.person_outline),
                          hintText: "Enter your full name",
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
                          if (val == null || val.trim().isEmpty) return "Email is required";
                          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val)) {
                            return "Please enter a valid email address";
                          }
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
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Password is required";
                          if (val.length < 6) return "Password must be at least 6 characters";
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
                          hintText: "Create a secure password",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.p32),
                  _isLoading
                      ? CircularProgressIndicator(color: colorScheme.secondary)
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSignup,
                      child: Text(
                        "Create Account",
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
                        const Text("Sign up with Apple"),
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
                        const Text("Sign up with Google"),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacing.p16),
                  // Footer Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Sign in",
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