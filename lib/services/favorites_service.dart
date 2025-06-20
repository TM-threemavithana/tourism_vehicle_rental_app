import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/favorite_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if a vehicle is in favorites
  Future<bool> isFavorite(String vehicleId) async {
    if (currentUserId == null) return false;

    final QuerySnapshot snapshot = await _favoritesCollection
        .where('userId', isEqualTo: currentUserId)
        .where('vehicleId', isEqualTo: vehicleId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Add a vehicle to favorites
  Future<void> addToFavorites(Map<String, dynamic> vehicleData) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final String vehicleId = vehicleData['id'] ?? '';
    if (vehicleId.isEmpty) throw Exception('Vehicle ID is empty');

    // First check if it's already a favorite
    bool alreadyFavorite = await isFavorite(vehicleId);
    if (alreadyFavorite) return; // Already a favorite, do nothing

    await _favoritesCollection.add({
      'vehicleId': vehicleId,
      'userId': currentUserId,
      'createdAt': Timestamp.now(),
      'vehicleData': vehicleData,
    });
  }

  // Remove a vehicle from favorites
  Future<void> removeFromFavorites(String vehicleId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final QuerySnapshot snapshot = await _favoritesCollection
        .where('userId', isEqualTo: currentUserId)
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Map<String, dynamic> vehicleData) async {
    final String vehicleId = vehicleData['id'] ?? '';
    if (vehicleId.isEmpty) throw Exception('Vehicle ID is empty');

    bool isFav = await isFavorite(vehicleId);

    if (isFav) {
      await removeFromFavorites(vehicleId);
      return false;
    } else {
      await addToFavorites(vehicleData);
      return true;
    }
  }

  // Get all favorites
  Stream<List<Favorite>> getFavorites() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _favoritesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Favorite.fromFirestore(doc)).toList());
  }
}
