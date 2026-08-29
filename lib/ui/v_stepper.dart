/// [VStepper] — a big live number flanked by round − / + buttons (design.md
/// §5.6: round `surfaceSubtle` 44pt steppers). The fine-adjust counterpart to
/// [VRulerDial]: used where the range is tight (age) or a small delta (goal
/// weight); the ruler stays for wide scans (height, current weight).
///
/// Press-and-hold a button to repeat. Uncontrolled after mount ([value] is an
/// initial only) — re-key to reset, mirroring the dial.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class VStepper extends StatefulWidget {
  const VStepper({
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
  final double value;
  final ValueChanged<double> onChanged;
  final String unit;
  final int decimals;
  final String Function(double)? displayFormatter;

  @override
  State<VStepper> createState() => _VStepperState();
}

class _VStepperState extends State<VStepper> {
  late double _value = _snap(widget.value);

  double _snap(double v) {
    final clamped = v.clamp(widget.min, widget.max);
    final stepped = (clamped / widget.step).round() * widget.step;
    return stepped.clamp(widget.min, widget.max).toDouble();
  }


  // The value handed in may be out of range or off-step, and _value above is
  // SNAPPED at construction. If that snap moved it, the parent is now holding a
  // different number than the one on screen — so tell it, once, after mount.
  //
  // Without this the client intake could save a goal weight of 68 kg while the
  // control read 160: _targetController seeds at '68', the range is derived
  // from current weight (+/-40 kg), and a client who weighs 200 kg never
  // touches the stepper. The dial clamped its own display and said nothing.
  @override
  void initState() {
    super.initState();
    if (_value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_value);
      });
    }
  }

  void _bump(int dir) {
    final next = _snap(_value + dir * widget.step);
    if (next == _value) return; // at a bound
    HapticFeedback.selectionClick();
    setState(() => _value = next);
    widget.onChanged(_value);
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          value: '${_readout(_value)} ${widget.unit}'.trim(),
          child: VTextScaleCap(
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
        ),
        const SizedBox(height: 24),
        // Buttons sit directly under the number — a reachable, grouped cluster.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepButton(
              icon: PhosphorIconsBold.minus,
              enabled: _value > widget.min,
              onStep: () => _bump(-1),
            ),
            const SizedBox(width: 24),
            _StepButton(
              icon: PhosphorIconsBold.plus,
              enabled: _value < widget.max,
              onStep: () => _bump(1),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({required this.icon, required this.enabled, required this.onStep});

  final IconData icon;
  final bool enabled;
  final VoidCallback onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _delay;
  Timer? _repeat;
  bool _down = false;

  void _start() {
    if (!widget.enabled) return;
    setState(() => _down = true);
    widget.onStep();
    _delay = Timer(const Duration(milliseconds: 350), () {
      _repeat = Timer.periodic(const Duration(milliseconds: 70), (_) {
        if (widget.enabled) {
          widget.onStep();
        } else {
          _stop();
        }
      });
    });
  }

  void _stop() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
    if (mounted && _down) setState(() => _down = false);
  }

  @override
  void dispose() {
    _delay?.cancel();
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: Listener(
        onPointerDown: widget.enabled ? (_) => _start() : null,
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: VDuration.micro,
          curve: VMotion.curve,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: t.surfaceSubtle, shape: BoxShape.circle),
            child: Icon(widget.icon,
                size: 22, color: widget.enabled ? t.ink : t.inkTertiary),
          ),
        ),
      ),
    );
  }
}
