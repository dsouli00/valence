/// [VOptionCard] — the selectable card for quiz answers and role picks
/// (design.md §2): min-h64 r18 `surface` card, leading 38px tinted icon circle,
/// `headline` label (+ optional subtitle). Selected = gold 1.5 ring + gold @ 8%
/// wash — the ONLY selected signal (no checkmark, no radio).
///
/// Auto-advance for single-selects is the screen's job, not this component's.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
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
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(16),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: t.tintFill(tintColor),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: t.legibleTint(tintColor)),
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
