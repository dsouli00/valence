import 'package:valence/l10n/app_localizations.dart';
import 'package:valence/models/enums.dart';

/// Localized display strings for the app's enums. Kept here (rather than on the
/// enums themselves) so models stay free of any localization dependency. The
/// non-localized `.label`/`.hint` getters in enums.dart remain for any
/// non-UI use; UI should prefer these.

extension ActivityLevelL10n on ActivityLevel {
  String localizedLabel(AppLocalizations l) => switch (this) {
        ActivityLevel.sedentary => l.activitySedentary,
        ActivityLevel.light => l.activityLight,
        ActivityLevel.moderate => l.activityModerate,
        ActivityLevel.active => l.activityActive,
        ActivityLevel.veryActive => l.activityVeryActive,
      };

  String localizedHint(AppLocalizations l) => switch (this) {
        ActivityLevel.sedentary => l.activitySedentaryHint,
        ActivityLevel.light => l.activityLightHint,
        ActivityLevel.moderate => l.activityModerateHint,
        ActivityLevel.active => l.activityActiveHint,
        ActivityLevel.veryActive => l.activityVeryActiveHint,
      };
}

extension CoachSpecialtyL10n on CoachSpecialty {
  String localizedLabel(AppLocalizations l) => switch (this) {
        CoachSpecialty.weightLoss => l.specWeightLoss,
        CoachSpecialty.muscleGain => l.specMuscleGain,
        CoachSpecialty.strength => l.specStrength,
        CoachSpecialty.nutrition => l.specNutrition,
        CoachSpecialty.recomp => l.specRecomp,
        CoachSpecialty.generalFitness => l.specGeneralFitness,
        CoachSpecialty.endurance => l.specEndurance,
        CoachSpecialty.mobility => l.specMobility,
      };
}

extension CoachExperienceL10n on CoachExperience {
  String localizedLabel(AppLocalizations l) => switch (this) {
        CoachExperience.justStarting => l.expJustStarting,
        CoachExperience.oneToThree => l.expOneToThree,
        CoachExperience.threeToFive => l.expThreeToFive,
        CoachExperience.fivePlus => l.expFivePlus,
      };

  String localizedHint(AppLocalizations l) => switch (this) {
        CoachExperience.justStarting => l.expJustStartingHint,
        CoachExperience.oneToThree => l.expOneToThreeHint,
        CoachExperience.threeToFive => l.expThreeToFiveHint,
        CoachExperience.fivePlus => l.expFivePlusHint,
      };
}

extension RosterBandL10n on RosterBand {
  String localizedLabel(AppLocalizations l) => switch (this) {
        RosterBand.solo => l.rosterSolo,
        RosterBand.small => l.rosterSmall,
        RosterBand.growing => l.rosterGrowing,
        RosterBand.established => l.rosterEstablished,
      };
}

extension CoachPriorToolL10n on CoachPriorTool {
  String localizedLabel(AppLocalizations l) => switch (this) {
        CoachPriorTool.whatsapp => l.priorWhatsapp,
        CoachPriorTool.spreadsheets => l.priorSpreadsheets,
        CoachPriorTool.otherApp => l.priorOtherApp,
        CoachPriorTool.penPaper => l.priorPenPaper,
        CoachPriorTool.mix => l.priorMix,
      };
}
