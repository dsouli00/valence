import 'enums.dart';

/// The coach's onboarding answers, captured *before* an account exists, so
/// personalization happens ahead of the signup wall (mirrors the client flow).
/// Carries from the coach intake → signup → Firestore.
class CoachIntakeDraft {
  final List<CoachSpecialty> specialties;
  final CoachExperience experience;
  final RosterBand rosterBand;
  final CoachPriorTool priorTool;

  const CoachIntakeDraft({
    required this.specialties,
    required this.experience,
    required this.rosterBand,
    required this.priorTool,
  });

  List<String> get specialtyNames => specialties.map((e) => e.name).toList();
}
