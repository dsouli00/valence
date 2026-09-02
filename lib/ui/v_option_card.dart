/// [VOptionCard] — the selectable card for quiz answers and role picks
/// (design.md §2): min-h64 r18 `surface` card, leading 38px tinted icon circle,
/// `headline` label (+ optional subtitle). Selected = gold 1.5 ring + gold @ 8%
/// wash — the ONLY selected signal (no checkmark, no radio).
///
/// Auto-advance for single-selects is the screen's job, not this component's.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'v_icon.dart';
import '../theme/typography.dart';
import 'v_pressable.dart';

class VOptionCard extends StatelessWidget {
  const VOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.tint,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Data-tint for the leading circle. Defaults to gold.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tintColor = tint ?? t.gold;

    return VPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VDuration.standard,
        curve: VMotion.curve,
        // A LIST ROW, not a card.
        //
        // These were 64dp-min blocks with 16dp padding and a 38dp circle,
        // separated by 12dp — so three options ate most of a screen and read as
        // three separate objects rather than one set of choices. On a tall
        // phone that left the step looking half-empty and unfinished.
        //
        // A list of options is a LIST: it starts under the question and stays
        // tight. That is the opposite of what a numeric step wants — a ruler or
        // a dial is a single focal object and earns being centred in space —
        // and the two step types now deliberately behave differently.
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(t.selectedWash, t.surface)
              : t.surface,
          borderRadius: BorderRadius.circular(VRadius.cardSmall),
          boxShadow: t.cardShadow,
          border: Border.all(
            color: selected ? t.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: t.tintFill(tintColor),
                shape: BoxShape.circle,
              ),
              child: VIcon(icon, size: 19, color: t.legibleTint(tintColor)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: VType.headline.copyWith(color: t.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: VType.subhead.copyWith(color: t.inkSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
