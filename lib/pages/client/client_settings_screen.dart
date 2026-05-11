import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/auth/link_coach_screen.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/providers/theme_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  final _firestoreService = FirestoreService();
  bool _isSavingName = false;
  bool _isSavingPrefs = false;

  Future<void> _editProfileName() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'Enter your name',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (nextName == null || nextName.trim().isEmpty || nextName.trim() == user.name) {
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _firestoreService.updateUserName(user.uid, nextName);
      await auth.refreshCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile right now')),
      );
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSavingPrefs = true);
    try {
      await _firestoreService.updateUserSettings(user.uid, {key: value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save settings')),
      );
    } finally {
      if (mounted) setState(() => _isSavingPrefs = false);
    }
  }

  Future<void> _showSupport() async {
    const supportEmail = 'support@valence.app';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For account or app support, contact support@valence.app.\n\n'
          'Include your role (Client) and a short issue summary.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: supportEmail));
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email copied')),
              );
            },
            child: const Text('Copy Email'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final clientName = user?.name ?? 'Fitness Member';
    final clientEmail = user?.email ?? 'member@valenceapp.com';
    final coachLinked = user?.coachId != null && user!.coachId!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.secondaryColor,
            ),
            iconSize: 30,
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? const <String, dynamic>{};
                  final notificationsEnabled = (data['notificationsEnabled'] as bool?) ?? true;
                  final weightUnit = (data['weightUnit'] as String?) ?? 'kg';

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(AppSpacing.p16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.secondaryColor.withAlpha(50),
                    child: Text(
                      clientName.isNotEmpty ? clientName[0].toUpperCase() : 'U',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: AppSpacing.p4),
                        Text(
                          clientEmail,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.p24),
              if (_isSavingName || _isSavingPrefs) const LinearProgressIndicator(),
              SizedBox(height: AppSpacing.p8),

              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile Name',
                onTap: _isSavingName ? null : _editProfileName,
              ),
              _buildSettingsTile(
                icon: Icons.link_outlined,
                title: coachLinked ? 'Relink Coach' : 'Link a Coach',
                subtitle: coachLinked ? 'Coach linked to your account' : 'Required to use coaching features',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LinkCoachScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: _showSupport,
              ),

              SizedBox(height: AppSpacing.p16),

              // Preferences are loaded from the live user document so switch values
              // always reflect the latest saved state across sessions/devices.
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.p12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: AppTheme.defaultBorderRadius,
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: notificationsEnabled,
                      title: const Text('Meal reminders'),
                      subtitle: const Text('Save preference to your profile'),
                      onChanged: _isSavingPrefs
                          ? null
                          : (enabled) => _savePreference('notificationsEnabled', enabled),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: weightUnit == 'kg',
                      title: const Text('Use metric units (kg)'),
                      subtitle: const Text('Switches app weight unit preference'),
                      onChanged: _isSavingPrefs
                          ? null
                          : (metric) => _savePreference('weightUnit', metric ? 'kg' : 'lb'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.p24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().signOut();
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.p12),
                    foregroundColor: AppColors.statusRed,
                    side: BorderSide(color: AppColors.statusRed.withAlpha(100)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.p24),
              Center(
                child: Text(
                  'Valence Fitness v1.0.0',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                ),
              ),
            ],
          ),
        );
                },
              ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 24),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
