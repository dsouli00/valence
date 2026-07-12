/// [VRow] — the list row (design.md §2): optional leading (VAvatar), title
/// `headline`, optional subline `subhead inkSecondary`, optional quiet third
/// line (e.g. VQuietStats), and a trailing slot (VStatusPill / chevron /
/// VMiniPill / VTextAction). Pressed tint via [VPressable]; long-press opens a
/// context sheet. Min height 64, vertical padding 14.
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'v_pressable.dart';

class VRow extends StatelessWidget {
  const VRow({
    super.key,
    required this.title,
    this.leading,
    this.subline,
    this.sublineColor,
    this.third,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final Widget? leading;

  /// Secondary line — `inkSecondary` unless [sublineColor] demands otherwise
  /// (colored only when the bucket requires it).
  final String? subline;
  final Color? sublineColor;

  /// A quiet third line, typically a [VQuietStats].
  final Widget? third;

  /// Trailing content. Ignored when [chevron] is true and this is null.
  final Widget? trailing;

  /// Show a trailing chevron when there's no explicit [trailing].
  final bool chevron;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget? trailingWidget = trailing;
    trailingWidget ??= chevron
        ? Icon(PhosphorIconsBold.caretRight, size: 14, color: t.inkTertiary)
        : null;

    return VPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      overlay: true,
      overlayRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VSpace.rowMinHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, VSpace.rowVPad, 8, VSpace.rowVPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VType.headline.copyWith(color: t.ink),
                    ),
                    if (subline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subline!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VType.subhead
                            .copyWith(color: sublineColor ?? t.inkSecondary),
                      ),
                    ],
                    if (third != null) ...[
                      const SizedBox(height: 6),
                      third!,
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
