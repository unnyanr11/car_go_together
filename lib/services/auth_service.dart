import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // More specific error handling
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        default:
          throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error during sign-in: $e');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      String phone,
      ) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        profileImageUrl: '',
        walletBalance: 0,
        rating: 0,
        ratingCount: 0,
        createdAt: DateTime.now(),
      );

      await _db
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific registration errors
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Email is already in use.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'weak-password':
          throw Exception('Password is too weak.');
        default:
          throw Exception('Registration failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Get user profile
  Future<UserModel> getUserProfile() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc =
      await _db.collection('users').doc(_auth.currentUser!.uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        throw Exception('User profile not found');
      }
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;

      await _db.collection('users').doc(_auth.currentUser!.uid).update(data);

      // Optionally update display name in Firebase Auth
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'user-not-found':
          throw Exception('No user found with this email.');
        default:
          throw Exception('Failed to send password reset email: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error during password reset: $e');
    }
  }

  // Check email verification status
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No user signed in');
      }
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to resend verification email: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No user signed in');
      }

      // Delete Firestore user document
      await _db.collection('users').doc(_auth.currentUser!.uid).delete();

      // Delete Firebase Authentication user
      await _auth.currentUser!.delete();

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}