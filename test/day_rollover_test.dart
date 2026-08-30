// Widget tests for the midnight rollover.
//
// The bug: both daily screens read `DateTime.now()` once, in a field
// initializer, and never asked again. Left open across midnight, Today kept
// showing yesterday's water, sleep, weight and habit ticks — while the live
// `isViewingToday` checks flipped to false, so every control silently went
// read-only on data that was no longer today's.
//
// The one rule that is easy to get backwards, and the reason this file exists:
// rolling the day must NOT drag a client out of the past. Someone reading last
// Tuesday at 23:59 is still on last Tuesday at 00:01.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valence/utils/day_rollover.dart';

class _Host extends StatefulWidget {
  final DateTime initialSelected;
  const _Host({required this.initialSelected});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host>
    with WidgetsBindingObserver, DayRolloverMixin {
  late DateTime selected = widget.initialSelected;
  int rolls = 0;
  bool? lastWasViewingToday;

  @override
  void initState() {
    super.initState();
    startDayRollover();
  }

  @override
  void dispose() {
    stopDayRollover();
    super.dispose();
  }

  @override
  bool get isViewingToday => selected == today;

  @override
  void onDayRolled({required bool wasViewingToday}) {
    rolls++;
    lastWasViewingToday = wasViewingToday;
    if (wasViewingToday) setState(() => selected = today);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  final monday = DateTime(2026, 8, 30);
  final tuesday = DateTime(2026, 8, 31);

  setUp(() => dayRolloverClock = () => monday.add(const Duration(hours: 23)));
  tearDown(() => dayRolloverClock = DateTime.now);

  Future<_HostState> pump(WidgetTester tester, DateTime selected) async {
    await tester.pumpWidget(MaterialApp(home: _Host(initialSelected: selected)));
    return tester.state<_HostState>(find.byType(_Host));
  }

  testWidgets('starts on the clock day', (tester) async {
    final s = await pump(tester, monday);
    expect(s.today, monday);
    expect(s.isViewingToday, isTrue);
  });

  testWidgets('RULE: a client sitting on today follows the clock over midnight',
      (tester) async {
    final s = await pump(tester, monday);
    dayRolloverClock = () => tuesday.add(const Duration(minutes: 6));
    s.checkDayRollover();
    await tester.pump();

    expect(s.today, tuesday, reason: 'the day must advance');
    expect(s.lastWasViewingToday, isTrue);
    expect(s.selected, tuesday, reason: 'and the screen must follow it');
    expect(s.isViewingToday, isTrue,
        reason: 'controls must stay live, not silently go read-only');
  });

  testWidgets('RULE: a client reading an older day is NOT dragged forward',
      (tester) async {
    final lastTuesday = DateTime(2026, 8, 25);
    final s = await pump(tester, lastTuesday);
    expect(s.isViewingToday, isFalse);

    dayRolloverClock = () => tuesday.add(const Duration(minutes: 6));
    s.checkDayRollover();
    await tester.pump();

    expect(s.today, tuesday, reason: 'the clock still moved');
    expect(s.lastWasViewingToday, isFalse);
    expect(s.selected, lastTuesday, reason: 'but the reader stays put');
  });

  testWidgets('does nothing when the day has not changed', (tester) async {
    final s = await pump(tester, monday);
    dayRolloverClock = () => monday.add(const Duration(hours: 23, minutes: 59));
    s.checkDayRollover();
    await tester.pump();

    expect(s.rolls, 0);
    expect(s.today, monday);
  });

  testWidgets('resuming from background catches a day the timer slept through',
      (tester) async {
    final s = await pump(tester, monday);
    dayRolloverClock = () => tuesday.add(const Duration(hours: 9));

    // The phone was asleep; the Timer never fired. Resume is the safety net.
    s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();

    expect(s.today, tuesday);
    expect(s.rolls, 1);
  });

  testWidgets('the midnight timer fires on its own with the app left open',
      (tester) async {
    final almostMidnight = DateTime(2026, 8, 30, 23, 59, 50);
    dayRolloverClock = () => almostMidnight;
    final s = await pump(tester, monday);
    expect(s.rolls, 0);

    // 11 seconds of wall clock crosses midnight; the scheduled timer wakes up
    // and finds a new day without anybody touching the screen.
    dayRolloverClock = () => DateTime(2026, 8, 31, 0, 0, 1);
    await tester.pump(const Duration(seconds: 12));

    expect(s.today, tuesday);
    expect(s.rolls, 1);
    expect(s.selected, tuesday);
  });
}
