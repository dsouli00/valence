/// Picks a glyph for a workout template from its NAME.
///
/// Lived as a private function inside the library screen, so the Swap Workout
/// sheet — which shows the same templates — could not reach it and hardcoded a
/// barbell for every one. The same three workouts looked distinct on one screen
/// and identical on another, a few taps apart.
///
/// Matching is substring-based across the app's six languages. It is a nice
/// touch rather than a promise: an unmatched name gets the barbell.
library;

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/widgets.dart';

IconData workoutGlyph(String name) {
  final n = name.toLowerCase();
  bool has(List<String> words) => words.any(n.contains);

  if (has(['run', 'sprint', 'cardio', 'hiit', 'conditioning', 'course', 'correr', 'lauf'])) {
    return PhosphorIconsFill.personSimpleRun;
  }
  if (has(['bike', 'cycle', 'spin', 'vélo', 'velo', 'bici', 'rad'])) {
    return PhosphorIconsFill.personSimpleBike;
  }
  if (has(['swim', 'nage', 'nata', 'schwimm'])) {
    return PhosphorIconsFill.personSimpleSwim;
  }
  if (has(['box', 'mma', 'kick', 'fight'])) {
    return PhosphorIconsFill.boxingGlove;
  }
  if (has(['yoga', 'stretch', 'mobility', 'flex', 'recovery', 'étirement'])) {
    return PhosphorIconsFill.personSimpleTaiChi;
  }
  if (has(['walk', 'steps', 'marche', 'caminar', 'geh'])) {
    return PhosphorIconsFill.footprints;
  }
  if (has(['core', 'abs', 'plank', 'gainage'])) {
    return PhosphorIconsFill.target;
  }
  if (has(['heart', 'endurance'])) {
    return PhosphorIconsFill.heartbeat;
  }
  return PhosphorIconsFill.barbell;
}
