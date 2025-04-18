import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class TripModel {
  final String id;
  final String userId;
  final String rideId;
  final String driverId;
  final String driverName;
  final double driverRating;
  final LocationModel pickupLocation;
  final LocationModel destinationLocation;
  final DateTime departureTime;
  final double price;
  final int seats;
  final String vehicleModel;
  final String vehicleColor;
  final String status; // 'confirmed', 'completed', 'cancelled'
  final String paymentMethod; // 'Wallet', 'Credit/Debit Card', 'Cash'
  final DateTime createdAt;

  TripModel({
    required this.id,
    required this.userId,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.departureTime,
    required this.price,
    required this.seats,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.status,
    this.paymentMethod = 'Wallet',
    required this.createdAt,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      userId: map['userId'] ?? '',
      rideId: map['rideId'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverRating: (map['driverRating'] ?? 0).toDouble(),
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
      seats: map['seats'] ?? 1,
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleColor: map['vehicleColor'] ?? '',
      status: map['status'] ?? 'confirmed',
      paymentMethod: map['paymentMethod'] ?? 'Wallet',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rideId': rideId,
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'pickupLocation': pickupLocation.toMap(),
      'destinationLocation': destinationLocation.toMap(),
      'departureTime': Timestamp.fromDate(departureTime),
      'price': price,
      'seats': seats,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TripModel copyWith({
    String? id,
    String? userId,
    String? rideId,
    String? driverId,
    String? driverName,
    double? driverRating,
    LocationModel? pickupLocation,
    LocationModel? destinationLocation,
    DateTime? departureTime,
    double? price,
    int? seats,
    String? vehicleModel,
    String? vehicleColor,
    String? status,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      seats: seats ?? this.seats,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
