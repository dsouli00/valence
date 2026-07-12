/// [VStatusPill] — h24 status chip: status @ 12% fill, a 6px solid dot + the
/// word in the status color (design.md §2). The `alert` dot breathes — the
/// app's single looping animation (§1.7-④); everything else is static.
///
/// "Setup" is NOT a pill — render a `VTextAction("Setup →")` instead.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

enum VStatusVariant { good, watch, alert, brandNew }

class VStatusPill extends StatelessWidget {
  const VStatusPill({
    super.key,
    required this.variant,
    required this.label,
    this.breathing = false,
  });

  final VStatusVariant variant;
  final String label;

  /// Breathe the dot — only meaningful (and only allowed) for at-risk alerts.
  final bool breathing;

  Color _color(ValenceTokens t) {
    switch (variant) {
      case VStatusVariant.good:
        return t.good;
      case VStatusVariant.watch:
        return t.watch;
      case VStatusVariant.alert:
        return t.alert;
      case VStatusVariant.brandNew:
        return t.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = _color(t);
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: c, breathing: breathing),
          const SizedBox(width: 5),
          Text(
            label,
            style: VType.caption.copyWith(color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.breathing});
  final Color color;
  final bool breathing;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final shouldRun = widget.breathing && !reduceMotion;
    if (shouldRun && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: VDuration.breathing,
      )..repeat(reverse: true);
    } else if (!shouldRun && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = SizedBox(width: 6, height: 6);
    final base = DecoratedBox(
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      child: dot,
    );
    if (_controller == null) return base;
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      ),
      child: base,
    );
  }
}
