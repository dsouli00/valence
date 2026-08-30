/// Keeps a day-scoped screen honest about what "today" is.
///
/// Both daily screens took `DateTime.now()` once, in a field initializer, and
/// never looked again. Left open across midnight the Today tab kept showing
/// yesterday — water, sleep, weight, habit ticks, all of it — while the live
/// `isViewingToday` checks flipped to false, so every control silently went
/// read-only on data that was no longer today's. The client sees a finished day
/// they cannot edit and nothing on screen explains why.
///
/// Two triggers, because neither alone is enough: a timer set for the next
/// midnight covers the app being left open (the case that actually happened),
/// and a check on resume covers the timer having been frozen while the app was
/// backgrounded.
///
/// The one rule worth stating: rolling the day must NOT yank a client out of
/// the past. Someone reading last Tuesday at 23:59 should still be on last
/// Tuesday at 00:01. Only a screen that was showing *today* follows the clock,
/// which is why [onDayRolled] is told whether it was.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// The clock this file asks for the time. Overridable ONLY by tests: midnight
/// behaviour is otherwise verifiable just by changing the device clock, which
/// is not a thing to do to someone's phone.
@visibleForTesting
DateTime Function() dayRolloverClock = DateTime.now;

mixin DayRolloverMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  DateTime _today = startOfDay(dayRolloverClock());
  Timer? _dayTimer;

  /// The current day, re-read from the clock rather than frozen at first build.
  /// Screens should compare against this instead of calling `DateTime.now()`.
  DateTime get today => _today;

  /// Fires after [today] has advanced. [wasViewingToday] is false when the user
  /// had deliberately navigated to an older day — leave them there.
  void onDayRolled({required bool wasViewingToday});

  void startDayRollover() {
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextMidnight();
  }

  void stopDayRollover() {
    _dayTimer?.cancel();
    _dayTimer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) checkDayRollover();
  }

  /// Compares the clock to [today] and rolls if they disagree. Safe to call at
  /// any time; does nothing on the same day.
  void checkDayRollover() {
    if (!mounted) return;
    final now = startOfDay(dayRolloverClock());
    if (now == _today) {
      _scheduleNextMidnight();
      return;
    }
    // Read BEFORE the roll: `isViewingToday` compares against [today], so once
    // _today has moved the answer is always false.
    final wasViewingToday = isViewingToday;
    setState(() => _today = now);
    onDayRolled(wasViewingToday: wasViewingToday);
    _scheduleNextMidnight();
  }

  void _scheduleNextMidnight() {
    _dayTimer?.cancel();
    final now = dayRolloverClock();
    // A second past midnight, so the timer can never land on 23:59:59.999 and
    // compute the same day it was scheduled on.
    final next = DateTime(now.year, now.month, now.day + 1)
        .add(const Duration(seconds: 1));
    _dayTimer = Timer(next.difference(now), checkDayRollover);
  }

  /// Whether the screen is showing today right now. Screens that can browse
  /// history must override this; one that only ever shows today need not.
  bool get isViewingToday => true;
}
