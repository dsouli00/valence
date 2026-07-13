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
import 'package:valence/ui/ui.dart';

/// Coach settings — built from the shared blocks in `shared/settings_ui.dart`
/// (design system v2.2, archetype F; the design rules live there). Structure:
/// profile card → ACCOUNT (plan row with live client count → paywall, invite
/// a client, change password) → PREFERENCES (dark mode, language, client
/// alerts) → SUPPORT → log out → delete account.
///
/// The invite flow is GATED by the plan's client limit (config/plans.dart):
/// at the cap, "Invite a client" routes to the UpgradeScreen instead of
/// generating a code. Every row does something real — no placeholder rows.
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

    // The sheet owns its controller (design.md §2 — sheets with text fields
    // own + dispose their controllers in their own State).
    final nextName = await showVSheet<String>(
      context: context,
      builder: (_) => _EditNameSheet(initialName: coach.name),
    );

    if (nextName == null || nextName.trim().isEmpty || nextName.trim() == coach.name) {
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _firestoreService.updateUserName(coach.uid, nextName);
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
    final coach = context.read<AuthProvider>().currentUser;
    if (coach == null) return;

    setState(() => _isSavingPrefs = true);
    try {
      await _firestoreService.updateUserSettings(coach.uid, {key: value});
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
    await showVSheet<void>(
      context: context,
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
      iconColor: context.tokens.gold,
      title: context.l10n.clientLimitTitle,
      message: context.l10n.clientLimitBody(limit),
      confirmLabel: context.l10n.viewPlans,
    );
    if (view != true || !mounted) return;
    _openUpgrade();
  }

  Future<void> _showSupport() async {
    const supportEmail = 'support@valence.app';
    await showVSheet<void>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return VSheet(
          title: ctx.l10n.coachSupportTitle,
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
                ctx.l10n.coachSupportBody,
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
                  ctx.l10n.aboutTaglineCoach,
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
    final coach = context.watch<AuthProvider>().currentUser;

    if (coach == null) {
      return Scaffold(
        backgroundColor: t.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: t.canvas,
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
              const SizedBox(height: 16),
              SettingsProfileCard(
                name: coach.name,
                email: coach.email,
                badge: context.l10n.badgeCoach,
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
              itemBuilder: (context, i) => SettingsEntrance(index: i, child: sections[i]),
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
    final t = context.tokens;
    final def = planDefFor(planTierFromId(tier));
    return VPressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      overlay: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            const SettingsIconBox(icon: PhosphorIconsFill.crown),
            const SizedBox(width: 14),
            Text(
              context.l10n.planLabel,
              style: VType.body.copyWith(color: t.ink, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: clientStream,
                builder: (context, snap) {
                  final count = snap.data?.length ?? 0;
                  final usage = def.maxClients == null
                      ? context.l10n.clientsCount(count)
                      : context.l10n.planUsageLimited(count, def.maxClients!);
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Text(
                      '${_planName(context, def.tier)} · $usage',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: VType.subhead.copyWith(
                        color: t.inkSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Icon(PhosphorIconsBold.caretRight, size: 14, color: t.inkTertiary),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Invite-client sheet — VSheet, generate + copy code/link.
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
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (!mounted) return;
      showVToast(context, context.l10n.inviteGenerateError);
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
    showVToast(context, context.l10n.inviteCodeCopied);
  }

  Future<void> _copyLink() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: widget.service.buildInviteLink(code)));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    showVToast(context, context.l10n.inviteLinkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final code = _code;

    return VSheet(
      title: context.l10n.inviteSheetSubtitle,
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.inviteSheetBody,
            style: VType.subhead.copyWith(color: t.inkSecondary),
          ),
          const SizedBox(height: 18),
          // The code display — quiet track until a code exists, then the gold
          // selected treatment (ring + wash) with the code in big tabular ink.
          AnimatedContainer(
            duration: VDuration.standard,
            curve: VMotion.curve,
            width: double.infinity,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: code == null
                  ? t.surfaceSubtle
                  : Color.alphaBlend(t.selectedWash, t.surface),
              borderRadius: BorderRadius.circular(VRadius.cardSmall),
              border: Border.all(
                color: code == null ? Colors.transparent : t.gold,
                width: 1.5,
              ),
            ),
            child: Center(
              child: code == null
                  ? Text(
                      context.l10n.inviteNoCode,
                      style: VType.body.copyWith(color: t.inkTertiary),
                    )
                  : SelectableText(
                      code,
                      style: VType.stat(26).copyWith(
                        color: t.goldDeep,
                        letterSpacing: 6,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SettingsGoldButton(
                  label: code == null
                      ? context.l10n.generateCode
                      : context.l10n.newCode,
                  icon: PhosphorIconsBold.plus,
                  loading: _generating,
                  onTap: _generating ? null : _generate,
                ),
              ),
              const SizedBox(width: 8),
              SettingsOutlineIconButton(
                icon: PhosphorIconsBold.copy,
                tooltip: context.l10n.copyCode,
                onTap: (code == null || _generating) ? null : _copyCode,
              ),
              const SizedBox(width: 8),
              SettingsOutlineIconButton(
                icon: PhosphorIconsBold.link,
                tooltip: context.l10n.copyLink,
                onTap: (code == null || _generating) ? null : _copyLink,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
