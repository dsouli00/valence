import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/theme/app_theme.dart';

/// Shared "delete my own account" flow used by both coach and client settings.
///
/// Shows a single destructive dialog that explains permanence AND collects the
/// password (Firebase requires a recent login to delete). On success it signs
/// the user out and returns them to the get-started screen.
Future<void> showDeleteAccountFlow(BuildContext context) async {
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (deleted == true && context.mounted) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
      (route) => false,
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() => _error = context.l10n.deleteAccountConfirmPassword);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context.read<AuthProvider>().deleteAccount(password: password);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;
    const danger = AppColors.statusRed;

    return Dialog(
      backgroundColor: cs.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: danger.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(PhosphorIconsFill.trash, color: danger, size: 20),
                ),
                SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    l10n.deleteAccount,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.p12),
            Text(
              l10n.deleteAccountWarning,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            SizedBox(height: AppSpacing.p16),
            TextField(
              controller: _controller,
              obscureText: true,
              enabled: !_loading,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _loading ? null : _delete(),
              decoration: InputDecoration(
                hintText: l10n.password,
                prefixIcon: const Icon(PhosphorIconsBold.lockKey, size: 18),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: AppSpacing.p8),
              Text(
                _error!,
                style: textTheme.labelSmall?.copyWith(color: danger, fontWeight: FontWeight.w600),
              ),
            ],
            SizedBox(height: AppSpacing.p20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                ),
                SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: GestureDetector(
                    onTap: _loading ? null : _delete,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: danger.withValues(alpha: _loading ? 0.5 : 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(
                              l10n.deleteAccount,
                              style: textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
