import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/ui/ui.dart';

/// Shared settings building blocks used by both the coach and client settings
/// screens — design system v2.2, archetype F (design.md §4-F/§5.10): `label`
/// group headers (the ONLY uppercase in the app), VGroupCard-style groups,
/// rows with 30px tinted icon circles, values in `subhead`, Cupertino-style
/// switches, confirms via VSheet. Gradient rings / gold buttons / outlined
/// boxes are retired.

// ===========================================================================
// Screen title + section label
// ===========================================================================

class SettingsScreenTitle extends StatelessWidget {
  final String title;
  const SettingsScreenTitle({super.key, this.title = 'Settings'});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, top: 4),
      child: Text(title, style: VType.title1.copyWith(color: t.ink)),
    );
  }
}

/// Settings group header — the one place uppercase+tracking is allowed
/// (design.md §1.2 `label`).
class SettingsSectionLabel extends StatelessWidget {
  final String label;
  const SettingsSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        label.toUpperCase(),
        style: VType.label.copyWith(color: t.inkTertiary),
      ),
    );
  }
}

// ===========================================================================
// Profile card — surface card, VAvatar (no rings), quiet role tag.
// ===========================================================================

class SettingsProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String badge;
  final VoidCallback? onTap;

  const SettingsProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return VPressable(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      overlay: true,
      overlayRadius: BorderRadius.circular(VRadius.card),
      child: Container(
        padding: const EdgeInsets.all(VSpace.cardPadding),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          boxShadow: t.cardShadow,
        ),
        child: Row(
          children: [
            VAvatar(name: name, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.headline.copyWith(color: t.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.subhead.copyWith(color: t.inkSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.tintFill(t.gold),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    child: Text(
                      badge,
                      style: VType.caption.copyWith(
                        color: t.goldDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onTap != null)
              Icon(PhosphorIconsBold.pencilSimple, size: 16, color: t.goldDeep),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Grouped inset list + rows
// ===========================================================================

class SettingsGroup extends StatelessWidget {
  final List<Widget> rows;
  const SettingsGroup({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(Padding(
          padding: const EdgeInsetsDirectional.only(start: 58),
          child: Divider(height: 1, thickness: 1, color: t.hairline),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// 30px tinted icon circle for grouped rows (design.md §4-F). Gold by default.
class SettingsIconBox extends StatelessWidget {
  final IconData icon;
  const SettingsIconBox({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: t.tintFill(t.gold),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 15, color: t.legibleTint(t.gold)),
    );
  }
}

class SettingsNavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VPressable(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      overlay: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
              horizontal: 14, vertical: subtitle == null ? 13 : 10),
          child: Row(
            children: [
              SettingsIconBox(icon: icon),
              const SizedBox(width: 14),
              // The value is deliberately NOT flexible any more, and this is
              // the whole fix. Both children used to carry flex 1: the text is
              // `Expanded` (tight — takes exactly its share) and the value was
              // `Flexible` (loose — takes only what it needs), and a loose
              // child's leftovers are never handed back. So the text column was
              // pinned to half the row however short the value was, and
              // "Choose your app language" wrapped in ENGLISH while "System
              // default" sat in a half-empty column beside it.
              //
              // Sizing the value intrinsically (capped, so a long one can still
              // ellipsize rather than overflow) means it is measured FIRST and
              // the text column receives everything actually left over.
              //
              // Tried 5:3 first. It fixed the wrap and broke the value instead
              // — "System defa…". Splitting a row two ways by ratio cannot work
              // when only one side knows how much it needs.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VType.body.copyWith(
                        color: t.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        // Two lines is a settings row; three is a paragraph,
                        // and it drags the icon far off the row's centre.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VType.caption.copyWith(color: t.inkSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: VType.subhead.copyWith(color: t.inkSecondary),
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(PhosphorIconsBold.caretRight, size: 14, color: t.inkTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SettingsIconBox(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VType.body.copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: VType.caption.copyWith(color: t.inkSecondary),
                ),
              ],
            ),
          ),
          // Cupertino-style switch; ON = ink (ink carries active states, §1.1).
          Switch.adaptive(
            value: value,
            activeTrackColor: t.ink,
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? t.onInk : null,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Buttons
// ===========================================================================

/// Legacy name kept for both settings screens — now THE primary pill
/// (design.md §5.10: GoldButton → VPillButton).
class SettingsGoldButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  const SettingsGoldButton({
    super.key,
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VPillButton.primary(
      label: label,
      icon: icon,
      loading: loading,
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap!();
            },
    );
  }
}

class SettingsOutlineIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const SettingsOutlineIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        child: VPressable(
          onTap: onTap,
          semanticButton: false,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: t.surfaceSubtle,
              borderRadius: BorderRadius.circular(VRadius.input),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? t.ink : t.inkTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Log out is SECONDARY, not destructive.
///
/// It used to be a full-width red destructive pill sitting directly above the
/// red "Delete account" text action — the routine weekly action and the
/// irreversible one carrying nearly the same weight, and the eye reading two
/// warnings stacked. Nothing is destroyed by logging out; you sign back in.
///
/// Reserving red for what actually destroys is also what makes Delete account
/// read as serious, which is the whole reason it is red.
class SettingsLogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const SettingsLogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return VPillButton.secondary(
      label: context.l10n.logOut,
      icon: PhosphorIconsBold.signOut,
      onPressed: onTap,
    );
  }
}

/// Low-prominence destructive "Delete account" text row. Reachable (store
/// requirement) but visually quieter than Log Out so it isn't hit by accident.
class SettingsDeleteAccountButton extends StatelessWidget {
  final VoidCallback onTap;
  const SettingsDeleteAccountButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: VTextAction(
        icon: PhosphorIconsBold.trash,
        label: context.l10n.deleteAccount,
        color: t.alert,
        onTap: onTap,
      ),
    );
  }
}

// ===========================================================================
// Staggered entrance + shared confirm sheet
// ===========================================================================

class SettingsEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  const SettingsEntrance({super.key, required this.index, required this.child});

  @override
  State<SettingsEntrance> createState() => _SettingsEntranceState();
}

class _SettingsEntranceState extends State<SettingsEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: VMotion.curve));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: (widget.index.clamp(0, 10)) * 40), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion → land instantly (design.md §1.7).
    if (MediaQuery.of(context).disableAnimations) _c.value = 1.0;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Shared confirm — a VSheet (AlertDialog retired app-wide, design.md §2):
/// tinted icon circle + message, solid confirm (destructive or primary) over a
/// secondary cancel.
Future<bool?> showSettingsConfirm(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showVSheet<bool>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      final confirm = destructive
          ? VPillButton.destructive(
              label: confirmLabel,
              solid: true,
              onPressed: () => Navigator.pop(ctx, true),
            )
          : VPillButton.primary(
              label: confirmLabel,
              onPressed: () => Navigator.pop(ctx, true),
            );
      return VSheet(
        title: title,
        scrollable: false,
        pinnedAction: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            confirm,
            const SizedBox(height: 8),
            VPillButton.secondary(
              label: ctx.l10n.cancel,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.tintFill(iconColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: t.legibleTint(iconColor)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: VType.body.copyWith(color: t.inkSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
