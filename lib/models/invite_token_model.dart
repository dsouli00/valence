
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteToken {
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int currentUses;
  final bool isActive;

  InviteToken({
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.currentUses,
    required this.isActive,
  });

  factory InviteToken.fromJson(Map<String, dynamic> json) {
    return InviteToken(
      token: json['token'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      maxUses: json['maxUses'] as int,
      currentUses: json['currentUses'] as int,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'isActive': isActive,
    };
  }
}