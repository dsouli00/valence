import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/client/client_home_screen.dart';
import 'package:valence/pages/client/client_progress_screen.dart';
import 'package:valence/pages/client/client_settings_screen.dart';
import 'package:valence/pages/client/client_workouts_screen.dart';
import 'package:valence/ui/ui.dart';

/// The client's main shell: persistent bottom navigation with Today /
/// Workouts / Progress / Profile. "Persistent" matters — each tab keeps its
/// own navigator and state, so switching tabs doesn't rebuild or lose
/// scroll/stream positions. Mirrors CoachPersistantTabs on the coach side.
///
/// DESIGN: the bar is [VTabBar] (§5.20) — frosted `surface` + top hairline,
/// active = Fill icon + goldDeep, inactive = inkTertiary. Content scrolls
/// under the glass via `NavBarOverlap.full()`.
class ClientPersistantTabs extends StatelessWidget {
  const ClientPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PersistentTabView(
      navBarOverlap: const NavBarOverlap.full(),
      tabs: [
        PersistentTabConfig(
          screen: ClientHomeScreen(),
          item: ItemConfig(
            title: l10n.navToday,
            icon: PhosphorIcon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.calendarBlank()),
          ),
        ),
        PersistentTabConfig(
          screen: const ClientWorkoutsScreen(),
          item: ItemConfig(
            title: l10n.navWorkouts,
            icon: PhosphorIcon(PhosphorIcons.barbell(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.barbell()),
          ),
        ),
        PersistentTabConfig(
          screen: ClientProgressScreen(),
          item: ItemConfig(
            title: l10n.navProgress,
            icon: PhosphorIcon(PhosphorIcons.trendUp(PhosphorIconsStyle.bold)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.trendUp()),
          ),
        ),
        PersistentTabConfig(
          screen: ClientSettingsScreen(),
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
