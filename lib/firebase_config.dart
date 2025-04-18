// firebase_config.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConfig {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // User collection reference
  static final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Rides collection reference
  static final CollectionReference ridesCollection =
      FirebaseFirestore.instance.collection('rides');

  // Bookings collection reference
  static final CollectionReference bookingsCollection =
      FirebaseFirestore.instance.collection('bookings');
}
