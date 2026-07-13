/// [VCallout] — the coach-note voice (design.md §2): a `surface` card with a 3px
/// gold r999 accent bar inside-left, a quiet `goldDeep` author tag, and the body
/// in italic `body`. No label, no glow, no border. Used for the client-home
/// coach note (§5.6) and the client-detail check-in (§5.12).
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VCallout extends StatelessWidget {
  const VCallout({
    super.key,
    required this.body,
    this.author,
  });

  /// The message. Rendered italic, in `ink` — this is the thing being said.
  final String body;

  /// Optional attribution tag above the body (e.g. the coach badge), quiet
  /// `goldDeep`.
  final String? author;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      padding: const EdgeInsets.all(VSpace.cardPadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The one signature detail: a slim gold accent bar, inside-left.
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: t.gold,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (author != null) ...[
                    Text(
                      author!,
                      style: VType.caption.copyWith(
                        color: t.goldDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    body,
                    style: VType.body.copyWith(
                      color: t.ink,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
