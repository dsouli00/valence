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

  /// A linked client who hasn't completed intake yet (no plan configured).
  /// They should be routed to the intake form before the main app.
  bool get needsIntake {
    final user = _currentUser;
    if (user == null || user.role != UserRole.client) return false;
    if (needsCoachLink) return false;
    return user.status == ClientStatus.unconfigured || user.targetMacros == null;
  }

  /// A coach who hasn't completed their first-run intake yet. Routed through
  /// the coach intake before the main app.
  bool get needsCoachIntake {
    final user = _currentUser;
    if (user == null || user.role != UserRole.coach) return false;
    return user.coachOnboarded != true;
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
      // Clients join by invite code. We create the auth account FIRST so that the
      // invite read/redeem happens while authenticated (Firestore rules deny
      // unauthenticated access). If the code turns out to be invalid or already
      // used, we delete the just-created account so the user can retry cleanly.
      if (role == UserRole.client &&
          (inviteToken == null || inviteToken.trim().isEmpty)) {
        return AuthResult.error('An invite code is required to join');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? resolvedCoachId;
      if (role == UserRole.client) {
        resolvedCoachId = await _firestoreService.redeemInviteToken(inviteToken!);
        if (resolvedCoachId == null) {
          try {
            await result.user?.delete();
          } catch (_) {}
          return AuthResult.error(
            'That invite code is invalid, expired, or already used',
          );
        }
      }

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

  /// Sends a Firebase password-reset email. Defaults to the signed-in user's
  /// address; pass [email] to override (e.g. from the forgot-password screen).
  Future<AuthResult> sendPasswordResetEmail({String? email}) async {
    final target = (email ?? _currentUser?.email)?.trim();
    if (target == null || target.isEmpty) {
      return AuthResult.error('No email address on file');
    }
    try {
      await _auth.sendPasswordResetEmail(email: target);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.message ?? 'Could not send the reset email');
    } catch (e) {
      return AuthResult.error('Could not send the reset email');
    }
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

  /// Permanently deletes the signed-in user's own account.
  ///
  /// Firebase requires a recent login to delete an account, so we reauthenticate
  /// with the supplied [password] first. Then we cascade-delete the user's
  /// Firestore data WHILE still authenticated (rules require auth), and finally
  /// delete the Auth account. On success the user is signed out locally.
  Future<AuthResult> deleteAccount({required String password}) async {
    final user = _currentUser;
    final firebaseUser = _auth.currentUser;
    if (user == null || firebaseUser == null) {
      return AuthResult.error('You must be logged in');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email,
        password: password,
      );
      await firebaseUser.reauthenticateWithCredential(credential);

      // Cascade Firestore data before removing the auth account.
      if (user.role == UserRole.coach) {
        await _firestoreService.deleteCoachData(user.uid);
      } else {
        await _firestoreService.deleteOwnClientData(user.uid);
      }

      await firebaseUser.delete();

      _currentUser = null;
      notifyListeners();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return AuthResult.error('Incorrect password');
        case 'requires-recent-login':
          return AuthResult.error('Please sign out, sign in again, then retry');
        default:
          return AuthResult.error(e.message ?? 'Could not delete your account');
      }
    } catch (e) {
      return AuthResult.error('Could not delete your account: $e');
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

  /// Re-fetches the current user's Firestore profile and updates listeners.
  Future<void> refreshCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return;
    _currentUser = AppUser.fromJson(doc.data()!, firebaseUser.uid);
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
