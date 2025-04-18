import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/ride_model.dart';
import '../models/location_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User methods
  Future<UserModel> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
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

  // This is the missing method needed by home_screen.dart
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
}
