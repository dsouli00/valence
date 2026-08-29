/// [VRulerDial] — THE numeric input (design.md §2 / §5.3): a big live number
/// over a horizontal tick ruler with a fixed gold centre indicator. Drag to
/// change; `selectionClick` per tick; snaps to the nearest tick on release.
///
/// One crafted dial, zero novelty variants (coherence > novelty). The unit
/// VSegmented lives ABOVE it, placed by the screen — switching units rebuilds
/// the dial (new key) with the converted range, so [value] is an INITIAL only.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VRulerDial extends StatefulWidget {
  const VRulerDial({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    this.unit = '',
    this.decimals = 0,
    this.displayFormatter,
  });

  final double min;
  final double max;
  final double step;

  /// Initial value (the dial is uncontrolled after mount — re-key to reset).
  final double value;
  final ValueChanged<double> onChanged;

  final String unit;
  final int decimals;

  /// Override the readout (e.g. ft/in). When set, [unit] is hidden.
  final String Function(double)? displayFormatter;

  @override
  State<VRulerDial> createState() => _VRulerDialState();
}

class _VRulerDialState extends State<VRulerDial> {
  static const double _tick = 10;
  static const double _rulerHeight = 76;

  late final int _count = ((widget.max - widget.min) / widget.step).round() + 1;
  late double _value = _snap(widget.value);
  late final ScrollController _scroll =
      ScrollController(initialScrollOffset: _indexOf(_value) * _tick);
  bool _settling = false;

  double _snap(double v) {
    final clamped = v.clamp(widget.min, widget.max);
    final stepped = (clamped / widget.step).round() * widget.step;
    return stepped.clamp(widget.min, widget.max).toDouble();
  }

  int _indexOf(double v) =>
      ((v - widget.min) / widget.step).round().clamp(0, _count - 1);

  double _valueOf(int i) =>
      (widget.min + i * widget.step).clamp(widget.min, widget.max).toDouble();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Same contract as VStepper: if snapping moved the incoming value, the
    // parent is holding a different number than the one rendered. Say so once.
    if (_value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_value);
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final i = (_scroll.offset / _tick).round().clamp(0, _count - 1);
    final v = _valueOf(i);
    if (v != _value) {
      setState(() => _value = v);
      HapticFeedback.selectionClick();
      widget.onChanged(v);
    }
  }

  void _snapToNearest() {
    if (_settling || !_scroll.hasClients) return;
    final i = (_scroll.offset / _tick).round().clamp(0, _count - 1);
    final target = i * _tick;
    if ((_scroll.offset - target).abs() < 0.5) return;
    _settling = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _scroll
        .animateTo(
          target,
          duration: reduceMotion ? Duration.zero : VDuration.micro,
          curve: VMotion.curve,
        )
        .whenComplete(() => _settling = false);
  }

  String _readout(double v) {
    if (widget.displayFormatter != null) return widget.displayFormatter!(v);
    if (widget.decimals == 0 || v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(widget.decimals);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final showUnit = widget.displayFormatter == null && widget.unit.isNotEmpty;

    return Column(
      children: [
        // Live readout.
        VTextScaleCap(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_readout(_value), style: VType.display.copyWith(color: t.ink)),
              if (showUnit) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(widget.unit,
                      style: VType.title2.copyWith(color: t.goldDeep)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Ruler.
        SizedBox(
          height: _rulerHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final pad = (constraints.maxWidth - _tick) / 2;
                  return NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _snapToNearest());
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemExtent: _tick,
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemCount: _count,
                      itemBuilder: (context, i) => _tickMark(t, i),
                    ),
                  );
                },
              ),
              // Fixed gold centre indicator.
              IgnorePointer(
                child: Container(
                  width: 3,
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tickMark(ValenceTokens t, int i) {
    final major = i % 5 == 0;
    // Ticks near the centre warm toward gold — a soft focus so the ruler reads
    // alive, not like a dead grey comb.
    final dist = (i - _indexOf(_value)).abs();
    final color = dist <= 2
        ? Color.lerp(t.gold, t.inkTertiary, dist / 3)!
        : (major ? t.inkSecondary : t.inkTertiary);
    return Center(
      child: Container(
        width: 2,
        height: major ? 26 : 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
