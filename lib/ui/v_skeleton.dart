/// [VSkeleton] — a shimmer block for loading states (design.md §2). Base
/// `surfaceSubtle`, a 1400ms sweep. Compose several to mirror the real layout.
/// Static (no sweep) under Reduce Motion.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VSkeleton extends StatefulWidget {
  const VSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<VSkeleton> createState() => _VSkeletonState();
}

class _VSkeletonState extends State<VSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: VDuration.shimmer,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final radius = BorderRadius.circular(widget.radius);

    // Start/stop the loop in response to Reduce Motion changes.
    if (reduceMotion) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: t.surfaceSubtle, borderRadius: radius),
      );
    }

    final highlight = Color.alphaBlend(
      t.onInk.withValues(alpha: t.isLight ? 0.35 : 0.06),
      t.surfaceSubtle,
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [t.surfaceSubtle, highlight, t.surfaceSubtle],
              stops: const [0.35, 0.5, 0.65],
              transform: _SweepTransform(_c.value * 2 - 1),
            ),
          ),
        );
      },
    );
  }
}

/// Slides the shimmer gradient across the block from -1 → +1 of its width.
class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.slide);
  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slide, 0, 0);
  }
}
