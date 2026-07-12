/// [VHeader] — the in-body editorial header (design.md §2). No AppBar: a big
/// `title1` (or `serifDisplay` for greeting screens), optional subhead, a
/// leading VIconCircle back on pushed screens, and trailing VIconCircle actions.
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'v_buttons.dart';

class VHeader extends StatelessWidget {
  const VHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.serif = false,
    this.onBack,
    this.actions,
    this.backSemanticLabel = 'Back',
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? subtitle;

  /// Use the serif "Voice" for greeting screens.
  final bool serif;

  /// Shows a leading back chip when non-null.
  final VoidCallback? onBack;
  final String backSemanticLabel;

  /// Trailing VIconCircle(s) etc.
  final List<Widget>? actions;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasTopRow = onBack != null || (actions?.isNotEmpty ?? false);

    Widget titleText = Text(
      title,
      style: (serif ? VType.serifDisplay : VType.title1).copyWith(color: t.ink),
    );
    if (serif) titleText = VTextScaleCap(child: titleText);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTopRow) ...[
            Row(
              children: [
                if (onBack != null)
                  VIconCircle(
                    icon: PhosphorIconsBold.caretLeft,
                    onTap: onBack,
                    semanticLabel: backSemanticLabel,
                  ),
                const Spacer(),
                for (var i = 0; i < (actions?.length ?? 0); i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions![i],
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          titleText,
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: VType.subhead.copyWith(color: t.inkSecondary)),
          ],
        ],
      ),
    );
  }
}
