import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final double driverRating;
  final int driverRatingCount;
  final LocationModel pickupLocation;
  final LocationModel destinationLocation;
  final DateTime departureTime;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String vehicleModel;
  final String vehicleColor;
  final String status;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    required this.driverRatingCount,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.departureTime,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.status,
    required this.createdAt,
  });

  factory RideModel.fromMap(Map<String, dynamic> map, String id) {
    return RideModel(
      id: id,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverRating: (map['driverRating'] ?? 0).toDouble(),
      driverRatingCount: map['driverRatingCount'] ?? 0,
      pickupLocation: LocationModel.fromMap(
        map['pickupLocation'] ?? {},
        map['pickupLocation']['id'] ?? '',
      ),
      destinationLocation: LocationModel.fromMap(
        map['destinationLocation'] ?? {},
        map['destinationLocation']['id'] ?? '',
      ),
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      price: (map['price'] ?? 0).toDouble(),
      totalSeats: map['totalSeats'] ?? 0,
      availableSeats: map['availableSeats'] ?? 0,
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleColor: map['vehicleColor'] ?? '',
      status: map['status'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'driverRatingCount': driverRatingCount,
      'pickupLocation': pickupLocation.toMap(),
      'destinationLocation': destinationLocation.toMap(),
      'departureTime': Timestamp.fromDate(departureTime),
      'price': price,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    double? driverRating,
    int? driverRatingCount,
    LocationModel? pickupLocation,
    LocationModel? destinationLocation,
    DateTime? departureTime,
    double? price,
    int? totalSeats,
    int? availableSeats,
    String? vehicleModel,
    String? vehicleColor,
    String? status,
    DateTime? createdAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      driverRatingCount: driverRatingCount ?? this.driverRatingCount,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
