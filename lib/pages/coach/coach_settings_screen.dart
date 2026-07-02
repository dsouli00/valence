import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/config/plans.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/utils/app_info.dart';
import 'package:valence/l10n/auth_error_l10n.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/pages/auth/get_started.dart';
import 'package:valence/pages/coach/upgrade_screen.dart';
import 'package:valence/pages/shared/delete_account.dart';
import 'package:valence/pages/shared/language_picker.dart';
import 'package:valence/pages/shared/settings_ui.dart';
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
  bool _isSavingName = false;
  bool _isSavingPrefs = false;

  // -------------------------------------------------------------------------
  // Logic
  // -------------------------------------------------------------------------

  Future<void> _editProfileName() async {
    final auth = context.read<AuthProvider>();
    final coach = auth.currentUser;
    if (coach == null) return;

    final controller = TextEditingController(text: coach.name);
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

    if (nextName == null || nextName.trim().isEmpty || nextName.trim() == coach.name) {
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _firestoreService.updateUserName(coach.uid, nextName);
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
    final coach = context.read<AuthProvider>().currentUser;
    if (coach == null) return;

    setState(() => _isSavingPrefs = true);
    try {
      await _firestoreService.updateUserSettings(coach.uid, {key: value});
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
        content: Text(result.success ? context.l10n.resetLinkSent(email) : result.localizedMessage(context.l10n)),
      ),
    );
  }

  Future<void> _openInviteSheet() async {
    final coach = context.read<AuthProvider>().currentUser;
    final coachId = coach?.uid;
    if (coachId == null) return;

    // Gate: block inviting beyond the plan's client limit.
    final tier = effectivePlanTier(
      tierId: coach?.subscriptionTier,
      expiry: coach?.subscriptionExpiryDate,
    );
    final max = planDefFor(tier).maxClients;
    if (max != null) {
      final clients = await _firestoreService.streamClientsByCoach(coachId).first;
      if (!mounted) return;
      if (clients.length >= max) {
        await _showLimitReached(max);
        return;
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteClientSheet(service: _firestoreService, coachId: coachId),
    );
  }

  void _openUpgrade() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
    );
  }

  Future<void> _showLimitReached(int limit) async {
    final view = await showSettingsConfirm(
      context,
      icon: PhosphorIconsFill.crown,
      iconColor: AppColors.secondaryColor,
      title: context.l10n.clientLimitTitle,
      message: context.l10n.clientLimitBody(limit),
      confirmLabel: context.l10n.viewPlans,
    );
    if (view != true || !mounted) return;
    _openUpgrade();
  }

  Future<void> _showSupport() async {
    const supportEmail = 'support@valence.app';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.coachSupportTitle),
        content: Text(
          context.l10n.coachSupportBody,
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
                context.l10n.aboutVersion(AppInfo.version),
                style: textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.p12),
              Text(
                context.l10n.aboutTaglineCoach,
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
    final coach = context.watch<AuthProvider>().currentUser;

    if (coach == null) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(coach.uid).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? const <String, dynamic>{};
            final notificationsEnabled = (data['notificationsEnabled'] as bool?) ?? true;
            final subscriptionTier = (data['subscriptionTier'] as String?) ?? 'free';

            final sections = <Widget>[
              SettingsScreenTitle(title: context.l10n.settingsTitle),
              SizedBox(height: AppSpacing.p16),
              SettingsProfileCard(
                name: coach.name,
                email: coach.email,
                badge: context.l10n.badgeCoach,
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
                  _PlanRow(
                    tier: subscriptionTier,
                    clientStream: _firestoreService.streamClientsByCoach(coach.uid),
                    onTap: _openUpgrade,
                  ),
                  SettingsNavRow(
                    icon: PhosphorIconsFill.userPlus,
                    title: context.l10n.inviteAClient,
                    onTap: _openInviteSheet,
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
                    icon: PhosphorIconsFill.bell,
                    title: context.l10n.clientActivityAlerts,
                    subtitle: context.l10n.clientActivityAlertsSubtitle,
                    value: notificationsEnabled,
                    onChanged: _isSavingPrefs
                        ? null
                        : (v) => _savePreference('notificationsEnabled', v),
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
                    value: 'v${AppInfo.version}',
                    onTap: _showAbout,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.p24),
              SettingsLogoutButton(onTap: _logout),
              SizedBox(height: AppSpacing.p8),
              SettingsDeleteAccountButton(onTap: () => showDeleteAccountFlow(context)),
              SizedBox(height: AppSpacing.p12),
              Center(
                child: Text(
                  'Valence · v${AppInfo.version}',
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

// ===========================================================================
// Plan row — informational, live client count (coach-specific).
// ===========================================================================

class _PlanRow extends StatelessWidget {
  final String tier;
  final Stream<List<AppUser>> clientStream;
  final VoidCallback onTap;

  const _PlanRow({required this.tier, required this.clientStream, required this.onTap});

  String _planName(BuildContext context, PlanTier t) {
    final l10n = context.l10n;
    switch (t) {
      case PlanTier.pro:
        return l10n.planPro;
      case PlanTier.studio:
        return l10n.planStudio;
      case PlanTier.free:
        return l10n.planFree;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final def = planDefFor(planTierFromId(tier));
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            const SettingsIconBox(icon: PhosphorIconsFill.crown),
            SizedBox(width: AppSpacing.p16),
            Text(context.l10n.planLabel, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: clientStream,
                builder: (context, snap) {
                  final count = snap.data?.length ?? 0;
                  final usage = def.maxClients == null
                      ? context.l10n.clientsCount(count)
                      : context.l10n.planUsageLimited(count, def.maxClients!);
                  return Padding(
                    padding: EdgeInsets.only(left: AppSpacing.p8),
                    child: Text(
                      '${_planName(context, def.tier)} · $usage',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: AppSpacing.p8),
            Icon(PhosphorIconsBold.caretRight,
                size: 15, color: cs.onSurfaceVariant.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Invite-client sheet — clean (coach-specific), generate + copy link.
// ===========================================================================

class _InviteClientSheet extends StatefulWidget {
  final FirestoreService service;
  final String coachId;

  const _InviteClientSheet({required this.service, required this.coachId});

  @override
  State<_InviteClientSheet> createState() => _InviteClientSheetState();
}

class _InviteClientSheetState extends State<_InviteClientSheet> {
  String? _code;
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final code = await widget.service.createCoachInviteToken(
        widget.coachId,
        ttl: const Duration(days: 7),
        maxUses: 1,
      );
      if (!mounted) return;
      setState(() => _code = code);
      HapticFeedback.lightImpact();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.inviteGenerateError)),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copyCode() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.inviteCodeCopied)),
    );
  }

  Future<void> _copyLink() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: widget.service.buildInviteLink(code)));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.inviteLinkCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final code = _code;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.p20,
        right: AppSpacing.p20,
        top: AppSpacing.p12,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.p16),
            Text(
              context.l10n.inviteAClient.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.inviteSheetSubtitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: AppSpacing.p12),
            Text(
              context.l10n.inviteSheetBody,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            SizedBox(height: AppSpacing.p20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: code == null
                    ? cs.surfaceContainerLow
                    : AppColors.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: code == null
                      ? cs.outlineVariant.withValues(alpha: 0.3)
                      : AppColors.secondaryColor.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: code == null
                    ? Text(
                        context.l10n.inviteNoCode,
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      )
                    : SelectableText(
                        code,
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
              ),
            ),
            SizedBox(height: AppSpacing.p16),
            Row(
              children: [
                Expanded(
                  child: SettingsGoldButton(
                    label: _generating
                        ? context.l10n.generating
                        : (code == null ? context.l10n.generateCode : context.l10n.newCode),
                    icon: PhosphorIconsBold.plus,
                    loading: _generating,
                    onTap: _generating ? null : _generate,
                  ),
                ),
                SizedBox(width: AppSpacing.p8),
                SettingsOutlineIconButton(
                  icon: PhosphorIconsBold.copy,
                  tooltip: context.l10n.copyCode,
                  onTap: (code == null || _generating) ? null : _copyCode,
                ),
                SizedBox(width: AppSpacing.p8),
                SettingsOutlineIconButton(
                  icon: PhosphorIconsBold.link,
                  tooltip: context.l10n.copyLink,
                  onTap: (code == null || _generating) ? null : _copyLink,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
