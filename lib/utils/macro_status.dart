/// What a macro target MEANS, and therefore what colour a number earns.
///
/// One rule used to serve all four: `current > target` turned the number, the
/// unit and the whole bar `alert`. That is right for calories and wrong for
/// everything else. A client who ate 142g of protein against a 130g target had
/// done exactly what her coach asked, and the dashboard told her — in red, on
/// three of three bars — that she had failed.
///
/// Targets do not share a direction:
///
///   * **Protein is a floor.** Reaching it is the goal; passing it is a win and
///     must never read as a fault.
///   * **Carbs and fat are soft ceilings.** Real food does not land on a number.
///     A modest overshoot is ordinary eating, not a slip, so there is a band
///     before anything goes red.
///   * **Calories is the hard ceiling.** This is the one where over genuinely
///     matters, and its behaviour is deliberately unchanged.
///
/// Both the client's dashboard and the coach's mirror of it read from here, so
/// the two sides cannot drift into disagreeing about the same plate.
library;

/// How far past a soft ceiling still counts as on target. Ten percent — the
/// usual coaching tolerance, and roughly the error in eyeballing a portion.
const double kMacroCeilingTolerance = 0.10;

/// Past this, a soft ceiling is a real miss rather than drift. Between the two
/// the metric is worth NOTICING, which is exactly what `watch` is for — a token
/// the palette defines and almost nothing used.
const double kMacroCeilingAlert = 0.25;

enum MacroTargetKind {
  /// A number to reach. Protein.
  floor,

  /// A number to stay near, with room to brush past it. Carbs, fat.
  softCeiling,

  /// A number to stay under. Calories.
  hardCeiling,
}

/// What the figure should say about itself.
enum MacroTone {
  /// Nothing to report — under a ceiling, or on the way to a floor.
  neutral,

  /// Earned. Only a [MacroTargetKind.floor] can reach this.
  good,

  /// Drifting past a soft ceiling. Worth noticing, not a failure — the step
  /// that used to be missing, so carbs and fat jumped from "fine" straight to
  /// "red" the moment they crossed the tolerance band.
  watch,

  /// Past a ceiling by enough to mean something.
  alert,
}

MacroTone macroTone({
  required MacroTargetKind kind,
  required num current,
  required num target,
}) {
  // No target set (a client still in setup) is not a judgement about anything.
  if (target <= 0) return MacroTone.neutral;

  switch (kind) {
    case MacroTargetKind.floor:
      return current >= target ? MacroTone.good : MacroTone.neutral;
    case MacroTargetKind.softCeiling:
      if (current > target * (1 + kMacroCeilingAlert)) return MacroTone.alert;
      if (current > target * (1 + kMacroCeilingTolerance)) return MacroTone.watch;
      return MacroTone.neutral;
    case MacroTargetKind.hardCeiling:
      return current > target ? MacroTone.alert : MacroTone.neutral;
  }
}
