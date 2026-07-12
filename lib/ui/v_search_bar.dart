/// [VSearchBar] — h48 rounded `surface` field with the card shadow, magnifier
/// leading, clear-on-text trailing, gold focus ring (design.md §2).
///
/// The screen owns the [controller]; this widget only owns its [FocusNode].
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VSearchBar extends StatefulWidget {
  const VSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<VSearchBar> createState() => _VSearchBarState();
}

class _VSearchBarState extends State<VSearchBar> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool get _ownsFocus => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onChange);
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onChange);
    widget.controller.removeListener(_onChange);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasText = widget.controller.text.isNotEmpty;
    final focused = _focus.hasFocus;

    return Container(
      height: 48,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: t.cardShadow,
        border: Border.all(
          color: focused ? t.gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: t.inkTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              cursorColor: t.gold,
              style: VType.body.copyWith(color: t.ink),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: widget.hint,
                hintStyle: VType.body.copyWith(color: t.inkTertiary),
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.controller.clear();
                widget.onChanged?.call('');
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Icon(PhosphorIconsBold.x, size: 16, color: t.inkTertiary),
              ),
            ),
        ],
      ),
    );
  }
}
