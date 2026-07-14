import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/ui/ui.dart';

/// Shared "delete my own account" flow used by both coach and client settings
/// — a destructive VSheet (design.md §5.18) that explains permanence AND
/// collects the password (Firebase requires a recent login to delete). On
/// success it signs the user out and returns them to the get-started screen.
Future<void> showDeleteAccountFlow(BuildContext context) async {
  final deleted = await showVSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => const _DeleteAccountSheet(),
  );
  if (deleted == true && context.mounted) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
      (route) => false,
    );
  }
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
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
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context.read<AuthProvider>().deleteAccount(password: password);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _loading = false;
        _error = result.localizedMessage(context.l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;

    return VSheet(
      title: l10n.deleteAccount,
      pinnedAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VPillButton.destructive(
            label: l10n.deleteAccount,
            solid: true,
            loading: _loading,
            onPressed: _loading ? null : _delete,
          ),
          const SizedBox(height: 8),
          VPillButton.secondary(
            label: l10n.cancel,
            onPressed: _loading ? null : () => Navigator.pop(context, false),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.tintFill(t.alert),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIconsFill.trash, size: 19, color: t.alert),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.deleteAccountWarning,
                  style: VType.body.copyWith(color: t.inkSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          VField(
            controller: _controller,
            hint: l10n.password,
            obscureText: true,
            enabled: !_loading,
            autofocus: true,
            errorText: _error,
            textInputAction: TextInputAction.done,
            prefix: Icon(PhosphorIconsBold.lockKey, size: 18, color: t.inkTertiary),
            onSubmitted: (_) => _loading ? null : _delete(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
