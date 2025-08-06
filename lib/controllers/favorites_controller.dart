import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/favorites_service.dart';
import '../models/favorite_model.dart';

class FavoritesController extends GetxController {
  final FavoritesService _favoritesService = FavoritesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxList<Favorite> _favorites = <Favorite>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<Favorite> get favorites => _favorites;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  // Load user favorites
  Future<void> loadFavorites() async {
    try {
      _isLoading.value = true;
      await for (List<Favorite> favorites in _favoritesService.getFavorites()) {
        _favorites.value = favorites;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load favorites: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  // Add to favorites
  Future<void> addToFavorites(Map<String, dynamic> vehicleData) async {
    try {
      await _favoritesService.addToFavorites(vehicleData);
      Get.snackbar('Success', 'Added to favorites');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add to favorites: ${e.toString()}');
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String vehicleId) async {
    try {
      await _favoritesService.removeFromFavorites(vehicleId);
      Get.snackbar('Success', 'Removed from favorites');
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove from favorites: ${e.toString()}');
    }
  }

  // Check if vehicle is in favorites
  bool isInFavorites(String vehicleId) {
    return _favorites.any((favorite) => favorite.vehicleId == vehicleId);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(Map<String, dynamic> vehicleData) async {
    try {
      await _favoritesService.toggleFavorite(vehicleData);
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle favorite: ${e.toString()}');
    }
  }

  // Get favorites count
  int get favoritesCount => _favorites.length;
}
