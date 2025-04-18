import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final String id;
  final String userId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // 'home', 'work', 'other'
  final DateTime createdAt;
  final GeoPoint? _geoPoint; // Private field for Firestore compatibility

  LocationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.type = 'other',
    DateTime? createdAt,
    GeoPoint? geoPoint,
  })  : createdAt = createdAt ?? DateTime.now(),
        _geoPoint = geoPoint;

  // Constructor that takes a GeoPoint instead of separate lat/lng
  factory LocationModel.fromGeoPoint({
    required String id,
    required String userId,
    required String name,
    required String address,
    required GeoPoint geoPoint,
    String type = 'other',
    DateTime? createdAt,
  }) {
    return LocationModel(
      id: id,
      userId: userId,
      name: name,
      address: address,
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      type: type,
      createdAt: createdAt ?? DateTime.now(),
      geoPoint: geoPoint,
    );
  }

  factory LocationModel.fromMap(Map<String, dynamic> map, String id) {
    GeoPoint? geoPoint;
    double latitude;
    double longitude;

    if (map['geoPoint'] != null) {
      geoPoint = map['geoPoint'] as GeoPoint;
      latitude = geoPoint.latitude;
      longitude = geoPoint.longitude;
    } else {
      latitude = (map['latitude'] ?? 0).toDouble();
      longitude = (map['longitude'] ?? 0).toDouble();
    }

    return LocationModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: latitude,
      longitude: longitude,
      type: map['type'] ?? 'other',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      geoPoint: geoPoint,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'userId': userId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Add geoPoint if available for Firestore GeoPoint queries
    if (_geoPoint != null) {
      map['geoPoint'] = _geoPoint as Object;
    }

    return map;
  }

  // Getter for GeoPoint (creates one if it doesn't exist)
  GeoPoint get geoPoint => _geoPoint ?? GeoPoint(latitude, longitude);

  // Getter for LatLng (for Google Maps)
  LatLng get latLng => LatLng(latitude, longitude);

  LocationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? type,
    DateTime? createdAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
