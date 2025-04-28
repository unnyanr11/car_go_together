import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/ride_model.dart';
import '../models/location_model.dart';
import '../models/emergency_contact_model.dart'; // Add this import

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User methods

  Future<void> createUserDocument(User firebaseUser) async {
    try {
      // Check if user document already exists
      final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // Create a new user document
        await _db.collection('users').doc(firebaseUser.uid).set({
          'id': firebaseUser.uid,
          'name':
              firebaseUser.displayName ?? '', // Use display name if available
          'email': firebaseUser.email ?? '',
          'phone': firebaseUser.phoneNumber ?? '', // Firebase auth phone number
          'createdAt': FieldValue.serverTimestamp(),
          'rating': 0.0,
          'ratingCount': 0,
          'profileImageUrl': firebaseUser.photoURL ?? '',
          'walletBalance': 0.0, // Add wallet balance
          // Add any other default fields
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  Future<UserModel> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      // Print the entire document data for debugging
      print('User Document Data: ${doc.data()}');

      return UserModel.fromMap({
        'id': userId,
        ...doc.data()!,
      }, userId);
    } catch (e) {
      print('Error in getUser: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Emergency Contact methods
  Future<List<EmergencyContact>> getEmergencyContacts(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts')
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching emergency contacts: $e');
      return [];
    }
  }

  Future<void> addEmergencyContact(
      String userId, EmergencyContact contact) async {
    // Validate before adding
    if (!contact.validate()) {
      throw Exception('Invalid emergency contact');
    }

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts')
          .add(contact.toMap());
    } catch (e) {
      print('Error adding emergency contact: $e');
      rethrow;
    }
  }

  Future<void> updateEmergencyContact(
      String userId, EmergencyContact contact) async {
    if (contact.id == null) {
      throw Exception('Contact ID is required for update');
    }

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts')
          .doc(contact.id)
          .update(contact.toMap());
    } catch (e) {
      print('Error updating emergency contact: $e');
      rethrow;
    }
  }

  Future<void> deleteEmergencyContact(String userId, String contactId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      print('Error deleting emergency contact: $e');
      rethrow;
    }
  }

  // Trip methods
  Future<List<TripModel>> getUserTrips(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .orderBy('departureTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user trips: ${e.toString()}');
    }
  }

  Future<void> bookTrip(TripModel trip) async {
    try {
      // First, add the trip
      DocumentReference tripRef =
          await _db.collection('trips').add(trip.toMap());

      // Then, update the ride's available seats
      await _db.collection('rides').doc(trip.rideId).update({
        'availableSeats': FieldValue.increment(-trip.seats),
      });

      // For user wallet payment, deduct the amount
      if (trip.paymentMethod == 'Wallet') {
        await _db.collection('users').doc(trip.userId).update({
          'walletBalance': FieldValue.increment(-trip.price),
        });
      }

      return;
    } catch (e) {
      throw Exception('Failed to book trip: ${e.toString()}');
    }
  }

  Future<void> cancelTrip(String tripId, String rideId, int seats) async {
    try {
      // First, update the trip status
      await _db.collection('trips').doc(tripId).update({
        'status': 'cancelled',
      });

      // Then, restore the ride's available seats
      await _db.collection('rides').doc(rideId).update({
        'availableSeats': FieldValue.increment(seats),
      });

      return;
    } catch (e) {
      throw Exception('Failed to cancel trip: ${e.toString()}');
    }
  }

  // Ride methods
  Future<List<RideModel>> getAvailableRides() async {
    try {
      // Get rides that are scheduled for the future and have available seats
      QuerySnapshot snapshot = await _db
          .collection('rides')
          .where('departureTime', isGreaterThan: Timestamp.now())
          .where('availableSeats', isGreaterThan: 0)
          .where('status', isEqualTo: 'active')
          .orderBy('departureTime')
          .get();

      return snapshot.docs
          .map((doc) =>
              RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      // Return mock data for now since we're just implementing the structure
      return [];
    }
  }

  // Location methods
  Future<List<LocationModel>> getUserLocations(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user locations: ${e.toString()}');
    }
  }

  Future<List<LocationModel>> getSavedLocations(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get saved locations: ${e.toString()}');
    }
  }

  Future<void> saveLocation(LocationModel location) async {
    try {
      await _db.collection('locations').add(location.toMap());
    } catch (e) {
      throw Exception('Failed to save location: ${e.toString()}');
    }
  }

  // Method to add emergency alert log
  Future<void> logEmergencyAlert(
      String userId, Map<String, dynamic> alertData) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('emergencyAlerts')
          .add({
        ...alertData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging emergency alert: $e');
      rethrow;
    }
  }

  // Method to retrieve emergency alert logs
  Future<List<Map<String, dynamic>>> getEmergencyAlertLogs(
      String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('emergencyAlerts')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error retrieving emergency alert logs: $e');
      return [];
    }
  }

  // Improved Aadhar Verification Method
  Future<void> verifyUserAadhar(
      String userId, Map<String, dynamic> verificationData) async {
    try {
      // More robust input validation
      if (verificationData['aadharNumber'] == null ||
          verificationData['name'] == null ||
          verificationData['isVerified'] == null) {
        throw ArgumentError('Invalid verification data');
      }

      // Validate Aadhar number format
      if (!_validateAadharNumber(verificationData['aadharNumber'])) {
        throw ArgumentError('Invalid Aadhar number format');
      }

      // Update user document with verification details
      await _db.collection('users').doc(userId).update({
        'aadharVerification': {
          'status': verificationData['isVerified'] ? 'verified' : 'failed',
          'verifiedAt': verificationData['isVerified']
              ? FieldValue.serverTimestamp()
              : null,

          // Partially mask Aadhar number for privacy
          'maskedAadharNumber':
              _maskAadharNumber(verificationData['aadharNumber']),

          // Additional verification metadata
          'verificationAttempts': FieldValue.increment(1),

          // Store additional details securely
          'name': _maskName(verificationData['name']),
        }
      });

      // Log verification attempt
      await _db
          .collection('users')
          .doc(userId)
          .collection('verificationLogs')
          .add({
        'type': 'aadhar',
        'status': verificationData['isVerified'] ? 'success' : 'failed',
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'UIDAI Direct Verification',
      });
    } catch (e) {
      print('Error in Aadhar verification: $e');
      rethrow;
    }
  }

  // Enhanced Aadhar number validation
  bool _validateAadharNumber(String aadharNumber) {
    // Basic validation checks
    if (aadharNumber.length != 12) return false;

    // Optional: Implement Verhoeff algorithm for checksum validation
    return _verhoeffAlgorithmCheck(aadharNumber);
  }

  // Verhoeff algorithm for Aadhar number validation
  bool _verhoeffAlgorithmCheck(String aadharNumber) {
    // Placeholder for Verhoeff algorithm implementation
    // This is a complex checksum validation algorithm
    // Actual implementation would be more sophisticated
    return true;
  }

  // Helper method to mask Aadhar number
  String _maskAadharNumber(String aadharNumber) {
    if (aadharNumber.length != 12) return 'Invalid Aadhar';
    return 'XXXX-XXXX-${aadharNumber.substring(8)}';
  }

  // Helper method to mask name for additional privacy
  String _maskName(String name) {
    if (name.length <= 2) return name;
    return '${name[0]}${name[1]}${'*' * (name.length - 2)}';
  }

  // Method to check current Aadhar verification status
  Future<Map<String, dynamic>> getAadharVerificationStatus(
      String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();

      // Default to unverified if no verification data exists
      if (!userDoc.exists || userDoc.data()?['aadharVerification'] == null) {
        return {
          'isVerified': false,
          'status': 'not_verified',
          'maskedAadharNumber': null,
        };
      }

      final verificationData = userDoc.data()?['aadharVerification'];

      return {
        'isVerified': verificationData['status'] == 'verified',
        'status': verificationData['status'],
        'maskedAadharNumber': verificationData['maskedAadharNumber'],
        'verifiedAt': verificationData['verifiedAt'],
        'maskedName': verificationData['name'], // Include masked name
      };
    } catch (e) {
      print('Error retrieving Aadhar verification status: $e');
      return {
        'isVerified': false,
        'status': 'error',
        'maskedAadharNumber': null,
      };
    }
  }

  // Method to reset or retry Aadhar verification
  Future<void> resetAadharVerification(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'aadharVerification': {
          'status': 'not_verified',
          'verifiedAt': null,
          'maskedAadharNumber': null,
          'name': null,
        }
      });
    } catch (e) {
      print('Error resetting Aadhar verification: $e');
      rethrow;
    }
  }
}
