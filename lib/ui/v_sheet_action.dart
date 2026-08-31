/// One row in an action sheet — icon in a tinted circle, then a label.
///
/// This exists because there were two of them. The client's meal-actions sheet
/// used a 40px tinted circle with a `headline` label; the coach's client-actions
/// sheet used a bare 20px glyph with a `body` label. Same component role, two
/// treatments, in a design system whose whole premise is that there is one way
/// to do each thing (design.md §3: compose the shared primitives, never
/// copy-paste styling into screens).
///
/// The tinted-circle version wins because it is what the settings rows already
/// do (§4-F), so the app has one vocabulary for "an icon that labels an action"
/// rather than two.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'v_pressable.dart';

class VSheetAction extends StatelessWidget {
  const VSheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Red glyph, red tint, red label. Only for actions that actually destroy —
  /// see the note on `SettingsLogoutButton` about spending that colour.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tint = destructive ? t.alert : t.gold;
    return VPressable(
      onTap: onTap,
      overlay: true,
      overlayRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.tintFill(tint),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: t.legibleTint(tint)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VType.headline
                    .copyWith(color: destructive ? t.alert : t.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
