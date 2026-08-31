/// [VSheet] + [showVSheet] — the bottom-sheet system (design.md §2). r28 top on
/// `canvas`, a 36×4 grabber, optional title, optional pinned CTA. ALL confirms,
/// editors and pickers are sheets — `AlertDialog` is retired app-wide.
///
/// Sheets are keyboard-safe by construction: the content scrolls, and both it
/// and the pinned CTA rise above the keyboard via `viewInsets` (design.md §2 —
/// the b727bbb overflow lesson encoded as law). Sheets with their own text
/// fields must own their controllers (dispose in their State).
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Presents [builder] as a Valence sheet. Scroll-controlled by default so tall
/// / keyboard-driven content behaves.
Future<T?> showVSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // ROOT navigator. Sheets were presented on the TAB's local navigator
    // (persistent_bottom_nav_bar_v2 gives each tab its own), so the persistent
    // tab bar stayed lit ABOVE the scrim and fully tappable while a modal was
    // open — you could switch tabs mid-sheet, out from under a confirmation.
    // Seen on the note sheet, the meal-actions sheet, the edit sheet and the
    // log-out confirm.
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: context.tokens.scrim,
    builder: builder,
  );
}

class VSheet extends StatelessWidget {
  const VSheet({
    super.key,
    required this.child,
    this.title,
    this.pinnedAction,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: VSpace.screenMargin),
  });

  final Widget child;
  final String? title;

  /// Pinned CTA above the safe area / keyboard.
  final Widget? pinnedAction;

  /// Wrap [child] in a scroll view (default). Disable for content that manages
  /// its own scrolling.
  final bool scrollable;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.92;

    final content = Padding(padding: padding, child: child);

    return Padding(
      // Lift the whole sheet above the keyboard.
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: t.canvas,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.sheetTop),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grabber.
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.inkTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        VSpace.screenMargin, 4, VSpace.screenMargin, 10),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(title!, style: VType.headline.copyWith(color: t.ink)),
                    ),
                  ),
                Flexible(
                  child: scrollable
                      ? _ScrollFade(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: content,
                          ),
                        )
                      : content,
                ),
                if (pinnedAction != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        VSpace.screenMargin, 8, VSpace.screenMargin, 16),
                    child: pinnedAction,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades the bottom edge of a sheet's scroll area so content that continues
/// past the fold says so.
///
/// Three separate findings were the same shape: a sheet looks complete, the
/// pinned CTA sits right there, and the rest of the form is below the fold with
/// nothing suggesting a scroll. The Update Workout sheet cut off at two
/// exercises; the Assign sheet hid its duration stepper; the coach-note editor
/// pushed Save out of sight while typing. The layout was never wrong — the
/// pinned action sits BELOW the scroll area, it does not overlay it — what was
/// missing was any signal that there is more.
///
/// A ShaderMask only affects pixels that exist, so a short sheet is unchanged:
/// the fade appears exactly when there is something to fade.
///
/// Not a decorative gradient (design.md §6.6 retires gradient CARD FILLS) — it
/// is a scroll affordance on an edge, and the alternative in the system's
/// vocabulary, a hairline, is reserved for other jobs by §1.5.
class _ScrollFade extends StatelessWidget {
  const _ScrollFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0.0, 0.92, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
