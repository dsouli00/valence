
import 'package:cloud_firestore/cloud_firestore.dart';

/// A coach's client-invite code.
///
/// SOURCE OF TRUTH is the top-level `invites/{code}` collection (the doc id
/// is the 7-char uppercase code itself, so validation is a direct get — no
/// query). A copy is also kept under the coach's `inviteTokens` map purely
/// for record-keeping. Redemption is consumed atomically in a transaction
/// (`FirestoreService.redeemInviteToken`) so a single-use code can't be
/// claimed twice.
class InviteToken {
  final String token; // the human-typeable code, e.g. 'K7KM3PA'
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int currentUses;
  final bool isActive; // manual kill-switch, checked alongside expiry/uses

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