import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/pages/client/client_home_screen.dart';
import 'package:valence/pages/client/client_progress_screen.dart';
import 'package:valence/pages/client/client_settings_screen.dart';
import 'package:valence/pages/client/client_workouts_screen.dart';


class ClientPersistantTabs extends StatelessWidget {
  const ClientPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
          screen: ClientHomeScreen(),
          item: ItemConfig(
            title: l10n.navToday,
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.calendarBlank()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: const ClientWorkoutsScreen(),
          item: ItemConfig(
            title: l10n.navWorkouts,
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.barbell(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.barbell()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: ClientProgressScreen(),
          item: ItemConfig(
            title: l10n.navProgress,
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.trendUp(PhosphorIconsStyle.bold)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.trendUp()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: ClientSettingsScreen(),
          item: ItemConfig(
            title: l10n.navProfile,
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.user()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => Style6BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(25),
              blurRadius: 8,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(125),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
