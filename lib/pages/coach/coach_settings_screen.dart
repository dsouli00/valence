import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/providers/theme_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

class CoachSettingsScreen extends StatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  State<CoachSettingsScreen> createState() => _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends State<CoachSettingsScreen> {
  final _firestoreService = FirestoreService();
  String? _latestInviteLink;
  bool _isGenerating = false;
  bool _isSavingName = false;
  bool _isSavingPrefs = false;

  Future<void> _editProfileName() async {
    final auth = context.read<AuthProvider>();
    final coach = auth.currentUser;
    if (coach == null) return;

    final controller = TextEditingController(text: coach.name);
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

    if (nextName == null || nextName.trim().isEmpty || nextName.trim() == coach.name) {
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _firestoreService.updateUserName(coach.uid, nextName);
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
    final coach = context.read<AuthProvider>().currentUser;
    if (coach == null) return;

    setState(() => _isSavingPrefs = true);
    try {
      await _firestoreService.updateUserSettings(coach.uid, {key: value});
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

  Future<void> _generateInviteLink() async {
    final coachId = context.read<AuthProvider>().currentUser?.uid;
    if (coachId == null) return;

    setState(() => _isGenerating = true);
    try {
      // Single-use and expiring by default to reduce accidental token reuse.
      final token = await _firestoreService.createCoachInviteToken(
        coachId,
        ttl: const Duration(days: 7),
        maxUses: 1,
      );
      final link = _firestoreService.buildInviteLink(token);
      if (!mounted) return;
      setState(() => _latestInviteLink = link);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate invite link')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _copyInviteLink() async {
    final link = _latestInviteLink;
    if (link == null || link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied')),
    );
  }

  Future<void> _showSupport() async {
    const supportEmail = 'support@valence.app';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coach Support'),
        content: const Text(
          'For billing, client-management, or technical support:\n'
          'support@valence.app',
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
    final coach = authProvider.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final coachName = coach?.name ?? 'Coach';
    final coachEmail = coach?.email ?? '';

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
        child: coach == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(coach.uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? const <String, dynamic>{};
                  final notificationsEnabled = (data['notificationsEnabled'] as bool?) ?? true;
                  final weeklyReportsEnabled = (data['weeklyReportsEnabled'] as bool?) ?? true;
                  final subscriptionTier = (data['subscriptionTier'] as String?) ?? 'free';
                  final inviteTokens = (data['inviteTokens'] as Map<String, dynamic>?) ?? const {};
                  final activeInvites = inviteTokens.values.where((token) {
                    if (token is! Map<String, dynamic>) return false;
                    return (token['isActive'] as bool?) ?? false;
                  }).length;

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
                                coachName.isNotEmpty ? coachName[0].toUpperCase() : 'C',
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
                                    coachName,
                                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: AppSpacing.p4),
                                  Text(
                                    coachEmail,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.p16),
                        if (_isSavingName || _isSavingPrefs || _isGenerating)
                          const LinearProgressIndicator(),
                        SizedBox(height: AppSpacing.p8),

                        _buildSettingsTile(
                          icon: Icons.person_outline,
                          title: 'Edit Profile Name',
                          onTap: _isSavingName ? null : _editProfileName,
                        ),
                        _buildSettingsTile(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: _showSupport,
                        ),
                        _buildSettingsTile(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Subscription',
                          subtitle: 'Current plan: ${subscriptionTier.toUpperCase()}',
                          onTap: null,
                        ),

                        SizedBox(height: AppSpacing.p16),
                        Text(
                          'SECURE CLIENT INVITE LINK',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: AppSpacing.p12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppSpacing.p16),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor.withAlpha(15),
                            borderRadius: AppTheme.defaultBorderRadius,
                            border: Border.all(color: AppColors.secondaryColor.withAlpha(50)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active invite tokens: $activeInvites',
                                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: AppSpacing.p8),
                              Text(
                                'Generate one-time invite links. Valid links auto-link new clients to your roster as unconfigured.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: AppSpacing.p16),
                              SelectableText(
                                _latestInviteLink ?? 'No active link generated yet',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: _latestInviteLink == null
                                      ? colorScheme.onSurfaceVariant
                                      : AppColors.secondaryColor,
                                  fontWeight: _latestInviteLink == null
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: AppSpacing.p16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isGenerating ? null : _generateInviteLink,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryColor,
                                    foregroundColor: AppColors.primaryColor,
                                  ),
                                  icon: _isGenerating
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.link, size: 18),
                                  label: Text(
                                    _isGenerating ? 'Generating...' : 'Generate New Invite Link',
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.p12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: (_latestInviteLink == null || _isGenerating)
                                      ? null
                                      : _copyInviteLink,
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy Invite Link'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: AppSpacing.p16),
                        // Persisted coach-level preferences for notifications/reporting.
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
                                title: const Text('Client activity notifications'),
                                subtitle: const Text('Save preference to your profile'),
                                onChanged: _isSavingPrefs
                                    ? null
                                    : (enabled) =>
                                        _savePreference('notificationsEnabled', enabled),
                              ),
                              const Divider(height: 1),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: weeklyReportsEnabled,
                                title: const Text('Weekly summary reports'),
                                subtitle: const Text('Email/app digest preference'),
                                onChanged: _isSavingPrefs
                                    ? null
                                    : (enabled) =>
                                        _savePreference('weeklyReportsEnabled', enabled),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Log Out',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
