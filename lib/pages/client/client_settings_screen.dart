import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/auth/link_coach_screen.dart';
import 'package:valence/pages/shared/language_picker.dart';
import 'package:valence/pages/shared/settings_ui.dart';
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

  // -------------------------------------------------------------------------
  // Logic
  // -------------------------------------------------------------------------

  Future<void> _editProfileName() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final textTheme = theme.textTheme;
        return Dialog(
          backgroundColor: cs.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.settingsDisplayName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: AppSpacing.p16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(hintText: context.l10n.settingsEnterName),
                  onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
                ),
                SizedBox(height: AppSpacing.p20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(context.l10n.cancel),
                      ),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: SettingsGoldButton(
                        label: context.l10n.save,
                        icon: PhosphorIconsBold.check,
                        loading: false,
                        onTap: () => Navigator.pop(ctx, controller.text.trim()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
        SnackBar(content: Text(context.l10n.profileUpdated)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdateError)),
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
        SnackBar(content: Text(context.l10n.settingsSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsSaveError)),
      );
    } finally {
      if (mounted) setState(() => _isSavingPrefs = false);
    }
  }

  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    final email = auth.currentUser?.email ?? '';
    final confirmed = await showSettingsConfirm(
      context,
      icon: PhosphorIconsFill.lockKey,
      iconColor: AppColors.secondaryColor,
      title: context.l10n.changePassword,
      message: context.l10n.changePasswordMsg(email),
      confirmLabel: context.l10n.sendLink,
    );
    if (confirmed != true) return;

    final result = await auth.sendPasswordResetEmail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? context.l10n.resetLinkSent(email) : result.message),
      ),
    );
  }

  void _openLinkCoach() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LinkCoachScreen()),
    );
  }

  Future<void> _showSupport() async {
    const supportEmail = 'support@valence.app';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.helpSupport),
        content: Text(
          context.l10n.supportBody(context.l10n.roleClient),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await Clipboard.setData(const ClipboardData(text: supportEmail));
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text(context.l10n.supportEmailCopied)),
              );
            },
            child: Text(context.l10n.copyEmail),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.close)),
        ],
      ),
    );
  }

  Future<void> _showAbout() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cs.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(PhosphorIconsFill.barbell, color: AppColors.secondaryColor, size: 28),
              ),
              SizedBox(height: AppSpacing.p16),
              Text(
                'Valence',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.aboutVersion,
                style: textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.p12),
              Text(
                context.l10n.aboutTaglineClient,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
              ),
              SizedBox(height: AppSpacing.p20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showSettingsConfirm(
      context,
      icon: PhosphorIconsFill.signOut,
      iconColor: AppColors.statusRed,
      title: context.l10n.logoutConfirmTitle,
      message: context.l10n.logoutConfirmMsg,
      confirmLabel: context.l10n.logOut,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
      (route) => false,
    );
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final coachLinked = user.coachId != null && user.coachId!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? const <String, dynamic>{};
            final notificationsEnabled = (data['notificationsEnabled'] as bool?) ?? true;
            final weightUnit = (data['weightUnit'] as String?) ?? 'kg';

            final sections = <Widget>[
              SettingsScreenTitle(title: context.l10n.settingsTitle),
              SizedBox(height: AppSpacing.p16),
              SettingsProfileCard(
                name: user.name,
                email: user.email,
                badge: context.l10n.badgeMember,
                onTap: _isSavingName ? null : _editProfileName,
              ),
              if (_isSavingName || _isSavingPrefs) ...[
                SizedBox(height: AppSpacing.p12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: cs.secondary,
                    backgroundColor: cs.secondary.withValues(alpha: 0.12),
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.p24),
              SettingsSectionLabel(context.l10n.sectionAccount),
              SizedBox(height: AppSpacing.p8 + 2),
              SettingsGroup(
                rows: [
                  SettingsNavRow(
                    icon: PhosphorIconsFill.link,
                    title: context.l10n.myCoach,
                    subtitle: coachLinked ? context.l10n.coachLinkedLabel : context.l10n.coachNotLinked,
                    value: coachLinked ? null : context.l10n.connect,
                    onTap: _openLinkCoach,
                  ),
                  SettingsNavRow(
                    icon: PhosphorIconsFill.lockKey,
                    title: context.l10n.changePassword,
                    onTap: _changePassword,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.p24),
              SettingsSectionLabel(context.l10n.sectionPreferences),
              SizedBox(height: AppSpacing.p8 + 2),
              SettingsGroup(
                rows: [
                  SettingsNavRow(
                    icon: PhosphorIconsFill.translate,
                    title: context.l10n.settingsLanguage,
                    subtitle: context.l10n.settingsLanguageSubtitle,
                    value: currentLanguageLabel(context),
                    onTap: () => showLanguagePicker(context),
                  ),
                  SettingsSwitchRow(
                    icon: PhosphorIconsFill.moon,
                    title: context.l10n.darkMode,
                    subtitle: context.l10n.darkModeSubtitle,
                    value: themeProvider.isDarkMode,
                    onChanged: (_) {
                      HapticFeedback.selectionClick();
                      context.read<ThemeProvider>().toggleTheme();
                    },
                  ),
                  SettingsSwitchRow(
                    icon: PhosphorIconsFill.bellRinging,
                    title: context.l10n.mealReminders,
                    subtitle: context.l10n.mealRemindersSubtitle,
                    value: notificationsEnabled,
                    onChanged: _isSavingPrefs
                        ? null
                        : (v) => _savePreference('notificationsEnabled', v),
                  ),
                  SettingsSwitchRow(
                    icon: PhosphorIconsFill.scales,
                    title: context.l10n.metricUnits,
                    subtitle: context.l10n.metricUnitsSubtitle,
                    value: weightUnit == 'kg',
                    onChanged: _isSavingPrefs
                        ? null
                        : (metric) => _savePreference('weightUnit', metric ? 'kg' : 'lb'),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.p24),
              SettingsSectionLabel(context.l10n.sectionSupport),
              SizedBox(height: AppSpacing.p8 + 2),
              SettingsGroup(
                rows: [
                  SettingsNavRow(
                    icon: PhosphorIconsFill.lifebuoy,
                    title: context.l10n.helpSupport,
                    onTap: _showSupport,
                  ),
                  SettingsNavRow(
                    icon: PhosphorIconsFill.info,
                    title: context.l10n.aboutValence,
                    value: 'v1.0.0',
                    onTap: _showAbout,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.p24),
              SettingsLogoutButton(onTap: _logout),
              SizedBox(height: AppSpacing.p20),
              Center(
                child: Text(
                  'Valence · v1.0.0',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ];

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.p16,
                AppSpacing.p12,
                AppSpacing.p16,
                AppSpacing.p32,
              ),
              itemCount: sections.length,
              itemBuilder: (context, i) => SettingsEntrance(index: i, child: sections[i]),
            );
          },
        ),
      ),
    );
  }
}
