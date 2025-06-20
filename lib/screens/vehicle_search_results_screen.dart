import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Refine_search.dart';
import '../utils/app_colors.dart';
import 'filter_results.dart';
import 'vehicle_detail_page.dart';
import '../services/favorites_service.dart';
import '../helpers/car_logo_helper.dart'; // Add this import at the top

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
    super.key,
    required this.selectedVehicleTypes,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.flexibleDates,
    this.make,
    this.model,
  });

  @override
  State<VehicleSearchResultsScreen> createState() =>
      _VehicleSearchResultsScreenState();
}

class _VehicleSearchResultsScreenState
    extends State<VehicleSearchResultsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add a new GlobalKey for the end drawer
  final GlobalKey<ScaffoldState> _filterDrawerKey = GlobalKey<ScaffoldState>();

  String _selectedSortOption = '';
  RangeValues _priceRange = const RangeValues(0, 50000);
  Set<String> _selectedFeatures = {};
  Set<String> _selectedFuelTypes = {};
  Set<String> _selectedTransmissionTypes = {};
  Set<String> _selectedRentModes = {};

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(VehicleSearchResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedVehicleTypes != widget.selectedVehicleTypes ||
        oldWidget.location != widget.location ||
        oldWidget.pickupDate != widget.pickupDate ||
        oldWidget.returnDate != widget.returnDate ||
        oldWidget.make != widget.make ||
        oldWidget.model != widget.model) {
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    try {
      Query query = FirebaseFirestore.instance.collection('vehicles');

      if (widget.selectedVehicleTypes.isNotEmpty) {
        query =
            query.where('type', whereIn: widget.selectedVehicleTypes.toList());
      }

      query = query.where('status', isEqualTo: 'available');

      final QuerySnapshot snapshot = await query.get();
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

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
          locationMatches = true;
        }

        bool makeMatches = true;
        if (widget.make != null && widget.make!.isNotEmpty) {
          makeMatches = (data['make'] as String?)?.toLowerCase() ==
              widget.make!.toLowerCase();
        }

        bool modelMatches = true;
        if (widget.model != null && widget.model!.isNotEmpty) {
          modelMatches = (data['model'] as String?)?.toLowerCase() ==
              widget.model!.toLowerCase();
        }

        bool dateMatches = true;

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

  // Replace the _showFilterResultsDrawer method
  void _showFilterResultsDrawer() {
    // Use the end drawer instead of modal bottom sheet
    _filterDrawerKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _filterDrawerKey, // Change from _scaffoldKey to _filterDrawerKey
      backgroundColor:
          isDarkMode ? AppColors.neutralDark : AppColors.neutralBackground,
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
      // Add the end drawer for filter results
      endDrawer: FilterResultsDrawer(
        selectedVehicleTypes: widget.selectedVehicleTypes,
        initialResults: _searchResults,
        initialSortOption: _selectedSortOption,
        initialPriceRange: _priceRange,
        initialFeatures: _selectedFeatures,
        initialFuelTypes: _selectedFuelTypes,
        initialTransmissionTypes: _selectedTransmissionTypes,
        initialRentModes: _selectedRentModes,
        onFiltersApplied: (filteredResults, sortOption, priceRange, features,
            fuelTypes, transmissionTypes, rentModes) {
          setState(() {
            _searchResults = filteredResults;
            _selectedSortOption = sortOption;
            _priceRange = priceRange;
            _selectedFeatures = features;
            _selectedFuelTypes = fuelTypes;
            _selectedTransmissionTypes = transmissionTypes;
            _selectedRentModes = rentModes;

            // If the filtered results are empty after applying filters
            if (_searchResults.isEmpty) {
              bool shouldRefineSearch = true;
              _errorMessage = "No vehicles match your filter criteria";
              // Schedule for after the current build cycle
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && shouldRefineSearch) {
                  _performSearch();
                }
              });
            } else {
              _errorMessage = null;
            }
          });
        },
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
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: isDarkMode ? AppColors.neutralDark : AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.tune, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
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
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showFilterResultsDrawer,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.filter_list, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Filter Results',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? _buildNoResultsView()
                        : _buildResultsListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color:
                isDarkMode ? AppColors.neutralMedium : AppColors.neutralLight,
          ),
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

  // Update the vehicle card in the search results
  Widget _buildVehicleCard(
      BuildContext context, Map<String, dynamic> vehicle, bool isDarkMode) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String make = vehicle['make'] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailPage(vehicle: vehicle),
          ),
        );
      },
      child: Container(
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
                        child: Icon(
                          Icons.car_rental,
                          size: 40,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey,
                        ),
                      ),
                    ),
                  ),
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
                        'Rs. ${vehicle['pricing']?['daily']?['vehicleOnly']?['price'] ?? 'N/A'}.00 / Day',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Replace the generic car icon container with car logo
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CarLogoHelper.getCarLogo(make),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${vehicle['make'] ?? 'Unknown'} ${vehicle['model'] ?? ''}',
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
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              (vehicle['rating'] != null &&
                                      index <
                                          (vehicle['rating'] as num).floor())
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle['rating'] ?? 0} (${vehicle['reviewsCount'] ?? 0})',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle['collectionPoint']?['city'] ?? ''} ${vehicle['collectionPoint']?['district'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle['rentalConditions']?['rentMode'] ??
                              'Vehicle Only',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        vehicle['status'] == 'available'
                            ? 'Available'
                            : 'Not Available',
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
      ),
    );
  }

  String _buildSearchTitle() {
    if (widget.selectedVehicleTypes.isEmpty) {
      return 'All Vehicles in ${widget.location.isEmpty ? "All Locations" : widget.location}';
    }

    List<String> pluralizedTypes = widget.selectedVehicleTypes.map((type) {
      switch (type.toLowerCase()) {
        case 'car':
          return 'Cars';
        case 'bike':
          return 'Bikes';
        case 'three-wheeler':
          return 'Three-Wheelers';
        default:
          return '${type}s';
      }
    }).toList();

    return '${pluralizedTypes.join(", ")} in ${widget.location.isEmpty ? "All Locations" : widget.location}';
  }

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
    Navigator.pop(context);

    setState(() {
      _isLoading = true;
    });

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

  // Also fix the buildResultsListView method:
  Widget _buildResultsListView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard(context, _searchResults[index], isDarkMode);
      },
    );
  }
}
