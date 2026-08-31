/// Pull-to-refresh, in the app's own colours.
///
/// There was not a single `RefreshIndicator` anywhere in `lib/`. Every surface
/// is a `ListView` fed by a Firestore stream cached in `State`, and a stream is
/// the only thing that can ever change what is on screen — so when one failed,
/// nothing could make it try again. The roster's error state said
/// "Check your connection and try again." and then offered no way to try again;
/// force-quitting the app was the only exit.
///
/// The quiet case is worse than the loud one: Firestore's offline cache serves
/// stale data with no error at all, so a coach can be reading yesterday's roster
/// believing it is live.
///
/// Refreshing a live stream means re-establishing the subscription, which is
/// why [onRefresh] implementations drop the cached stream rather than awaiting
/// a delay — a stream that is still the same object will not re-subscribe, and
/// the spinner would be theatre.
///
/// Stock `RefreshIndicator` is Material-purple on a warm cream app, which is the
/// same mistake as the reminder time picker. This wraps it in tokens.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VRefresh extends StatelessWidget {
  const VRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: t.goldDeep,
      backgroundColor: t.surface,
      strokeWidth: 2.4,
      // Clears the header so the spinner lands over content, not under the title.
      displacement: 28,
      child: child,
    );
  }
}
