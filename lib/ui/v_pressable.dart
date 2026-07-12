/// [VPressable] — the shared tap primitive. Everything tappable in the app
/// (design.md §1.5) gets the same feel: scale 0.98 over 120ms + an optional
/// ink @ 4% overlay, Reduce-Motion aware, with a ≥44pt hit area (§1.10).
///
/// Use the [builder] form when the child needs to react to the pressed state
/// (e.g. a filled button darkening); otherwise pass a static [child].
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VPressable extends StatefulWidget {
  const VPressable({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.scale = VMotion.pressedScale,
    this.overlay = false,
    this.overlayRadius,
    this.enableFeedback = true,
    this.semanticButton = true,
  }) : assert(child != null || builder != null,
            'VPressable needs a child or a builder');

  final Widget? child;

  /// Receives the live pressed state — for children that restyle on press.
  final Widget Function(BuildContext context, bool pressed)? builder;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Pressed scale target. 1.0 disables the scale.
  final double scale;

  /// Paint an ink @ 4% overlay while pressed (rows, cards). Clipped to
  /// [overlayRadius].
  final bool overlay;
  final BorderRadius? overlayRadius;

  /// When false the widget is inert (disabled/loading) — no scale, no taps.
  final bool enableFeedback;

  /// Expose a button role to screen readers.
  final bool semanticButton;

  @override
  State<VPressable> createState() => _VPressableState();
}

class _VPressableState extends State<VPressable> {
  bool _pressed = false;

  bool get _interactive =>
      widget.enableFeedback &&
      (widget.onTap != null || widget.onLongPress != null);

  void _set(bool value) {
    if (!_interactive) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget content = widget.builder?.call(context, _pressed) ?? widget.child!;

    if (widget.overlay) {
      content = Stack(
        children: [
          content,
          if (_pressed)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.pressedOverlay,
                    borderRadius: widget.overlayRadius,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    final scaled = AnimatedScale(
      scale: (_pressed && _interactive && widget.scale != 1.0) ? widget.scale : 1.0,
      duration: reduceMotion ? Duration.zero : VDuration.micro,
      curve: VMotion.curve,
      child: content,
    );

    return Semantics(
      button: widget.semanticButton && _interactive,
      enabled: _interactive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: scaled,
      ),
    );
  }
}
