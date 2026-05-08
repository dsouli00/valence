import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';


class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get needsCoachLink {
    final user = _currentUser;
    if (user == null || user.role != UserRole.client) return false;
    return (user.coachId == null || user.coachId!.trim().isEmpty);
  }

  // Sign up method
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? inviteToken,
  }) async {
    try {
      // For client signup we require a valid invite token so coach-client linking is secure.
      String? resolvedCoachId;
      if (role == UserRole.client) {
        if (inviteToken == null || inviteToken.trim().isEmpty) {
          return AuthResult.error('Invite link is required for client signup');
        }
        resolvedCoachId = await _firestoreService.redeemInviteToken(inviteToken);
        if (resolvedCoachId == null) {
          return AuthResult.error('Invite link is invalid or has expired');
        }
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final now = DateTime.now();
      final appUser = AppUser(
        uid: result.user!.uid,
        name: name,
        email: email,
        role: role,
        createdAt: now,
        currentStreak: 0,
        coachId: resolvedCoachId,
        status: role == UserRole.client ? ClientStatus.unconfigured : null,
      );
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(appUser.toJson());

      _currentUser = appUser;

      notifyListeners();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.message ?? 'An error occurred during signup');
    } catch (e) {
      return AuthResult.error('An error occurred: $e');
    }
  }

  // Sign in method
  Future<AuthResult> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _currentUser = AppUser.fromJson(userData, result.user!.uid);
        notifyListeners();
        return AuthResult.success();
      }

      return AuthResult.error('User data not found');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.message ?? 'An error occurred during sign in');
    } catch (e) {
      return AuthResult.error('An error occurred: $e');
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<AuthResult> linkClientToCoach(String inviteToken) async {
    final user = _currentUser;
    if (user == null) return AuthResult.error('You must be logged in');
    if (user.role != UserRole.client) {
      return AuthResult.error('Only client accounts can link a coach');
    }

    final rawToken = inviteToken.trim();
    if (rawToken.isEmpty) return AuthResult.error('Invite link is required');

    try {
      final coachId = await _firestoreService.redeemInviteToken(rawToken);
      if (coachId == null) {
        return AuthResult.error('Invite link is invalid or has expired');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'coachId': coachId,
        'status': 'unconfigured',
      });

      final refreshedDoc = await _firestore.collection('users').doc(user.uid).get();
      if (refreshedDoc.exists) {
        _currentUser = AppUser.fromJson(refreshedDoc.data()!, user.uid);
        notifyListeners();
      }

      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Failed to link coach: $e');
    }
  }

  Future<void> initializeAuth() async {
    final User? firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = AppUser.fromJson(userDoc.data()!, firebaseUser.uid);
        } else {
          await _auth.signOut();
        }
      } catch (e) {
        debugPrint("Error initializing auth: $e");
      }
    }

    notifyListeners();
  }
}

// Result class for typed errors
class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult.success() : success = true, errorMessage = null;
  AuthResult.error(this.errorMessage) : success = false;

  String get message => errorMessage ?? '';
}
