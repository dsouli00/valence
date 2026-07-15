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
/// DESIGN: the bar is [VTabBar] (§5.20) — frosted `surface` + top hairline,
/// active = Fill icon + goldDeep, inactive = inkTertiary. Content scrolls
/// under the glass via `NavBarOverlap.full()`.
class CoachPersistantTabs extends StatelessWidget {
  const CoachPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PersistentTabView(
      navBarOverlap: const NavBarOverlap.full(),
      tabs: [
        PersistentTabConfig(
          screen: ClientsScreen(),
          item: ItemConfig(
            title: l10n.navClients,
            icon: PhosphorIcon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.usersThree()),
          ),
        ),
        PersistentTabConfig(
          screen: const CoachWorkoutLibraryScreen(),
          item: ItemConfig(
            title: l10n.navLibrary,
            icon: PhosphorIcon(PhosphorIcons.clipboardText(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.clipboardText()),
          ),
        ),
        PersistentTabConfig(
          screen: CoachSettingsScreen(),
          item: ItemConfig(
            title: l10n.navProfile,
            icon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.user()),
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => VTabBar(navBarConfig: navBarConfig),
    );
  }
}
