import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/client_intake_draft.dart';
import 'package:valence/models/coach_intake_draft.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/pages/auth/auth_routing.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';

import '../../providers/auth_provider.dart';
import 'login_screen.dart';

/// Account creation, reached at the END of onboarding (personalize-first:
/// the user answers intake questions before hitting this signup wall).
///
/// Role-aware: clients must supply a coach invite code (the app is
/// invite-only for clients); coaches don't. If an intake/coach draft rode
/// along from onboarding it is persisted immediately after the account is
/// created, so the new user lands straight in the app.
class SignupScreen extends StatefulWidget {
  final UserRole userRole;

  /// A client's pre-built plan, collected during onboarding before the account
  /// existed. When present, it's persisted right after signup so the new client
  /// lands straight in the app instead of repeating intake.
  final ClientIntakeDraft? intakeDraft;

  /// A coach's onboarding answers, collected before the account existed. Same
  /// idea as [intakeDraft]: persisted right after signup so the new coach lands
  /// straight in the app.
  final CoachIntakeDraft? coachDraft;

  const SignupScreen({
    super.key,
    required this.userRole,
    this.intakeDraft,
    this.coachDraft,
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

  bool get _isClient => widget.userRole == UserRole.client;

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
    if (_isClient && _inviteController.text.trim().isEmpty) {
      showVToast(context, context.l10n.inviteLinkRequired);
      return;
    }

    setState(() => _isLoading = true);

    final result = await context.read<AuthProvider>().signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: widget.userRole,
          inviteToken: _isClient ? _inviteController.text.trim() : null,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      final auth = context.read<AuthProvider>();

      // Persist the plan the client built during onboarding (before the account
      // existed), then refresh so routing sees a configured client and skips
      // intake. If it fails, the needsIntake gate below catches them.
      final draft = widget.intakeDraft;
      if (draft != null && auth.currentUser != null) {
        try {
          await FirestoreService().saveClientIntake(
            auth.currentUser!.uid,
            age: draft.age,
            heightCm: draft.heightCm,
            currentWeight: draft.currentWeight,
            targetWeight: draft.targetWeight,
            sex: draft.sex.name,
            activityLevel: draft.activity.name,
            goal: draft.goal.name,
            macros: draft.macros,
            priorTracking: draft.priorTracking,
            weightUnit: draft.weightUnit,
          );
          await auth.refreshCurrentUser();
        } catch (_) {
          // Fall through — needsIntake will route them to finish their plan.
        }
        if (!mounted) return;
      }

      // Same for a coach who built their profile during onboarding.
      final cDraft = widget.coachDraft;
      if (cDraft != null && auth.currentUser != null) {
        try {
          await FirestoreService().saveCoachIntake(
            auth.currentUser!.uid,
            specialties: cDraft.specialtyNames,
            experience: cDraft.experience.name,
            rosterBand: cDraft.rosterBand.name,
            priorTool: cDraft.priorTool.name,
          );
          await auth.refreshCurrentUser();
        } catch (_) {
          // Fall through — needsCoachIntake will route them to finish setup.
        }
        if (!mounted) return;
      }

      showVToast(context, context.l10n.accountCreated);
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => landingScreenFor(auth)),
        (route) => false,
      );
    } else {
      showVToast(context, result.localizedMessage(context.l10n));
    }
  }

  void _toGetStarted() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final roleDisplay = _isClient ? l10n.roleAthlete : l10n.roleCoach;

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
                Text(l10n.joinValence,
                    textAlign: TextAlign.center,
                    style: VType.title1.copyWith(color: t.ink)),
                const SizedBox(height: 6),
                Text(l10n.signupSubtitle(roleDisplay),
                    textAlign: TextAlign.center,
                    style: VType.subhead.copyWith(color: t.inkSecondary)),
                const SizedBox(height: 28),
                // The join-your-coach ceremony: a short code links the client.
                if (_isClient) ...[
                  Text(l10n.inviteCode,
                      style: VType.caption.copyWith(color: t.inkSecondary)),
                  const SizedBox(height: 10),
                  VCodeBoxes(controller: _inviteController),
                  const SizedBox(height: 22),
                ],
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  textInputAction: TextInputAction.next,
                  cursorColor: t.gold,
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? l10n.fullNameRequired : null,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    hintText: l10n.fullNameHint,
                    prefixIcon:
                        Icon(PhosphorIconsRegular.user, size: 18, color: t.inkTertiary),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  cursorColor: t.gold,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return l10n.emailRequired;
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(val)) {
                      return l10n.emailInvalid;
                    }
                    return null;
                  },
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
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  cursorColor: t.gold,
                  onFieldSubmitted: (_) => _handleSignup(),
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.passwordRequired;
                    if (val.length < 6) return l10n.passwordTooShort;
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordCreateHint,
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
                const SizedBox(height: 28),
                VPillButton.primary(
                  label: l10n.createAccount,
                  loading: _isLoading,
                  onPressed: _isLoading ? null : _handleSignup,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.alreadyHaveAccount,
                        style: VType.subhead.copyWith(color: t.inkSecondary)),
                    VTextAction(
                      label: l10n.signIn,
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
  }
}
