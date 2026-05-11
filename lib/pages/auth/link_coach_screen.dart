import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/theme/app_theme.dart';

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
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ClientPersistantTabs()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
                'Enter Coach Invite Link',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.p8),
              Text(
                'You must link a coach before using the app.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: AppSpacing.p24),
              TextField(
                controller: _inviteController,
                decoration: const InputDecoration(
                  labelText: 'Coach Invite Link',
                  hintText: 'Paste invite link or token',
                  prefixIcon: Icon(Icons.link_outlined),
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
                      : const Text('Continue'),
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
                  child: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
