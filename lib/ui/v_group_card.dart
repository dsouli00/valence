/// [VGroupCard] — the grouped-list container (design.md §2): `surface` r24 with
/// the one card shadow, hairline separators inset to the text start. Optional
/// [VListHeader] row: `title2` + count + a trailing action (VMiniPill/VTextAction).
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VGroupCard extends StatelessWidget {
  const VGroupCard({
    super.key,
    required this.children,
    this.header,
    this.dividers = true,
    this.dividerInset = VSpace.separatorInset,
  });

  /// The rows (usually [VRow]s). Separators are woven between them here.
  final List<Widget> children;

  /// Optional header row pinned above the rows, under its own separator.
  final VListHeader? header;

  /// Weave hairline separators between rows.
  final bool dividers;

  /// Start-inset of separators, to the row's text (design.md §1.3 ≈ 64).
  final double dividerInset;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final items = <Widget>[];
    if (header != null) {
      items.add(header!);
      if (children.isNotEmpty) items.add(_divider(t, 0));
    }
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (dividers && i < children.length - 1) {
        items.add(_divider(t, dividerInset));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      // px8/py6 — the card breathes without a visible border.
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );
  }

  Widget _divider(ValenceTokens t, double inset) => Padding(
        padding: EdgeInsetsDirectional.only(start: inset),
        child: Divider(height: 1, thickness: 1, color: t.hairline),
      );
}

/// The header row inside a [VGroupCard]: big title-case head, optional count,
/// optional trailing action.
class VListHeader extends StatelessWidget {
  const VListHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
  });

  final String title;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 8, 10),
      child: Row(
        children: [
          // Title AND count inside ONE Expanded, with no Spacer after them.
          //
          // A bare `Text` took its full intrinsic width before the Spacer got a
          // say, so a long title pushed `trailing` off the right edge: German's
          // "Tägliche Gewohnheiten" overflowed by 126px and took the manage
          // button with it — a FEATURE a German-speaking coach could not reach.
          //
          // But making the title merely `Flexible` was not enough either: a
          // Spacer is `Expanded(flex: 1)`, so it and the title split the free
          // space 50/50 and the heading was capped at half the row however
          // short the action was — "Gewoh…" beside an easily-fitting button.
          // Expanding the pair and deleting the Spacer gives the text every
          // pixel the action does not need, and looks identical when it fits.
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.title2.copyWith(color: t.ink),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: VType.stat(17).copyWith(color: t.inkSecondary),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
