import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Refine_search.dart';
import '../utils/app_colors.dart'; // Add import for app colors

class VehicleSearchResultsScreen extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final String location;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool flexibleDates;
  final String? make;
  final String? model;

  const VehicleSearchResultsScreen({
    Key? key,
    required this.selectedVehicleTypes,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.flexibleDates,
    this.make,
    this.model,
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

  // Add a scaffold key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  // You might also want to add this to ensure the search is refreshed when parameters change
  @override
  void didUpdateWidget(VehicleSearchResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if any search parameters have changed
    if (oldWidget.selectedVehicleTypes != widget.selectedVehicleTypes ||
        oldWidget.location != widget.location ||
        oldWidget.pickupDate != widget.pickupDate ||
        oldWidget.returnDate != widget.returnDate ||
        oldWidget.make != widget.make ||
        oldWidget.model != widget.model) {
      _performSearch(); // Reload the search results
    }
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
        if (widget.location.isNotEmpty) {
          final collectionPoint =
              data['collectionPoint'] as Map<String, dynamic>?;
          if (collectionPoint != null) {
            final district = collectionPoint['district'] as String?;
            final city = collectionPoint['city'] as String?;

            if ((district
                        ?.toLowerCase()
                        .contains(widget.location.toLowerCase()) ==
                    true) ||
                (city?.toLowerCase().contains(widget.location.toLowerCase()) ==
                    true) ||
                (district?.toLowerCase() == widget.location.toLowerCase()) ||
                (city?.toLowerCase() == widget.location.toLowerCase())) {
              locationMatches = true;
            }
          }
        } else {
          // If no location specified, consider it a match
          locationMatches = true;
        }

        // Check make match if specified
        bool makeMatches = true;
        if (widget.make != null && widget.make!.isNotEmpty) {
          makeMatches = (data['make'] as String?)?.toLowerCase() ==
              widget.make!.toLowerCase();
        }

        // Check model match if specified
        bool modelMatches = true;
        if (widget.model != null && widget.model!.isNotEmpty) {
          modelMatches = (data['model'] as String?)?.toLowerCase() ==
              widget.model!.toLowerCase();
        }

        // Check date availability (you could add more sophisticated date checking here)
        bool dateMatches = true;
        // Add more detailed date matching logic if needed

        // Only add if all criteria match
        if (locationMatches && makeMatches && modelMatches && dateMatches) {
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
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDarkMode ? AppColors.neutralDark : AppColors.neutralBackground,

      // Add the drawer with RefineSearch
      drawer: RefineSearch(
        selectedVehicleTypes: widget.selectedVehicleTypes,
        location: widget.location,
        pickupDate: widget.pickupDate,
        pickupTime: widget.pickupTime,
        returnDate: widget.returnDate,
        returnTime: widget.returnTime,
        flexibleDates: widget.flexibleDates,
        onApplyFilters: _applyFilters,
      ),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _buildSearchTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: isDarkMode ? AppColors.neutralDark : AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Row(
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
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: const Text(
                        'Filter Result',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.filter_alt,
                        color: AppColors.sandBeige, size: 20),
                  ],
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: TextStyle(color: AppColors.error)))
                    : _searchResults.isEmpty
                        ? _buildNoResultsView()
                        : _buildResultsListView(),
          ),
        ],
      ),
    );
  }

  // Update _buildNoResultsView to use app theme colors
  Widget _buildNoResultsView() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 80,
              color: isDarkMode
                  ? AppColors.neutralMedium
                  : AppColors.neutralLight),
          const SizedBox(height: 16),
          Text(
            'No vehicles found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search criteria',
            style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? AppColors.neutralLight
                    : AppColors.neutralMedium),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Search'),
          )
        ],
      ),
    );
  }

  // Update _buildVehicleCard to use app theme colors
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.neutralDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
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
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(Icons.car_rental,
                          size: 40,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey),
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
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: const BorderRadius.only(
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
                      color: AppColors.neutralDark,
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
                      // Brand logo placeholder
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
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
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '0 (0)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle['collectionPoint']?['city'] ?? 'Colombo'} ${vehicle['collectionPoint']?['district'] ?? '10'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Driver info
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle['hasDriver'] == true
                            ? 'With Driver'
                            : 'Vehicle Only',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
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
                        color: AppColors.success,
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

  void _showFilterScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      elevation: 10,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.85, // Takes 85% of screen width
          heightFactor: 1,
          child: RefineSearch(
            // Change this from FilterScreen to RefineSearch
            selectedVehicleTypes: widget.selectedVehicleTypes,
            location: widget.location,
            pickupDate: widget.pickupDate,
            pickupTime: widget.pickupTime,
            returnDate: widget.returnDate,
            returnTime: widget.returnTime,
            flexibleDates: widget.flexibleDates,
            onApplyFilters: _applyFilters,
          ),
        );
      },
    );
  }

  // Update the _applyFilters method

  void _applyFilters(
    Set<String> selectedVehicleTypes,
    String location,
    DateTime pickupDate,
    TimeOfDay pickupTime,
    DateTime returnDate,
    TimeOfDay returnTime,
    bool flexibleDates,
    String? make,
    String? model,
  ) {
    // First close the drawer
    Navigator.pop(context);

    // Then update the state to show loading
    setState(() {
      _isLoading = true;
    });

    // Update the search results with new parameters
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSearchResultsScreen(
          selectedVehicleTypes: selectedVehicleTypes,
          location: location,
          pickupDate: pickupDate,
          pickupTime: pickupTime,
          returnDate: returnDate,
          returnTime: returnTime,
          flexibleDates: flexibleDates,
          make: make,
          model: model,
        ),
      ),
    );
  }

  // Add this method to the _VehicleSearchResultsScreenState class

  Widget _buildResultsListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final vehicle = _searchResults[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }
}
