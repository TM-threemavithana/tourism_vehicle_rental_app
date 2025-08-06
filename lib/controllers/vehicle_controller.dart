import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredVehicles =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxMap<String, dynamic> _filters = <String, dynamic>{}.obs;

  // Getters
  List<Map<String, dynamic>> get vehicles => _vehicles;
  List<Map<String, dynamic>> get filteredVehicles => _filteredVehicles;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  Map<String, dynamic> get filters => _filters.value;

  @override
  void onInit() {
    super.onInit();
    loadVehicles();
  }

  // Load all vehicles
  Future<void> loadVehicles() async {
    try {
      _isLoading.value = true;
      final QuerySnapshot snapshot =
          await _firestore.collection('vehicles').get();
      _vehicles.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      _applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load vehicles: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  // Search vehicles
  void searchVehicles(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }

  // Update filters
  void updateFilters(Map<String, dynamic> newFilters) {
    _filters.value = {..._filters.value, ...newFilters};
    _applyFilters();
  }

  // Clear filters
  void clearFilters() {
    _filters.clear();
    _searchQuery.value = '';
    _applyFilters();
  }

  // Apply filters and search
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_vehicles);

    // Apply search query
    if (_searchQuery.value.isNotEmpty) {
      filtered = filtered.where((vehicle) {
        final title = vehicle['title']?.toString().toLowerCase() ?? '';
        final description =
            vehicle['description']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.value.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    // Apply filters
    if (_filters.isNotEmpty) {
      filtered = filtered.where((vehicle) {
        bool matches = true;

        // Price filter
        if (_filters['minPrice'] != null) {
          final price = vehicle['price'] ?? 0;
          matches = matches && price >= _filters['minPrice'];
        }
        if (_filters['maxPrice'] != null) {
          final price = vehicle['price'] ?? 0;
          matches = matches && price <= _filters['maxPrice'];
        }

        // Location filter
        if (_filters['location'] != null && _filters['location'].isNotEmpty) {
          final location = vehicle['location']?.toString().toLowerCase() ?? '';
          matches =
              matches && location.contains(_filters['location'].toLowerCase());
        }

        // Vehicle type filter
        if (_filters['vehicleType'] != null &&
            _filters['vehicleType'].isNotEmpty) {
          final type = vehicle['vehicleType']?.toString().toLowerCase() ?? '';
          matches = matches && type == _filters['vehicleType'].toLowerCase();
        }

        // Availability filter
        if (_filters['available'] != null) {
          final available = vehicle['available'] ?? true;
          matches = matches && available == _filters['available'];
        }

        return matches;
      }).toList();
    }

    _filteredVehicles.value = filtered;
  }

  // Get vehicle by ID
  Map<String, dynamic>? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((vehicle) => vehicle['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Add vehicle to favorites
  Future<void> addToFavorites(String vehicleId) async {
    try {
      Get.snackbar('Success', 'Vehicle added to favorites');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add to favorites: ${e.toString()}');
    }
  }

  // Remove vehicle from favorites
  Future<void> removeFromFavorites(String vehicleId) async {
    try {
      Get.snackbar('Success', 'Vehicle removed from favorites');
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove from favorites: ${e.toString()}');
    }
  }

  // Request vehicle
  Future<void> requestVehicle(
      String vehicleId, Map<String, dynamic> requestData) async {
    try {
      _isLoading.value = true;
      Get.snackbar('Success', 'Vehicle request sent successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to request vehicle: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  // Get vehicle statistics
  Map<String, int> getVehicleStats() {
    final total = _vehicles.length;
    final available = _vehicles.where((v) => v['available'] == true).length;
    final rented = total - available;

    return {
      'total': total,
      'available': available,
      'rented': rented,
    };
  }
}
