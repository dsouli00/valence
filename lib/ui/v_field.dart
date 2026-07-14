/// [VField] — the text field (design.md §2): h52 r14 `surfaceSubtle` fill, no
/// border, gold 1.5 focus ring, `alert` ring + caption on error. Optional label
/// above (or inline-left for auth). The screen owns the [controller]; this
/// widget owns its [FocusNode].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VField extends StatefulWidget {
  const VField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.enabled = true,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  @override
  State<VField> createState() => _VFieldState();
}

class _VFieldState extends State<VField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool get _ownsFocus => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasError = widget.errorText != null;
    final focused = _focus.hasFocus;
    final ringColor = hasError
        ? t.alert
        : focused
            ? t.gold
            : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: VType.caption.copyWith(color: t.inkSecondary)),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: VDuration.micro,
          curve: VMotion.curve,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.enabled ? t.surfaceSubtle : t.surfaceSubtle.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(VRadius.input),
            border: Border.all(color: ringColor, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  cursorColor: t.gold,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: VType.body.copyWith(color: t.ink),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    hintText: widget.hint,
                    hintStyle: VType.body.copyWith(color: t.inkTertiary),
                  ),
                ),
              ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 10),
                widget.suffix!,
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(widget.errorText!, style: VType.caption.copyWith(color: t.alert)),
        ],
      ],
    );
  }
}
