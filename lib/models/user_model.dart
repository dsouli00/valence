import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:valence/models/target_macros.dart';
import 'enums.dart';
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
  final double? currentWeight;
  final int? lastSleepRating;
  final TargetMacros? targetMacros;

  // COACH-SPECIFIC FIELDS
  final String? subscriptionTier;
  final DateTime? subscriptionExpiryDate;
  final Map<String, InviteToken>? inviteTokens;
  final int? clientCount;
  final int? maxClients;

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
    this.currentWeight,
    this.lastSleepRating,
    this.targetMacros,
    this.subscriptionTier,
    this.subscriptionExpiryDate,
    this.inviteTokens,
    this.clientCount,
    this.maxClients,
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
      currentWeight: json['currentWeight']?.toDouble(),
      lastSleepRating: json['lastSleepRating'],
      targetMacros: json['targetMacros'] != null
          ? TargetMacros.fromJson(json['targetMacros'] as Map<String, dynamic>)
          : null,
      subscriptionTier: json['subscriptionTier'],
      subscriptionExpiryDate: json['subscriptionExpiryDate'] != null
          ? (json['subscriptionExpiryDate'] as Timestamp).toDate()
          : null,
      inviteTokens: tokens,
      clientCount: json['clientCount'],
      maxClients: json['maxClients'],
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
      if (currentWeight != null) 'currentWeight': currentWeight,
      if (lastSleepRating != null) 'lastSleepRating': lastSleepRating,
      if (targetMacros != null) 'targetMacros': targetMacros!.toJson(),
      if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
      if (subscriptionExpiryDate != null)
        'subscriptionExpiryDate': Timestamp.fromDate(subscriptionExpiryDate!),
      if (inviteTokens != null)
        'inviteTokens': inviteTokens!.map((k, v) => MapEntry(k, v.toJson())),
      if (clientCount != null) 'clientCount': clientCount,
      if (maxClients != null) 'maxClients': maxClients,
    };
  }

  AppUser copyWith({
    int? currentStreak,
    String? lastLogDate,
    ClientStatus? status,
    double? currentWeight,
    int? lastSleepRating,
    TargetMacros? targetMacros,
    String? subscriptionTier,
    DateTime? subscriptionExpiryDate,
    Map<String, InviteToken>? inviteTokens,
    int? clientCount,
    int? maxClients,
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
      currentWeight: currentWeight ?? this.currentWeight,
      lastSleepRating: lastSleepRating ?? this.lastSleepRating,
      targetMacros: targetMacros ?? this.targetMacros,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      inviteTokens: inviteTokens ?? this.inviteTokens,
      clientCount: clientCount ?? this.clientCount,
      maxClients: maxClients ?? this.maxClients,
    );
  }

  static ClientStatus? _statusFromString(String? status) {
    switch (status) {
      case 'on_track': return ClientStatus.onTrack;
      case 'slipping': return ClientStatus.slipping;
      case 'at_risk': return ClientStatus.atRisk;
      default: return null;
    }
  }

  static String _statusToString(ClientStatus status) {
    switch (status) {
      case ClientStatus.onTrack: return 'on_track';
      case ClientStatus.slipping: return 'slipping';
      case ClientStatus.atRisk: return 'at_risk';
    }
  }
}