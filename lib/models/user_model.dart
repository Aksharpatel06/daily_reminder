import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String area;
  final DateTime createdAt;
  final bool isAdmin;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.area,
    required this.createdAt,
    this.isAdmin = false, // Default is false
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      area: map['area'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] ?? false, // Default to false if not present
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'area': area,
      'isAdmin': isAdmin, // This will be false by default
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
