/// [showVToast] — the floating confirmation capsule (design.md §2). `ink` @ 92%
/// fill, `onInk` 13 w600, fully rounded, fades + rises 240ms, lingers 2.4s.
/// Replaces stock SnackBar visuals app-wide.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Shows a toast above the tab bar — or above the keyboard, when one is up.
/// Non-blocking; auto-dismisses.
///
/// The lift used to be `viewPadding.bottom + 72`, which ignores the keyboard
/// entirely. Every toast raised while someone was typing rendered UNDERNEATH
/// it and was never seen — so each form's validation error was silent at
/// exactly the moment it was needed, and the primary button looked dead. Caught
/// on the manual meal entry: tapping "Log Meal" with a macro left blank did
/// nothing visible, and the same tap with the keyboard dismissed showed
/// "Please fill in the meal name and all macros."
///
/// Measured inside the builder rather than at insert time, so a toast that
/// outlives the keyboard settles back down with it instead of hanging in space.
void showVToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final mq = MediaQuery.of(context);
      final keyboard = mq.viewInsets.bottom;
      final safeArea = mq.viewPadding.bottom;
      return Positioned(
        left: 0,
        right: 0,
        bottom: (keyboard > safeArea ? keyboard : safeArea) + 72,
        child: _VToastCard(message: message, onDismissed: () => entry.remove()),
      );
    },
  );
  overlay.insert(entry);
}

class _VToastCard extends StatefulWidget {
  const _VToastCard({required this.message, required this.onDismissed});
  final String message;
  final VoidCallback onDismissed;

  @override
  State<_VToastCard> createState() => _VToastCardState();
}

class _VToastCardState extends State<_VToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: VDuration.standard,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 2400), () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    // Material(transparency) is load-bearing, not decoration. This card lives in
    // the Navigator's Overlay, which has NO Material ancestor — and without one
    // Flutter falls back to its debug text style (double YELLOW underline).
    // `Text.style` MERGES with the default rather than replacing it, so our
    // explicit style could never clear that decoration. Every toast in the app
    // was drawing the underline until this wrapper was added.
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final v = _c.value;
              return Opacity(
                opacity: reduceMotion ? (v > 0 ? 1 : 0) : v,
                child: Transform.translate(
                  offset: Offset(0, reduceMotion ? 0 : (1 - v) * 8),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: t.ink.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: VType.subhead.copyWith(
                  color: t.onInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
