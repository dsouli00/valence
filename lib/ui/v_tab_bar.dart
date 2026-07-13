/// [VTabBar] — the iOS-style bottom tab bar (design.md §2/§5.20): frosted
/// translucent `surface` (backdrop blur) over a top `hairline`, active tab =
/// Fill icon + label in goldDeep, inactive = inkTertiary. No Material
/// indicator, no bounce — switching tabs swaps color and weight, nothing more.
///
/// Built as a custom nav bar for `persistent_bottom_nav_bar_v2`: pass it to
/// `navBarBuilder` and set `navBarOverlap: NavBarOverlap.full()` on the
/// PersistentTabView so content scrolls under the glass.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VTabBar extends StatelessWidget {
  const VTabBar({required this.navBarConfig, super.key});

  final NavBarConfig navBarConfig;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Stack(
      children: [
        // Frosted glass under the bar — content scrolls beneath it.
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: t.isLight ? 0.82 : 0.88),
            border: Border(top: BorderSide(color: t.hairline)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  for (var i = 0; i < navBarConfig.items.length; i++)
                    Expanded(child: _tab(context, t, i)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tab(BuildContext context, ValenceTokens t, int index) {
    final item = navBarConfig.items[index];
    final active = navBarConfig.selectedIndex == index;
    final color = active ? t.goldDeep : t.inkTertiary;

    return Semantics(
      selected: active,
      button: true,
      label: item.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => navBarConfig.onItemSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(size: 23, color: color),
              child: active ? item.icon : item.inactiveIcon,
            ),
            if (item.title != null) ...[
              const SizedBox(height: 3),
              Text(
                item.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VType.caption.copyWith(
                  fontSize: 11,
                  height: 1.0,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
