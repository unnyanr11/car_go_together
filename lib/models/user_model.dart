import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class UserModel {
  final String id;
  final String email;
  final String name; // This will be used as fullName
  final String phone; // This will be used as phoneNumber
  final String? profileImageUrl;
  final double walletBalance;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final List<LocationModel> savedPlaces;
  final Map<String, dynamic>? aadharVerification;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.profileImageUrl,
    required this.walletBalance,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    this.savedPlaces = const [],
    this.aadharVerification,
  });

  // Getters for compatibility with ProfileScreen
  String get fullName => name;
  String get phoneNumber => phone;

  // Convenience getters for Aadhar verification
  bool get isAadharVerified => aadharVerification?['status'] == 'verified';

  String? get maskedAadharNumber => aadharVerification?['maskedAadharNumber'];

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    List<LocationModel> places = [];
    if (map['savedPlaces'] != null && map['savedPlaces'] is List) {
      places = (map['savedPlaces'] as List).map((place) {
        if (place is Map<String, dynamic>) {
          return LocationModel.fromMap(place, place['id'] ?? '');
        }
        return LocationModel(
          id: '',
          userId: id,
          name: '',
          address: '',
          latitude: 0,
          longitude: 0,
          type: 'other',
          createdAt: DateTime.now(),
        );
      }).toList();
    }

    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      savedPlaces: places,
      aadharVerification: map['aadharVerification'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'walletBalance': walletBalance,
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'savedPlaces': savedPlaces.map((place) => place.toMap()).toList(),
      'aadharVerification': aadharVerification ?? {},
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImageUrl,
    double? walletBalance,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    List<LocationModel>? savedPlaces,
    Map<String, dynamic>? aadharVerification,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      walletBalance: walletBalance ?? this.walletBalance,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      aadharVerification: aadharVerification ?? this.aadharVerification,
    );
  }

  // Optional: Method to update Aadhar verification
  UserModel updateAadharVerification(Map<String, dynamic> verificationData) {
    return copyWith(
      aadharVerification: {
        'status': verificationData['status'] ?? 'not_verified',
        'verifiedAt': verificationData['verifiedAt'],
        'maskedAadharNumber': verificationData['maskedAadharNumber'],
      },
    );
  }
}
