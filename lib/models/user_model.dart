import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:valence/models/target_macros.dart';
import 'enums.dart';
import 'habit_model.dart';
import 'invite_token_model.dart';



class AppUser {
  // COMMON FIELDS
  final String uid;
  final UserRole role;
  final String name;
  final String email;
  final DateTime createdAt;

  // CLIENT-SPECIFIC FIELDS
  final String? coachId;
  final int? currentStreak;
  final String? lastLogDate;
  final ClientStatus? status;
  final String? statusSummary;
  final double? currentWeight;
  final int? lastSleepRating;
  final TargetMacros? targetMacros;
  final String? weightUnit; // 'kg' (metric) | 'lb' (imperial) — display preference only

  // CLIENT INTAKE (drives auto-calculated targets)
  final int? age;
  final double? heightCm;
  final double? targetWeight;
  final String? sex; // 'male' | 'female'
  final String? activityLevel; // ActivityLevel.name
  final String? goal; // 'lose' | 'maintain' | 'gain'

  // COACH-SPECIFIC FIELDS
  final String? subscriptionTier;
  final DateTime? subscriptionExpiryDate;
  final Map<String, InviteToken>? inviteTokens;
  final int? clientCount;
  final int? maxClients;

  // COACH INTAKE (first-run profile + business context)
  final List<String>? specialties;
  final String? coachExperience; // CoachExperience.name
  final String? rosterBand; // RosterBand.name
  final String? priorTool; // CoachPriorTool.name
  final bool? coachOnboarded;

  // COACH-DEFINED CUSTOM HABITS for this client (additive — supplements the
  // core water/sleep/weight pillars, never replaces them).
  final List<HabitDefinition>? customHabits;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    required this.createdAt,
    this.coachId,
    this.currentStreak,
    this.lastLogDate,
    this.status,
    this.statusSummary,
    this.currentWeight,
    this.lastSleepRating,
    this.targetMacros,
    this.weightUnit,
    this.age,
    this.heightCm,
    this.targetWeight,
    this.sex,
    this.activityLevel,
    this.goal,
    this.subscriptionTier,
    this.subscriptionExpiryDate,
    this.inviteTokens,
    this.clientCount,
    this.maxClients,
    this.specialties,
    this.coachExperience,
    this.rosterBand,
    this.priorTool,
    this.coachOnboarded,
    this.customHabits,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String documentId) {
    // Parse invite tokens map
    Map<String, InviteToken>? tokens;
    if (json['inviteTokens'] != null) {
      tokens = (json['inviteTokens'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, InviteToken.fromJson(value as Map<String, dynamic>)),
      );
    }

    return AppUser(
      uid: documentId,
      role: json['role'] == 'coach' ? UserRole.coach : UserRole.client,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      coachId: json['coachId'],
      currentStreak: json['currentStreak'],
      lastLogDate: json['lastLogDate'],
      status: _statusFromString(json['status']),
      statusSummary: json['statusSummary'] as String?,
      currentWeight: json['currentWeight']?.toDouble(),
      lastSleepRating: json['lastSleepRating'],
      weightUnit: json['weightUnit'] as String?,
      targetMacros: json['targetMacros'] != null
          ? TargetMacros.fromJson(json['targetMacros'] as Map<String, dynamic>)
          : null,
      age: json['age'],
      heightCm: json['heightCm']?.toDouble(),
      targetWeight: json['targetWeight']?.toDouble(),
      sex: json['sex'] as String?,
      activityLevel: json['activityLevel'] as String?,
      goal: json['goal'] as String?,
      subscriptionTier: json['subscriptionTier'],
      subscriptionExpiryDate: json['subscriptionExpiryDate'] != null
          ? (json['subscriptionExpiryDate'] as Timestamp).toDate()
          : null,
      inviteTokens: tokens,
      clientCount: json['clientCount'],
      maxClients: json['maxClients'],
      specialties: (json['specialties'] as List?)?.map((e) => e.toString()).toList(),
      coachExperience: json['coachExperience'] as String?,
      rosterBand: json['rosterBand'] as String?,
      priorTool: json['priorTool'] as String?,
      coachOnboarded: json['coachOnboarded'] as bool?,
      customHabits: (json['customHabits'] as List?)
          ?.map((e) => HabitDefinition.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      if (coachId != null) 'coachId': coachId,
      if (currentStreak != null) 'currentStreak': currentStreak,
      if (lastLogDate != null) 'lastLogDate': lastLogDate,
      if (status != null) 'status': _statusToString(status!),
      if (statusSummary != null) 'statusSummary': statusSummary,
      if (currentWeight != null) 'currentWeight': currentWeight,
      if (lastSleepRating != null) 'lastSleepRating': lastSleepRating,
      if (weightUnit != null) 'weightUnit': weightUnit,
      if (targetMacros != null) 'targetMacros': targetMacros!.toJson(),
      if (age != null) 'age': age,
      if (heightCm != null) 'heightCm': heightCm,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (sex != null) 'sex': sex,
      if (activityLevel != null) 'activityLevel': activityLevel,
      if (goal != null) 'goal': goal,
      if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
      if (subscriptionExpiryDate != null)
        'subscriptionExpiryDate': Timestamp.fromDate(subscriptionExpiryDate!),
      if (inviteTokens != null)
        'inviteTokens': inviteTokens!.map((k, v) => MapEntry(k, v.toJson())),
      if (clientCount != null) 'clientCount': clientCount,
      if (maxClients != null) 'maxClients': maxClients,
      if (specialties != null) 'specialties': specialties,
      if (coachExperience != null) 'coachExperience': coachExperience,
      if (rosterBand != null) 'rosterBand': rosterBand,
      if (priorTool != null) 'priorTool': priorTool,
      if (coachOnboarded != null) 'coachOnboarded': coachOnboarded,
      if (customHabits != null)
        'customHabits': customHabits!.map((h) => h.toJson()).toList(),
    };
  }

  AppUser copyWith({
    int? currentStreak,
    String? lastLogDate,
    ClientStatus? status,
    String? statusSummary,
    double? currentWeight,
    int? lastSleepRating,
    TargetMacros? targetMacros,
    String? weightUnit,
    int? age,
    double? heightCm,
    double? targetWeight,
    String? sex,
    String? activityLevel,
    String? goal,
    String? subscriptionTier,
    DateTime? subscriptionExpiryDate,
    Map<String, InviteToken>? inviteTokens,
    int? clientCount,
    int? maxClients,
    List<String>? specialties,
    String? coachExperience,
    String? rosterBand,
    String? priorTool,
    bool? coachOnboarded,
    List<HabitDefinition>? customHabits,
  }) {
    return AppUser(
      uid: uid,
      role: role,
      name: name,
      email: email,
      createdAt: createdAt,
      coachId: coachId,
      currentStreak: currentStreak ?? this.currentStreak,
      lastLogDate: lastLogDate ?? this.lastLogDate,
      status: status ?? this.status,
      statusSummary: statusSummary ?? this.statusSummary,
      currentWeight: currentWeight ?? this.currentWeight,
      lastSleepRating: lastSleepRating ?? this.lastSleepRating,
      targetMacros: targetMacros ?? this.targetMacros,
      weightUnit: weightUnit ?? this.weightUnit,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      targetWeight: targetWeight ?? this.targetWeight,
      sex: sex ?? this.sex,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      inviteTokens: inviteTokens ?? this.inviteTokens,
      clientCount: clientCount ?? this.clientCount,
      maxClients: maxClients ?? this.maxClients,
      specialties: specialties ?? this.specialties,
      coachExperience: coachExperience ?? this.coachExperience,
      rosterBand: rosterBand ?? this.rosterBand,
      priorTool: priorTool ?? this.priorTool,
      coachOnboarded: coachOnboarded ?? this.coachOnboarded,
      customHabits: customHabits ?? this.customHabits,
    );
  }

  /// Whether this user displays body weight in metric (kg). Defaults to metric
  /// unless they explicitly chose 'lb'.
  bool get usesMetricWeight => weightUnit != 'lb';

  static ClientStatus? _statusFromString(String? status) {
    switch (status) {
      case 'unconfigured': return ClientStatus.unconfigured;
      case 'on_track': return ClientStatus.onTrack;
      case 'slipping': return ClientStatus.slipping;
      case 'at_risk': return ClientStatus.atRisk;
      default: return null;
    }
  }

  static String _statusToString(ClientStatus status) {
    switch (status) {
      case ClientStatus.unconfigured: return 'unconfigured';
      case ClientStatus.onTrack: return 'on_track';
      case ClientStatus.slipping: return 'slipping';
      case ClientStatus.atRisk: return 'at_risk';
    }
  }
}
