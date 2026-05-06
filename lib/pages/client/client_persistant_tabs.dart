import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/pages/client/client_home_screen.dart';
import 'package:valence/pages/client/client_settings_screen.dart';


class ClientPersistantTabs extends StatelessWidget {
  const ClientPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
          screen: ClientHomeScreen(),
          item: ItemConfig(
            title: "Today",
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.calendarBlank()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: Placeholder(),
          item: ItemConfig(
            title: "Workouts",
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.barbell(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.barbell()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: Placeholder(),
          item: ItemConfig(
            title: "Progress",
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
            title: "Profile",
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