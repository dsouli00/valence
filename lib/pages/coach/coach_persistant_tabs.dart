import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/coach/coach_workout_library_screen.dart';
import 'package:valence/pages/coach/clients_screen.dart';
import 'package:valence/pages/coach/coach_settings_screen.dart';
import 'package:valence/ui/ui.dart';

/// The coach's main shell: persistent bottom navigation with Clients /
/// Library / Profile (no chat tab — messaging is deferred; the coach-note
/// flow covers communication for now). "Persistent" = each tab keeps its own
/// navigator and state across switches. Mirrors ClientPersistantTabs.
///
/// DESIGN (§5.20 VTabBar): `surface` bar + top hairline, active = Fill icon +
/// label in goldDeep, inactive = inkTertiary. No shadow, no indicator.
class CoachPersistantTabs extends StatelessWidget {
  const CoachPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final labelStyle = VType.caption.copyWith(fontWeight: FontWeight.w600);
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
          screen: ClientsScreen(),
          item: ItemConfig(
            title: l10n.navClients,
            textStyle: labelStyle,
            icon: PhosphorIcon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.usersThree()),
            activeForegroundColor: t.goldDeep,
            inactiveForegroundColor: t.inkTertiary,
          ),
        ),
        PersistentTabConfig(
          screen: const CoachWorkoutLibraryScreen(),
          item: ItemConfig(
            title: l10n.navLibrary,
            textStyle: labelStyle,
            icon: PhosphorIcon(PhosphorIcons.clipboardText(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.clipboardText()),
            activeForegroundColor: t.goldDeep,
            inactiveForegroundColor: t.inkTertiary,
          ),
        ),
        PersistentTabConfig(
          screen: CoachSettingsScreen(),
          item: ItemConfig(
            title: l10n.navProfile,
            textStyle: labelStyle,
            icon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.user()),
            activeForegroundColor: t.goldDeep,
            inactiveForegroundColor: t.inkTertiary,
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => Style6BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: t.surface,
          border: Border(top: BorderSide(color: t.hairline, width: 1.0)),
        ),
      ),
    );
  }
}
