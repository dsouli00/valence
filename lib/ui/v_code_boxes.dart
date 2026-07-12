/// [VCodeBoxes] — the invite-code entry ceremony (design.md §2 / §5.4): a row of
/// boxes (7 by default), each `surface` + `hairline`, the active box wearing a
/// gold ring; 20 w800 tabular chars; auto-advance, paste, and a gold flash on
/// completion.
///
/// A single hidden field is the source of truth (native paste + keyboard), and
/// the boxes are a painted overlay. The screen owns the [controller].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VCodeBoxes extends StatefulWidget {
  const VCodeBoxes({
    super.key,
    required this.controller,
    this.length = 7,
    this.onChanged,
    this.onCompleted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onChanged;

  /// Fires once when the last box is filled (e.g. to auto-submit).
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<VCodeBoxes> createState() => _VCodeBoxesState();
}

class _VCodeBoxesState extends State<VCodeBoxes>
    with SingleTickerProviderStateMixin {
  final FocusNode _focus = FocusNode();
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: VDuration.standard,
  );
  bool _wasComplete = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _focus.addListener(_redraw);
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  void _onChange() {
    final text = widget.controller.text;
    widget.onChanged?.call(text);
    final complete = text.length == widget.length;
    if (complete && !_wasComplete) {
      HapticFeedback.mediumImpact();
      _flash.forward(from: 0);
      widget.onCompleted?.call(text);
    }
    _wasComplete = complete;
    _redraw();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _focus.removeListener(_redraw);
    _focus.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = widget.controller.text;
    final complete = text.length == widget.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _flash,
            builder: (context, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _box(t, i, text, complete),
                  ],
                ],
              ),
            ),
          ),
          // The real input — invisible, on top, catching taps + keyboard.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                showCursor: false,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(widget.length),
                  const _UpperCaseFormatter(),
                  FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                ],
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(ValenceTokens t, int i, String text, bool complete) {
    final filled = i < text.length;
    final active = _focus.hasFocus && i == text.length && !complete;
    // Completion flash: gold @ 12% that fades out over the animation.
    final flashAlpha = complete ? 0.12 * (1 - _flash.value) : 0.0;
    final ring = (active || complete) ? t.gold : t.hairline;
    return Container(
      width: 40,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(t.gold.withValues(alpha: flashAlpha), t.surface),
        borderRadius: BorderRadius.circular(VRadius.codeBox),
        border: Border.all(color: ring, width: (active || complete) ? 1.5 : 1),
      ),
      child: Text(
        filled ? text[i] : '',
        style: VType.stat(20).copyWith(color: t.ink),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
