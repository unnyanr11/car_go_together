import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String? id;
  final String name;
  final String phoneNumber;
  final String? relationship;
  final String? email;
  final bool isPrimaryContact;
  final DateTime? createdAt;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship,
    this.email,
    this.isPrimaryContact = false,
    this.createdAt,
  });

  // Convert EmergencyContact to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'email': email,
      'isPrimaryContact': isPrimaryContact,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create an EmergencyContact from a Firestore document
  factory EmergencyContact.fromMap(Map<String, dynamic> map, String id) {
    return EmergencyContact(
      id: id,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'],
      email: map['email'],
      isPrimaryContact: map['isPrimaryContact'] ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create a copy of the EmergencyContact with optional parameter updates
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    String? email,
    bool? isPrimaryContact,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Validate emergency contact information
  bool validate() {
    // Basic validation for emergency contact
    return name.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        phoneNumber.length >= 10;
  }

  // Format phone number consistently
  String formatPhoneNumber() {
    // Remove any non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Ensure it's a valid phone number format
    if (digitsOnly.length >= 10) {
      // You can add country-specific formatting here
      return '+1$digitsOnly'; // Example for US phone numbers
    }
    return phoneNumber;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmergencyContact &&
        other.id == id &&
        other.name == name &&
        other.phoneNumber == phoneNumber &&
        other.relationship == relationship &&
        other.email == email &&
        other.isPrimaryContact == isPrimaryContact;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phoneNumber.hashCode ^
        relationship.hashCode ^
        email.hashCode ^
        isPrimaryContact.hashCode;
  }

  @override
  String toString() {
    return 'EmergencyContact(id: $id, name: $name, phoneNumber: $phoneNumber, '
        'relationship: $relationship, isPrimaryContact: $isPrimaryContact)';
  }
}
