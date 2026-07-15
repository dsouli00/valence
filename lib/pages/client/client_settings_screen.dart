import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/utils/app_info.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/auth/link_coach_screen.dart';
import 'package:valence/pages/shared/delete_account.dart';
import 'package:valence/pages/shared/language_picker.dart';
import 'package:valence/pages/shared/settings_ui.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/providers/theme_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/services/notification_service.dart';
import 'package:valence/ui/ui.dart';

/// Client settings — built entirely from the shared building blocks in
/// `shared/settings_ui.dart` (design system v2.2, archetype F; the design
/// rules live there). Structure: profile card → ACCOUNT (my coach, change
/// password) → PREFERENCES (language, dark mode, meal reminders + time,
/// weight unit) → SUPPORT → log out → delete account.
///
/// Two different persistence targets, on purpose: meal reminders live in
/// shared_preferences via NotificationService (notifications are PER-DEVICE),
/// while the weight-unit preference is written to the user doc (it must
/// follow the account onto any device). Every row does something real — the
/// screen has a no-placeholder rule.
class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  final _firestoreService = FirestoreService();
  bool _isSavingName = false;
  bool _isSavingPrefs = false;

  // Cache the user-doc stream (house rule: never build a Stream inline in
  // build()) — an inline one restarts on every rebuild (theme flips, saves,
  // sheets closing), flashing the rows back to their defaults mid-frame.
  String? _streamUid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStreamFor(String uid) {
    if (_userStream == null || _streamUid != uid) {
      _streamUid = uid;
      _userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
    return _userStream!;
  }

  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(
    hour: NotificationService.defaultHour,
    minute: NotificationService.defaultMinute,
  );

  @override
  void initState() {
    super.initState();
    _loadReminderPrefs();
  }

  // -------------------------------------------------------------------------
  // Logic
  // -------------------------------------------------------------------------

  Future<void> _loadReminderPrefs() async {
    final enabled = await NotificationService.instance.isEnabled();
    final t = await NotificationService.instance.reminderTime();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = enabled;
      _reminderTime = TimeOfDay(hour: t.hour, minute: t.minute);
    });
  }

  Future<void> _toggleReminders(bool value) async {
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!mounted) return;
      if (!granted) {
        showVToast(context, l10n.remindersPermissionDenied);
        return;
      }
      await NotificationService.instance.enableDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        title: l10n.reminderTitle,
        body: l10n.reminderBody,
      );
      if (!mounted) return;
      setState(() => _remindersEnabled = true);
    } else {
      await NotificationService.instance.disableDailyReminder();
      if (!mounted) return;
      setState(() => _remindersEnabled = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final l10n = context.l10n;
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked == null || !mounted) return;
    setState(() => _reminderTime = picked);
    await NotificationService.instance.enableDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
      title: l10n.reminderTitle,
      body: l10n.reminderBody,
    );
  }

  Future<void> _editProfileName() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    // The sheet owns its controller (design.md §2 — sheets with text fields
    // own + dispose their controllers in their own State).
    final nextName = await showVSheet<String>(
      context: context,
      builder: (_) => _EditNameSheet(initialName: user.name),
    );

    if (nextName == null || nextName.trim().isEmpty || nextName.trim() == user.name) {
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _firestoreService.updateUserName(user.uid, nextName);
      await auth.refreshCurrentUser();
      if (!mounted) return;
      showVToast(context, context.l10n.profileUpdated);
    } catch (_) {
      if (!mounted) return;
      showVToast(context, context.l10n.profileUpdateError);
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isSavingPrefs = true);
    try {
      await _firestoreService.updateUserSettings(user.uid, {key: value});
      // Keep the cached user fresh — home/workout screens read weightUnit
      // from AuthProvider, not from a live stream.
      await auth.refreshCurrentUser();
      if (!mounted) return;
      showVToast(context, context.l10n.settingsSaved);
    } catch (_) {
      if (!mounted) return;
      showVToast(context, context.l10n.settingsSaveError);
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
      iconColor: context.tokens.gold,
      title: context.l10n.changePassword,
      message: context.l10n.changePasswordMsg(email),
      confirmLabel: context.l10n.sendLink,
    );
    if (confirmed != true || !mounted) return;

    final result = await auth.sendPasswordResetEmail();
    if (!mounted) return;
    showVToast(
      context,
      result.success
          ? context.l10n.resetLinkSent(email)
          : result.localizedMessage(context.l10n),
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
    await showVSheet<void>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return VSheet(
          title: ctx.l10n.helpSupport,
          scrollable: false,
          pinnedAction: VPillButton.primary(
            label: ctx.l10n.copyEmail,
            icon: PhosphorIconsBold.copy,
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await Clipboard.setData(const ClipboardData(text: supportEmail));
              if (!mounted) return;
              navigator.pop();
              showVToast(context, context.l10n.supportEmailCopied);
            },
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                ctx.l10n.supportBody(ctx.l10n.roleClient),
                style: VType.body.copyWith(color: t.inkSecondary),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAbout() async {
    await showVSheet<void>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return VSheet(
          scrollable: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: t.gold.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsFill.barbell,
                      size: 28, color: t.goldDeep),
                ),
                const SizedBox(height: 14),
                Text('Valence', style: VType.title2.copyWith(color: t.ink)),
                const SizedBox(height: 2),
                Text(
                  ctx.l10n.aboutVersion(AppInfo.version),
                  style: VType.caption.copyWith(color: t.inkTertiary),
                ),
                const SizedBox(height: 12),
                Text(
                  ctx.l10n.aboutTaglineClient,
                  textAlign: TextAlign.center,
                  style: VType.body.copyWith(color: t.inkSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showSettingsConfirm(
      context,
      icon: PhosphorIconsFill.signOut,
      iconColor: context.tokens.alert,
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
    final t = context.tokens;
    // Rebuild when the theme flips (the dark-mode switch reads the effective
    // brightness, so it must repaint on change).
    context.watch<ThemeProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: t.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final coachLinked = user.coachId != null && user.coachId!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userStreamFor(user.uid),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? const <String, dynamic>{};
            final weightUnit = (data['weightUnit'] as String?) ?? 'kg';

            final sections = <Widget>[
              SettingsScreenTitle(title: context.l10n.settingsTitle),
              const SizedBox(height: 16),
              SettingsProfileCard(
                name: user.name,
                email: user.email,
                badge: context.l10n.badgeMember,
                onTap: _isSavingName ? null : _editProfileName,
              ),
              if (_isSavingName || _isSavingPrefs) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.pill),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: t.gold,
                    backgroundColor: t.gold.withValues(alpha: 0.12),
                  ),
                ),
              ],
              const SizedBox(height: VSpace.sectionGap),
              SettingsSectionLabel(context.l10n.sectionAccount),
              const SizedBox(height: 10),
              SettingsGroup(
                rows: [
                  SettingsNavRow(
                    icon: PhosphorIconsFill.link,
                    title: context.l10n.myCoach,
                    subtitle: coachLinked
                        ? context.l10n.coachLinkedLabel
                        : context.l10n.coachNotLinked,
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
              const SizedBox(height: VSpace.sectionGap),
              SettingsSectionLabel(context.l10n.sectionPreferences),
              const SizedBox(height: 10),
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
                    // Reflect the EFFECTIVE brightness (covers system mode) so
                    // the switch is truthful and one press always flips it.
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      context.read<ThemeProvider>().setDark(v);
                    },
                  ),
                  SettingsSwitchRow(
                    icon: PhosphorIconsFill.bellRinging,
                    title: context.l10n.mealReminders,
                    subtitle: context.l10n.mealRemindersSubtitle,
                    value: _remindersEnabled,
                    onChanged: _toggleReminders,
                  ),
                  if (_remindersEnabled)
                    SettingsNavRow(
                      icon: PhosphorIconsFill.clock,
                      title: context.l10n.reminderTimeLabel,
                      value: MaterialLocalizations.of(context)
                          .formatTimeOfDay(_reminderTime),
                      onTap: _pickReminderTime,
                    ),
                  SettingsSwitchRow(
                    icon: PhosphorIconsFill.scales,
                    title: context.l10n.metricUnits,
                    subtitle: context.l10n.metricUnitsSubtitle,
                    value: weightUnit == 'kg',
                    onChanged: _isSavingPrefs
                        ? null
                        : (metric) =>
                            _savePreference('weightUnit', metric ? 'kg' : 'lb'),
                  ),
                ],
              ),
              const SizedBox(height: VSpace.sectionGap),
              SettingsSectionLabel(context.l10n.sectionSupport),
              const SizedBox(height: 10),
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
                    value: 'v${AppInfo.version}',
                    onTap: _showAbout,
                  ),
                ],
              ),
              const SizedBox(height: VSpace.sectionGap),
              SettingsLogoutButton(onTap: _logout),
              const SizedBox(height: 8),
              SettingsDeleteAccountButton(onTap: () => showDeleteAccountFlow(context)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Valence · v${AppInfo.version}',
                  style: VType.caption.copyWith(color: t.inkTertiary),
                ),
              ),
            ];

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(
                VSpace.screenMargin,
                12,
                VSpace.screenMargin,
                VSpace.scrollBottom + 72,
              ),
              itemCount: sections.length,
              itemBuilder: (context, i) =>
                  SettingsEntrance(index: i, child: sections[i]),
            );
          },
        ),
      ),
    );
  }
}

// ===========================================================================
// Edit-name sheet — owns its controller (design.md §2 sheet law).
// ===========================================================================

class _EditNameSheet extends StatefulWidget {
  final String initialName;
  const _EditNameSheet({required this.initialName});

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return VSheet(
      title: context.l10n.settingsDisplayName,
      pinnedAction: VPillButton.primary(
        label: context.l10n.save,
        onPressed: () {
          HapticFeedback.mediumImpact();
          _submit();
        },
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4, bottom: 8),
        child: VField(
          controller: _controller,
          hint: context.l10n.settingsEnterName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
