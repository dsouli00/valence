/// [VProgressSegments] — the onboarding top-bar progress (design.md §2): h4
/// segments, r999; done + active are `gold`, the rest `surfaceSubtle`.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VProgressSegments extends StatelessWidget {
  const VProgressSegments({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;

  /// 0-based current segment; everything up to and including it is filled.
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: VDuration.standard,
              curve: VMotion.curve,
              height: 4,
              decoration: BoxDecoration(
                color: i <= index ? t.gold : t.surfaceSubtle,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
