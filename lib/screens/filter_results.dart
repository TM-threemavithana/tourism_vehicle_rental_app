import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/form_data_constants.dart';
import 'vehicle_search_results_screen.dart';

class FilterResultsScreen extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final String location;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool flexibleDates;
  final String? make;
  final String? model;
  final String? sortBy;
  final List<Map<String, dynamic>>? initialResults;

  const FilterResultsScreen({
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
    this.sortBy,
    this.initialResults,
  }) : super(key: key);

  @override
  _FilterResultsScreenState createState() => _FilterResultsScreenState();
}

class _FilterResultsScreenState extends State<FilterResultsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _filteredResults = [];
  String? _errorMessage;

  // Filter state variables
  String _selectedSortOption = 'price_low_to_high';
  RangeValues _priceRange = RangeValues(0, 50000);
  Set<String> _selectedFeatures = {};
  Set<String> _selectedFuelTypes = {};
  Set<String> _selectedTransmissionTypes = {};
  Set<String> _selectedRentModes = {};
  String? _selectedVehicleType;
  String? _selectedMake;
  String? _selectedModel;

  // Common features in vehicles
  final List<String> _commonFeatures = [
    'Air Conditioning',
    'Bluetooth',
    'Navigation',
    'Reverse Camera',
    'Sunroof',
    'Leather Seats',
    'ABS',
    'Cruise Control',
    'Parking Sensors'
  ];

  @override
  void initState() {
    super.initState();
    _selectedSortOption = widget.sortBy ?? 'price_low_to_high';

    // If a vehicle type is selected and there's only one, set it as the selected type
    if (widget.selectedVehicleTypes.length == 1) {
      _selectedVehicleType = widget.selectedVehicleTypes.first;
    }

    // Set make and model if provided
    _selectedMake = widget.make;
    _selectedModel = widget.model;

    // Load initial results or fetch new ones
    if (widget.initialResults != null) {
      _processInitialResults();
    } else {
      _fetchVehicles();
    }
  }

  void _processInitialResults() {
    setState(() {
      _isLoading = true;
    });

    // Get min and max price from the results to set price range
    if (widget.initialResults != null && widget.initialResults!.isNotEmpty) {
      double minPrice = double.infinity;
      double maxPrice = 0;

      for (var vehicle in widget.initialResults!) {
        final price = vehicle['pricing']?['daily']?['vehicleOnly']?['price'];
        if (price != null && price is num) {
          if (price < minPrice) minPrice = price.toDouble();
          if (price > maxPrice) maxPrice = price.toDouble();
        }
      }

      // Add a margin to the max price
      maxPrice = maxPrice + 5000;
      if (maxPrice > 50000) maxPrice = 50000;
      if (minPrice == double.infinity) minPrice = 0;

      setState(() {
        _priceRange = RangeValues(minPrice, maxPrice);
      });
    }

    // Apply initial filtering
    _applyFilters();
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a base query for vehicles
      Query query = FirebaseFirestore.instance.collection('vehicles');

      // Apply vehicle type filter if specified
      if (widget.selectedVehicleTypes.isNotEmpty) {
        query =
            query.where('type', whereIn: widget.selectedVehicleTypes.toList());
      }

      // Only show available vehicles
      query = query.where('status', isEqualTo: 'available');

      // Execute the query
      final QuerySnapshot snapshot = await query.get();

      // Convert to list of maps
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Add the document ID to the data
        results.add({...data, 'id': doc.id});
      }

      // Find price range for the filter
      if (results.isNotEmpty) {
        double minPrice = double.infinity;
        double maxPrice = 0;

        for (var vehicle in results) {
          final price = vehicle['pricing']?['daily']?['vehicleOnly']?['price'];
          if (price != null && price is num) {
            if (price < minPrice) minPrice = price.toDouble();
            if (price > maxPrice) maxPrice = price.toDouble();
          }
        }

        // Add a margin to the max price
        maxPrice = maxPrice + 5000;
        if (maxPrice > 50000) maxPrice = 50000;
        if (minPrice == double.infinity) minPrice = 0;

        setState(() {
          _priceRange = RangeValues(minPrice, maxPrice);
        });
      }

      // Store the results and apply filtering
      setState(() {
        _filteredResults = results;
        _isLoading = false;
      });

      // Apply initial filters
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading vehicles: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    try {
      // Start with all results
      List<Map<String, dynamic>> results = widget.initialResults != null
          ? List.from(widget.initialResults!)
          : _filteredResults;

      // Apply location filter
      if (widget.location.isNotEmpty) {
        results = results.where((vehicle) {
          final collectionPoint =
              vehicle['collectionPoint'] as Map<String, dynamic>?;
          if (collectionPoint == null) return false;

          final district = collectionPoint['district'] as String?;
          final city = collectionPoint['city'] as String?;

          return (district
                      ?.toLowerCase()
                      .contains(widget.location.toLowerCase()) ??
                  false) ||
              (city?.toLowerCase().contains(widget.location.toLowerCase()) ??
                  false);
        }).toList();
      }

      // Apply vehicle type filter
      if (_selectedVehicleType != null) {
        results = results
            .where((vehicle) => vehicle['type'] == _selectedVehicleType)
            .toList();
      }

      // Apply make filter
      if (_selectedMake != null && _selectedMake!.isNotEmpty) {
        results = results
            .where((vehicle) => vehicle['make'] == _selectedMake)
            .toList();
      }

      // Apply model filter
      if (_selectedModel != null && _selectedModel!.isNotEmpty) {
        results = results
            .where((vehicle) => vehicle['model'] == _selectedModel)
            .toList();
      }

      // Apply price range filter
      results = results.where((vehicle) {
        final price = vehicle['pricing']?['daily']?['vehicleOnly']?['price'];
        if (price == null) return false;

        return price >= _priceRange.start && price <= _priceRange.end;
      }).toList();

      // Apply rent mode filter
      if (_selectedRentModes.isNotEmpty) {
        results = results.where((vehicle) {
          final rentMode = vehicle['rentalConditions']?['rentMode'];
          return rentMode != null && _selectedRentModes.contains(rentMode);
        }).toList();
      }

      // Apply fuel type filter
      if (_selectedFuelTypes.isNotEmpty) {
        results = results.where((vehicle) {
          final fuelType = vehicle['fuelType'];
          return fuelType != null && _selectedFuelTypes.contains(fuelType);
        }).toList();
      }

      // Apply transmission filter
      if (_selectedTransmissionTypes.isNotEmpty) {
        results = results.where((vehicle) {
          final transmission = vehicle['transmission'];
          return transmission != null &&
              _selectedTransmissionTypes.contains(transmission);
        }).toList();
      }

      // Apply features filter
      if (_selectedFeatures.isNotEmpty) {
        results = results.where((vehicle) {
          final features =
              vehicle['extras']?['features'] as Map<String, dynamic>?;
          if (features == null) return false;

          // Check if all selected features are available in this vehicle
          for (var feature in _selectedFeatures) {
            if (features[feature] != true) return false;
          }
          return true;
        }).toList();
      }

      // Apply sort
      _sortResults(results);

      setState(() {
        _filteredResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error applying filters: $e';
        _isLoading = false;
      });
    }
  }

  void _sortResults(List<Map<String, dynamic>> results) {
    switch (_selectedSortOption) {
      case 'price_low_to_high':
        results.sort((a, b) {
          final aPrice = a['pricing']?['daily']?['vehicleOnly']?['price'] ?? 0;
          final bPrice = b['pricing']?['daily']?['vehicleOnly']?['price'] ?? 0;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'price_high_to_low':
        results.sort((a, b) {
          final aPrice = a['pricing']?['daily']?['vehicleOnly']?['price'] ?? 0;
          final bPrice = b['pricing']?['daily']?['vehicleOnly']?['price'] ?? 0;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'newest_first':
        results.sort((a, b) {
          final aYear = int.tryParse(a['year']?.toString() ?? '0') ?? 0;
          final bYear = int.tryParse(b['year']?.toString() ?? '0') ?? 0;
          return bYear.compareTo(aYear);
        });
        break;
      case 'rating':
        results.sort((a, b) {
          final aRating = a['rating'] ?? 0;
          final bRating = b['rating'] ?? 0;
          return bRating.compareTo(aRating);
        });
        break;
    }
  }

  void _toggleFeature(String feature) {
    setState(() {
      if (_selectedFeatures.contains(feature)) {
        _selectedFeatures.remove(feature);
      } else {
        _selectedFeatures.add(feature);
      }
    });
    _applyFilters();
  }

  void _toggleFuelType(String fuelType) {
    setState(() {
      if (_selectedFuelTypes.contains(fuelType)) {
        _selectedFuelTypes.remove(fuelType);
      } else {
        _selectedFuelTypes.add(fuelType);
      }
    });
    _applyFilters();
  }

  void _toggleTransmissionType(String transmissionType) {
    setState(() {
      if (_selectedTransmissionTypes.contains(transmissionType)) {
        _selectedTransmissionTypes.remove(transmissionType);
      } else {
        _selectedTransmissionTypes.add(transmissionType);
      }
    });
    _applyFilters();
  }

  void _toggleRentMode(String rentMode) {
    setState(() {
      if (_selectedRentModes.contains(rentMode)) {
        _selectedRentModes.remove(rentMode);
      } else {
        _selectedRentModes.add(rentMode);
      }
    });
    _applyFilters();
  }

  void _updatePriceRange(RangeValues values) {
    setState(() {
      _priceRange = values;
    });
  }

  void _applyPriceRangeFilter() {
    _applyFilters();
  }

  void _changeSortOption(String option) {
    setState(() {
      _selectedSortOption = option;
    });
    _applyFilters();
  }

  void _resetFilters() {
    setState(() {
      _selectedFeatures = {};
      _selectedFuelTypes = {};
      _selectedTransmissionTypes = {};
      _selectedRentModes = {};
      _selectedMake = widget.make;
      _selectedModel = widget.model;
    });
    _applyFilters();
  }

  // Navigate to search results with the filtered data
  void _showFilteredResults() {
    Navigator.pop(context, _filteredResults);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.neutralDark : AppColors.neutralBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filter Results',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter options section
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort options
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortOption(
                              'price_low_to_high', 'Price: Low to High'),
                          _buildSortOption(
                              'price_high_to_low', 'Price: High to Low'),
                          _buildSortOption('newest_first', 'Newest First'),
                          _buildSortOption('rating', 'Highest Rated'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Price range filter
                    Text(
                      'Price Range (LKR per day)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'LKR ${_priceRange.start.round()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Expanded(
                          child: RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 50000,
                            divisions: 50,
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.primary.withOpacity(0.3),
                            labels: RangeLabels(
                              'LKR ${_priceRange.start.round()}',
                              'LKR ${_priceRange.end.round()}',
                            ),
                            onChanged: _updatePriceRange,
                            onChangeEnd: (_) => _applyPriceRangeFilter(),
                          ),
                        ),
                        Text(
                          'LKR ${_priceRange.end.round()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Rent mode section
                    Text(
                      'Rent Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('Vehicle Only', 'Vehicle Only'),
                        _buildFilterChip('With Driver', 'With Driver'),
                        _buildFilterChip('Self Drive', 'Self Drive'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Fuel type section
                    Text(
                      'Fuel Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFuelTypeChip('Petrol'),
                        _buildFuelTypeChip('Diesel'),
                        _buildFuelTypeChip('Electric'),
                        _buildFuelTypeChip('Hybrid'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Transmission section
                    Text(
                      'Transmission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTransmissionChip('Automatic'),
                        _buildTransmissionChip('Manual'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Features section
                    Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonFeatures
                          .map((feature) => _buildFeatureChip(feature))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Results count and apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Loading results...'
                        : '${_filteredResults.length} vehicles found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _showFilteredResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'APPLY FILTERS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String value, String label) {
    final isSelected = _selectedSortOption == value;

    return GestureDetector(
      onTap: () => _changeSortOption(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String rentMode, String label) {
    final isSelected = _selectedRentModes.contains(rentMode);
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => _toggleRentMode(rentMode),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildFuelTypeChip(String fuelType) {
    final isSelected = _selectedFuelTypes.contains(fuelType);
    return FilterChip(
      selected: isSelected,
      label: Text(fuelType),
      onSelected: (_) => _toggleFuelType(fuelType),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildTransmissionChip(String transmissionType) {
    final isSelected = _selectedTransmissionTypes.contains(transmissionType);
    return FilterChip(
      selected: isSelected,
      label: Text(transmissionType),
      onSelected: (_) => _toggleTransmissionType(transmissionType),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildFeatureChip(String feature) {
    final isSelected = _selectedFeatures.contains(feature);
    return FilterChip(
      selected: isSelected,
      label: Text(feature),
      onSelected: (_) => _toggleFeature(feature),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}
