import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';


class CoachPersistantTabs extends StatelessWidget {
  const CoachPersistantTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
          screen: Placeholder(),
          item: ItemConfig(
            title: "Roster",
            textStyle: TextStyle(
                fontFamily: "Inter"
            ),
            inactiveIcon: Icon(Icons.people_alt_outlined),
            icon: Icon(Icons.people_alt),
            activeForegroundColor: activeColor,
            inactiveForegroundColor: inactiveColor,
          ),
        ),
        PersistentTabConfig(
          screen: Placeholder(),
          item: ItemConfig(
            title: "Library",
            textStyle: TextStyle(
                fontFamily: "Inter"
            ),
            inactiveIcon: Icon(Icons.local_library_outlined),
            icon: Icon(Icons.local_library_rounded),
            activeForegroundColor: activeColor,
            inactiveForegroundColor: inactiveColor,
          ),
        ),
        PersistentTabConfig(
          screen: Placeholder(),
          item: ItemConfig(
            title: "Settings",
            inactiveIcon: Icon(Icons.settings_outlined),
            icon: Icon(Icons.settings),
            textStyle: TextStyle(
                fontFamily: "Inter"
            ),
            activeForegroundColor: activeColor,
            inactiveForegroundColor: inactiveColor,
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