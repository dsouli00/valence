import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/pages/coach/coach_workout_library_screen.dart';
import 'package:valence/pages/coach/clients_screen.dart';
import 'package:valence/pages/coach/coach_settings_screen.dart';


class CoachPersistantTabs extends StatelessWidget {
  const CoachPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
          screen: ClientsScreen(),
          item: ItemConfig(
            title: "Clients",
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.usersThree()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: const CoachWorkoutLibraryScreen(),
          item: ItemConfig(
            title: "Library",
            textStyle: TextStyle(fontFamily: "Inter"),
            icon: PhosphorIcon(PhosphorIcons.clipboardText(PhosphorIconsStyle.fill)),
            inactiveIcon: PhosphorIcon(PhosphorIcons.clipboardText()),
            activeForegroundColor: colorScheme.secondary,
            inactiveForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: CoachSettingsScreen(),
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
