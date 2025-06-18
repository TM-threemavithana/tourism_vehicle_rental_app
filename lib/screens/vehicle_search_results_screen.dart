import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VehicleSearchResultsScreen extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final String location;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool flexibleDates;

  const VehicleSearchResultsScreen({
    Key? key,
    required this.selectedVehicleTypes,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.flexibleDates,
  }) : super(key: key);

  @override
  _VehicleSearchResultsScreenState createState() =>
      _VehicleSearchResultsScreenState();
}

class _VehicleSearchResultsScreenState
    extends State<VehicleSearchResultsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    try {
      // Create a query to filter vehicles
      Query query = FirebaseFirestore.instance.collection('vehicles');

      // Filter by vehicle type if specific types selected
      if (widget.selectedVehicleTypes.isNotEmpty) {
        query =
            query.where('type', whereIn: widget.selectedVehicleTypes.toList());
      }

      // Filter by status to only show available vehicles
      query = query.where('status', isEqualTo: 'available');

      // Execute the query
      final QuerySnapshot snapshot = await query.get();

      // Process the results
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check district/city location match
        bool locationMatches = false;
        if (widget.location.isNotEmpty && widget.location != 'Location') {
          final collectionPoint =
              data['collectionPoint'] as Map<String, dynamic>?;
          if (collectionPoint != null) {
            final district = collectionPoint['district'] as String?;
            final city = collectionPoint['city'] as String?;

            if ((district?.toLowerCase() == widget.location.toLowerCase()) ||
                (city?.toLowerCase() == widget.location.toLowerCase())) {
              locationMatches = true;
            }
          }
        } else {
          // If no location specified, consider it a match
          locationMatches = true;
        }

        // Only add if location matches
        if (locationMatches) {
          results.add({...data, 'id': doc.id});
        }
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching for vehicles: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _buildSearchTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Colors.grey[800],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Refine Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Filter Result',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.filter_alt, color: Colors.amber, size: 20),
                  ],
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.red)))
                    : _searchResults.isEmpty
                        ? _buildNoResultsView()
                        : _buildResultsListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No vehicles found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search criteria',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Search'),
          )
        ],
      ),
    );
  }

  Widget _buildResultsListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final vehicle = _searchResults[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vehicle Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Image.network(
                    vehicle['images']?['primaryImageUrl'] ??
                        'https://via.placeholder.com/120x120?text=No+Image',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.car_rental,
                          size: 40, color: Colors.grey),
                    ),
                  ),
                ),

                // Price Badge
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Rs. ${vehicle['pricing']?['daily']?['baseRate'] ?? 'N/A'}.00 / Day',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // KM Badge
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                    ),
                    child: Text(
                      '${vehicle['kmLimit'] ?? '200'} KM / Day',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vehicle Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Logo and Vehicle Name
                  Row(
                    children: [
                      // Brand logo placeholder (you can add actual brand logos)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${vehicle['make']} ${vehicle['model']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Rating
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                            5,
                            (index) => Icon(
                                  Icons.star_border,
                                  size: 14,
                                  color: Colors.amber[700],
                                )),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '0 (0)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle['collectionPoint']?['city'] ?? 'Colombo'} ${vehicle['collectionPoint']?['district'] ?? '10'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Driver info
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle['hasDriver'] == true
                            ? 'With Driver'
                            : 'Vehicle Only',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Availability
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method to the class to handle pluralization
  String _buildSearchTitle() {
    if (widget.selectedVehicleTypes.isEmpty) {
      return 'All Vehicles in ${widget.location.isEmpty ? "All Locations" : widget.location}';
    }

    // Generate properly pluralized vehicle type names
    List<String> pluralizedTypes = widget.selectedVehicleTypes.map((type) {
      // Add pluralization rules for different vehicle types
      switch (type.toLowerCase()) {
        case 'car':
          return 'Cars';
       
        case 'bike':
          return 'Bikes';
        case 'three-wheeler':
          return 'Three-Wheelers';
        
        default:
          // For any other type, just add 's' at the end
          return '${type}s';
      }
    }).toList();

    // Join the pluralized types with commas
    return '${pluralizedTypes.join(", ")} in ${widget.location.isEmpty ? "All Locations" : widget.location}';
  }
}
