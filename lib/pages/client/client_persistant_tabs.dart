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
/// DESIGN (§5.20 VTabBar): `surface` bar + top hairline, active = Fill icon +
/// label in goldDeep, inactive = inkTertiary. No shadow, no indicator.
class ClientPersistantTabs extends StatelessWidget {
  const ClientPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final labelStyle = VType.caption.copyWith(fontWeight: FontWeight.w600);
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
          screen: ClientHomeScreen(),
          item: ItemConfig(
            title: l10n.navToday,
            textStyle: labelStyle,
            icon: PhosphorIcon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.calendarBlank()),
            activeForegroundColor: t.goldDeep,
            inactiveForegroundColor: t.inkTertiary,
          ),
        ),
        PersistentTabConfig(
          screen: const ClientWorkoutsScreen(),
          item: ItemConfig(
            title: l10n.navWorkouts,
            textStyle: labelStyle,
            icon: PhosphorIcon(PhosphorIcons.barbell(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.barbell()),
            activeForegroundColor: t.goldDeep,
            inactiveForegroundColor: t.inkTertiary,
          ),
        ),
        PersistentTabConfig(
          screen: ClientProgressScreen(),
          item: ItemConfig(
            title: l10n.navProgress,
            textStyle: labelStyle,
            icon: PhosphorIcon(PhosphorIcons.trendUp(PhosphorIconsStyle.bold)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.trendUp()),
            activeForegroundColor: t.goldDeep,
            inactiveForegroundColor: t.inkTertiary,
          ),
        ),
        PersistentTabConfig(
          screen: ClientSettingsScreen(),
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
