import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/client_intake_screen.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/ui/ui.dart';

/// Blocking screen for an authenticated client who has NO coach — the app is
/// useless without that relationship, so the only ways out are entering a
/// valid invite code (redeemed atomically, then on to intake/home) or logging
/// out. Users land here from splash/signup when `AuthProvider.needsCoachLink`
/// is true (signed up without a code, redeem race, or their coach deleted
/// their account).
class LinkCoachScreen extends StatefulWidget {
  const LinkCoachScreen({super.key});

  @override
  State<LinkCoachScreen> createState() => _LinkCoachScreenState();
}

class _LinkCoachScreenState extends State<LinkCoachScreen> {
  final _inviteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _inviteController.text.trim();
    if (token.isEmpty || _isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final result = await context.read<AuthProvider>().linkClientToCoach(token);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      showVToast(context, result.localizedMessage(context.l10n));
      return;
    }

    final needsIntake = context.read<AuthProvider>().needsIntake;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            needsIntake ? const ClientIntakeScreen() : const ClientPersistantTabs(),
      ),
      (route) => false,
    );
  }

  Future<void> _logOut() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: VSkyGlow(alpha: 0.10)),
          SafeArea(
            child: Column(
              children: [
                // This screen is designed as a ROOT gate — no app bar, no back
                // — and that is right when it is the first thing after sign-up.
                // But Settings also pushes it, and there it became a dead end:
                // the code field autofocuses so the keyboard cannot be
                // dismissed, and the only two visible controls were Continue
                // (which needs a valid code) and Log out. Android back worked;
                // nothing on screen said so.
                //
                // So: a close affordance exactly when there is something to
                // close back to, and none when this IS the gate.
                if (Navigator.of(context).canPop())
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 0, 0),
                      child: VIconCircle(
                        icon: PhosphorIconsBold.x,
                        semanticLabel: l10n.close,
                        onTap: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: t.tintFill(t.gold),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(PhosphorIconsFill.ticket,
                              size: 26, color: t.legibleTint(t.gold)),
                        ),
                        const SizedBox(height: 20),
                        Text(l10n.linkCoachTitle,
                            textAlign: TextAlign.center,
                            style: VType.title1.copyWith(color: t.ink)),
                        const SizedBox(height: 8),
                        Text(l10n.linkCoachSubtitle,
                            textAlign: TextAlign.center,
                            style: VType.body.copyWith(color: t.inkSecondary)),
                        const SizedBox(height: 32),
                        VCodeBoxes(
                          controller: _inviteController,
                          autofocus: true,
                          onCompleted: (_) => _submit(),
                        ),
                        const SizedBox(height: 28),
                        VPillButton.primary(
                          label: l10n.continueLabel,
                          loading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                  child: VTextAction(
                    label: l10n.logOut,
                    onTap: _isSubmitting ? null : _logOut,
                    color: t.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
