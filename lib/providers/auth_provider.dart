import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/purchase_service.dart';
import '../services/push_service.dart';
import '../services/storage_service.dart';


/// Authentication + session state, and the app's routing brain.
///
/// Holds the signed-in [AppUser] (Firebase Auth identity + their Firestore
/// profile) and exposes the `needs*` getters that splash/signup/link screens
/// consult to decide where a user goes next: link-coach → intake → main app.
///
/// Every operation returns a typed [AuthResult] instead of throwing — the
/// provider has no BuildContext, so errors are CODES that screens localize
/// via `result.localizedMessage(context.l10n)`.
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// A client with no coach yet (signed up without a valid invite, or their
  /// coach deleted their account). Routed to LinkCoachScreen before anything
  /// else — the app is useless without a coach relationship.
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

  /// Creates the account and its `users/{uid}` profile doc. For clients this
  /// also consumes the invite code — see the ordering comment below, it was
  /// a real bug.
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
        return AuthResult.error(AuthErrorCode.inviteRequired);
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
          return AuthResult.error(AuthErrorCode.inviteInvalid);
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
      await _afterAuth();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(
          _authCodeFor(e, AuthErrorCode.signupFailed), e.message);
    } catch (e) {
      return AuthResult.error(AuthErrorCode.signupFailed, '$e');
    }
  }

  /// Email/password sign-in, then loads the Firestore profile. An auth user
  /// with no profile doc is treated as an error (userDataNotFound) rather
  /// than half-signed-in.
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
        await _afterAuth();
        return AuthResult.success();
      }

      return AuthResult.error(AuthErrorCode.userDataNotFound);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(
          _authCodeFor(e, AuthErrorCode.signinFailed), e.message);
    } catch (e) {
      return AuthResult.error(AuthErrorCode.signinFailed, '$e');
    }
  }

  Future<void> signOut() async {
    // Remove this device's FCM token BEFORE auth is gone (rules require auth
    // to write the user doc) — otherwise the next owner of this device would
    // keep receiving the old user's pushes.
    final uid = _currentUser?.uid;
    if (uid != null) await PushService.instance.clearToken(uid);
    await PurchaseService.instance.logout();
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Sends a Firebase password-reset email. Defaults to the signed-in user's
  /// address; pass [email] to override (e.g. from the forgot-password screen).
  Future<AuthResult> sendPasswordResetEmail({String? email}) async {
    final target = (email ?? _currentUser?.email)?.trim();
    if (target == null || target.isEmpty) {
      return AuthResult.error(AuthErrorCode.noEmailOnFile);
    }
    try {
      await _auth.sendPasswordResetEmail(email: target);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(
          _authCodeFor(e, AuthErrorCode.resetFailed), e.message);
    } catch (e) {
      return AuthResult.error(AuthErrorCode.resetFailed);
    }
  }

  /// Links an already-authenticated, coach-less client to a coach by
  /// redeeming an invite code (the LinkCoachScreen path — used when signup
  /// happened without a code, or after their coach deleted their account).
  Future<AuthResult> linkClientToCoach(String inviteToken) async {
    final user = _currentUser;
    if (user == null) return AuthResult.error(AuthErrorCode.notLoggedIn);
    if (user.role != UserRole.client) {
      return AuthResult.error(AuthErrorCode.clientsOnly);
    }

    final rawToken = inviteToken.trim();
    if (rawToken.isEmpty) return AuthResult.error(AuthErrorCode.inviteRequired);

    try {
      final coachId = await _firestoreService.redeemInviteToken(rawToken);
      if (coachId == null) {
        return AuthResult.error(AuthErrorCode.inviteInvalid);
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
      return AuthResult.error(AuthErrorCode.linkCoachFailed, '$e');
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
      return AuthResult.error(AuthErrorCode.notLoggedIn);
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
        // Meal photos first (storage rules only let the OWNER delete their
        // folder, so this must run while still authenticated). Best-effort:
        // a storage hiccup shouldn't block the account deletion itself.
        try {
          await StorageService().deleteAllMealPhotos(user.uid);
        } catch (_) {}
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
          return AuthResult.error(AuthErrorCode.incorrectPassword);
        case 'requires-recent-login':
          return AuthResult.error(AuthErrorCode.recentLoginRequired);
        default:
          return AuthResult.error(
              _authCodeFor(e, AuthErrorCode.deleteFailed), e.message);
      }
    } catch (e) {
      return AuthResult.error(AuthErrorCode.deleteFailed, '$e');
    }
  }

  /// Cold-start session restore, called once by SplashScreen. If a Firebase
  /// session exists but the profile doc is gone (deleted account), we sign
  /// out rather than leave a zombie session.
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
    await _afterAuth();
  }

  /// Post-authentication side effects: register this device for push and sync
  /// any subscription entitlement. Failures here never block sign-in.
  Future<void> _afterAuth() async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      // Fire-and-forget: requesting notification permission shows an OS dialog,
      // which must NOT block post-login navigation.
      unawaited(PushService.instance.syncToken(uid));
      await _saveLocale(uid);
    }
    await _syncSubscription();
  }

  /// Writes the user's current app language to Firestore so the notifier can
  /// localize pushes for them (the sender's locale isn't the recipient's). Uses
  /// the persisted choice, falling back to the device language.
  Future<void> _saveLocale(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_locale');
      final code = (stored != null && stored.isNotEmpty)
          ? stored
          : WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      await _firestoreService.saveUserLocale(uid, code);
    } catch (_) {}
  }

  /// Aligns the coach's stored `subscriptionTier` with RevenueCat's live
  /// entitlement (the source of truth). No-op until RevenueCat is configured.
  Future<void> _syncSubscription() async {
    if (!PurchaseService.instance.isReady) return;
    final user = _currentUser;
    if (user == null || user.role != UserRole.coach) return;
    await PurchaseService.instance.login(user.uid);
    final tierId = await PurchaseService.instance.currentTierId();
    if (tierId != null && tierId != user.subscriptionTier) {
      await _firestore.collection('users').doc(user.uid).set(
        {'subscriptionTier': tierId},
        SetOptions(merge: true),
      );
      await refreshCurrentUser();
    }
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

/// Machine-readable auth error kinds. The provider has no BuildContext, so it
/// returns codes; the UI maps them to localized text via
/// `result.localizedMessage(context.l10n)` (lib/l10n/auth_error_l10n.dart).
enum AuthErrorCode {
  inviteRequired,
  inviteInvalid,
  emailInUse,
  weakPassword,
  invalidEmail,
  wrongCredentials,
  tooManyRequests,
  network,
  userDataNotFound,
  noEmailOnFile,
  notLoggedIn,
  clientsOnly,
  linkCoachFailed,
  incorrectPassword,
  recentLoginRequired,
  resetFailed,
  signupFailed,
  signinFailed,
  deleteFailed,
  unknown,
}

/// Maps a [FirebaseAuthException] to an [AuthErrorCode], falling back to the
/// operation-specific [fallback] for codes we don't special-case.
AuthErrorCode _authCodeFor(FirebaseAuthException e, AuthErrorCode fallback) {
  switch (e.code) {
    case 'email-already-in-use':
      return AuthErrorCode.emailInUse;
    case 'weak-password':
      return AuthErrorCode.weakPassword;
    case 'invalid-email':
      return AuthErrorCode.invalidEmail;
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return AuthErrorCode.wrongCredentials;
    case 'too-many-requests':
      return AuthErrorCode.tooManyRequests;
    case 'network-request-failed':
      return AuthErrorCode.network;
    case 'requires-recent-login':
      return AuthErrorCode.recentLoginRequired;
    default:
      return fallback;
  }
}

// Result class for typed errors
class AuthResult {
  final bool success;
  final AuthErrorCode? code;

  /// Raw English detail (e.g. the FirebaseAuthException message) kept for
  /// debugging only — never show this to the user; use the localized text.
  final String? errorMessage;

  AuthResult.success() : success = true, code = null, errorMessage = null;
  AuthResult.error(this.code, [this.errorMessage]) : success = false;

  String get message => errorMessage ?? '';
}
