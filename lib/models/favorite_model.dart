import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id;
  final String vehicleId;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic> vehicleData;

  Favorite({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.createdAt,
    required this.vehicleData,
  });

  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Favorite(
      id: doc.id,
      vehicleId: data['vehicleId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      vehicleData: data['vehicleData'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'vehicleData': vehicleData,
    };
  }
}
