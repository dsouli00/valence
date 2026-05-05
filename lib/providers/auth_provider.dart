import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';


class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Sign up method
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final now = DateTime.now();

      // Create user document in Firestore
      final userData = {
        'name': name,
        'email': email,
        'role': role.name,
        'createdAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userData);

      // Create AppUser object
      _currentUser = AppUser(
        uid: result.user!.uid,
        name: name,
        email: email,
        role: role,
        createdAt: now,
      );

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