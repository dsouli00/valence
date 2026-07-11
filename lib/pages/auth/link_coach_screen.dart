import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/client_intake_screen.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/theme/app_theme.dart';

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

    setState(() => _isSubmitting = true);
    final result = await context.read<AuthProvider>().linkClientToCoach(token);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.localizedMessage(context.l10n))),
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.p32),
              Text(
                l10n.linkCoachTitle,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.p8),
              Text(
                l10n.linkCoachSubtitle,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: AppSpacing.p24),
              TextField(
                controller: _inviteController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
                decoration: InputDecoration(
                  labelText: l10n.inviteCode,
                  hintText: l10n.inviteCodeHint,
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: AppSpacing.p16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.continueLabel),
                ),
              ),
              SizedBox(height: AppSpacing.p8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          await context.read<AuthProvider>().signOut();
                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
                            (route) => false,
                          );
                        },
                  child: Text(l10n.logOut),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
