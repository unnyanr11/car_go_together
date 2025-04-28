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

  // Use the exact domain from your Firebase project
  ActionCodeSettings actionCodeSettings = ActionCodeSettings(
    url: 'https://cargotogether-64379.firebaseapp.com', // Remove /signup
    handleCodeInApp: true,
    androidPackageName: 'com.example.car_go_together', // Exact package name
    androidMinimumVersion: '1',
    iOSBundleId: 'com.example.carGoTogether', // Exact bundle ID
  );

  // Input validation method
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // Check if user exists in Firestore
  Future<bool> checkUserExists(String email) async {
    try {
      // Check in Firestore users collection
      QuerySnapshot query = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking user existence: ${e.toString()}');
    }
  }

  // Send Sign-In Link to Email
  Future<void> sendSignInLinkToEmail({
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      // Validate email
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email address.');
      }

      // Check if user exists
      bool userExists = await checkUserExists(email);
      if (!userExists) {
        throw Exception('No account found. Please sign up first.');
      }

      // Validate name
      if (name.trim().length < 2) {
        throw Exception('Name must be at least 2 characters long.');
      }

      // Validate phone (optional, adjust regex as needed)
      if (phone.isNotEmpty &&
          !RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$')
              .hasMatch(phone)) {
        throw Exception('Invalid phone number format.');
      }

      // Configure email link settings
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url:
            'https://cargogtogether.page.link/login', // Replace with your app's dynamic link
        handleCodeInApp: true,
        androidPackageName:
            'com.example.car_go_together', // Replace with your Android package name
        androidMinimumVersion: '1',
        iOSBundleId:
            'com.example.carGoTogether', // Replace with your iOS bundle ID
      );

      // Send sign-in link
      await _auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );

      // Store email and user details in local storage for verification
      await storeEmailAndUserDetails(
        email: email.trim(),
        name: name.trim(),
        phone: phone.trim(),
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to send sign-in link: ${e.toString()}');
    }
  }

  // Store email and user details locally
  Future<void> storeEmailAndUserDetails({
    required String email,
    required String name,
    required String phone,
  }) async {
    // Use shared_preferences or secure storage
    // This is a placeholder - implement your preferred local storage
    // Example using shared_preferences:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('pending_email', email);
    // await prefs.setString('pending_name', name);
    // await prefs.setString('pending_phone', phone);
  }

  // Complete Sign-In with Email Link
  Future<UserModel> signInWithEmailLink(String email, String link) async {
    try {
      // Confirm the link is a sign-in link
      if (_auth.isSignInWithEmailLink(link)) {
        // Sign in with email and link
        UserCredential userCredential = await _auth.signInWithEmailLink(
          email: email.trim(),
          emailLink: link,
        );

        // Check if this is a new user
        bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          // Retrieve stored user details (implement your storage retrieval)
          // Example with shared_preferences:
          // final prefs = await SharedPreferences.getInstance();
          // String? storedName = prefs.getString('pending_name');
          // String? storedPhone = prefs.getString('pending_phone');

          // Create user document in Firestore
          UserModel newUser = UserModel(
            id: userCredential.user!.uid,
            email: email.trim(),
            name: '', // Use retrieved name or default
            phone: '', // Use retrieved phone or default
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

          // Clear stored details
          // await prefs.remove('pending_email');
          // await prefs.remove('pending_name');
          // await prefs.remove('pending_phone');

          notifyListeners();
          return newUser;
        }

        // Fetch existing user profile
        DocumentSnapshot userDoc =
            await _db.collection('users').doc(userCredential.user!.uid).get();

        if (!userDoc.exists) {
          throw Exception('User profile not found');
        }

        UserModel user = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>, userDoc.id);

        notifyListeners();
        return user;
      } else {
        throw Exception('Invalid sign-in link');
      }
    } catch (e) {
      throw Exception('Sign-in failed: ${e.toString()}');
    }
  }

  // Register a new user
  Future<UserModel> registerUser({
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      // Validate inputs
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email address.');
      }

      if (name.trim().length < 2) {
        throw Exception('Name must be at least 2 characters long.');
      }

      if (phone.isNotEmpty &&
          !RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$')
              .hasMatch(phone)) {
        throw Exception('Invalid phone number format.');
      }

      // Check if user already exists
      bool userExists = await checkUserExists(email);
      if (userExists) {
        throw Exception('An account with this email already exists.');
      }

      // Create user document in Firestore
      UserModel newUser = UserModel(
        id: '', // Firestore will generate the ID
        email: email.trim(),
        name: name.trim(),
        phone: phone.trim(),
        profileImageUrl: '',
        walletBalance: 0,
        rating: 0,
        ratingCount: 0,
        createdAt: DateTime.now(),
      );

      // Add user to Firestore
      DocumentReference userRef =
          await _db.collection('users').add(newUser.toMap());

      // Update the user with the generated ID
      newUser = newUser.copyWith(id: userRef.id);

      notifyListeners();
      return newUser;
    } catch (e) {
      throw Exception('Failed to register user: ${e.toString()}');
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

  // Check if sign-in link is valid
  bool isSignInLink(String link) {
    return _auth.isSignInWithEmailLink(link);
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

      // Validate and add name if provided
      if (name != null) {
        if (name.trim().length < 2) {
          throw Exception('Name must be at least 2 characters long');
        }
        data['name'] = name.trim();
      }

      // Validate and add phone if provided
      if (phone != null) {
        if (!RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$')
            .hasMatch(phone)) {
          throw Exception('Invalid phone number format');
        }
        data['phone'] = phone.trim();
      }

      // Add profile image URL if provided
      if (profileImageUrl != null) {
        data['profileImageUrl'] = profileImageUrl;
      }

      // Update Firestore document
      await _db.collection('users').doc(_auth.currentUser!.uid).update(data);

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
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
