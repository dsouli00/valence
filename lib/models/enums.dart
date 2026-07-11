/// All shared app enums, plus their TDEE math and English labels.
///
/// The `.label`/`.hint` getters here are plain English and exist for non-UI
/// use (logs, defaults). UI must use the localized variants in
/// `lib/l10n/enum_labels.dart` — kept separate so models never depend on
/// localization. Enum values are persisted to Firestore by `.name`, so
/// renaming a value is a DATA MIGRATION, not a refactor.
library;

/// Determines the entire app experience after login (tabs, screens, intake).
enum UserRole {
  coach,
  client,
}

/// Adherence grade shown on the coach roster (Good/Watch/Alert/Setup).
/// Computed by `FirestoreService._refreshClientStatus` after every log action
/// — never set it manually elsewhere or it will be overwritten.
enum ClientStatus {
  /// Client has joined via invite and still needs plan configuration.
  unconfigured,

  /// Client is on track with their goals
  onTrack,

  /// Client is slipping (missed one day)
  slipping,

  /// Client is at risk (missed 2+ days)
  atRisk,
}

enum SleepQuality {
  poor,
  fair,
  good,
  excellent,
}

/// Provenance of a logged meal's nutrition numbers: AI scan confidence
/// (high/medium/low from Gemini) or `manual` when the user typed them.
enum MealConfidence { high, medium, low, manual }

/// Client intake — used to auto-calculate calorie & macro targets.
enum BiologicalSex { male, female }

enum FitnessGoal { lose, maintain, gain }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

extension ActivityLevelX on ActivityLevel {
  /// TDEE multiplier applied to BMR (Mifflin-St Jeor convention).
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Lightly active';
      case ActivityLevel.moderate:
        return 'Moderately active';
      case ActivityLevel.active:
        return 'Very active';
      case ActivityLevel.veryActive:
        return 'Athlete';
    }
  }

  String get hint {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Desk job, little exercise';
      case ActivityLevel.light:
        return 'Light exercise 1–3 days/wk';
      case ActivityLevel.moderate:
        return 'Exercise 3–5 days/wk';
      case ActivityLevel.active:
        return 'Hard exercise 6–7 days/wk';
      case ActivityLevel.veryActive:
        return 'Training twice a day';
    }
  }
}

// ---------------------------------------------------------------------------
// Coach intake — a light profile + business context captured at first run.
// ---------------------------------------------------------------------------

enum CoachSpecialty {
  weightLoss,
  muscleGain,
  strength,
  nutrition,
  recomp,
  generalFitness,
  endurance,
  mobility,
}

extension CoachSpecialtyX on CoachSpecialty {
  String get label {
    switch (this) {
      case CoachSpecialty.weightLoss:
        return 'Weight loss';
      case CoachSpecialty.muscleGain:
        return 'Muscle building';
      case CoachSpecialty.strength:
        return 'Strength';
      case CoachSpecialty.nutrition:
        return 'Nutrition';
      case CoachSpecialty.recomp:
        return 'Body recomp';
      case CoachSpecialty.generalFitness:
        return 'General fitness';
      case CoachSpecialty.endurance:
        return 'Endurance';
      case CoachSpecialty.mobility:
        return 'Mobility & rehab';
    }
  }
}

enum CoachExperience { justStarting, oneToThree, threeToFive, fivePlus }

extension CoachExperienceX on CoachExperience {
  String get label {
    switch (this) {
      case CoachExperience.justStarting:
        return 'Just starting out';
      case CoachExperience.oneToThree:
        return '1–3 years';
      case CoachExperience.threeToFive:
        return '3–5 years';
      case CoachExperience.fivePlus:
        return '5+ years';
    }
  }

  String get hint {
    switch (this) {
      case CoachExperience.justStarting:
        return 'New to coaching';
      case CoachExperience.oneToThree:
        return 'Building my book';
      case CoachExperience.threeToFive:
        return 'Established coach';
      case CoachExperience.fivePlus:
        return 'Seasoned pro';
    }
  }
}

enum RosterBand { solo, small, growing, established }

extension RosterBandX on RosterBand {
  String get label {
    switch (this) {
      case RosterBand.solo:
        return 'Just me, no clients yet';
      case RosterBand.small:
        return '1–10 clients';
      case RosterBand.growing:
        return '11–25 clients';
      case RosterBand.established:
        return '25+ clients';
    }
  }
}

enum CoachPriorTool { whatsapp, spreadsheets, otherApp, penPaper, mix }

extension CoachPriorToolX on CoachPriorTool {
  String get label {
    switch (this) {
      case CoachPriorTool.whatsapp:
        return 'WhatsApp & chat';
      case CoachPriorTool.spreadsheets:
        return 'Spreadsheets';
      case CoachPriorTool.otherApp:
        return 'Another coaching app';
      case CoachPriorTool.penPaper:
        return 'Pen & paper';
      case CoachPriorTool.mix:
        return 'A bit of everything';
    }
  }
}
