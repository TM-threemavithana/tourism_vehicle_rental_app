import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FilterResultsDrawer extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final List<Map<String, dynamic>> initialResults;
  // Add new parameters to receive saved filter state
  final String initialSortOption;
  final RangeValues initialPriceRange;
  final Set<String> initialFeatures;
  final Set<String> initialFuelTypes;
  final Set<String> initialTransmissionTypes;
  final Set<String> initialRentModes;
  // Update callback to return the selected filter state
  final Function(List<Map<String, dynamic>>, String, RangeValues, Set<String>,
      Set<String>, Set<String>, Set<String>) onFiltersApplied;

  const FilterResultsDrawer({
    super.key,
    required this.selectedVehicleTypes,
    required this.initialResults,
    // Initialize with defaults but allow passing saved values
    this.initialSortOption = 'price_low_to_high',
    this.initialPriceRange = const RangeValues(0, 50000),
    this.initialFeatures = const {},
    this.initialFuelTypes = const {},
    this.initialTransmissionTypes = const {},
    this.initialRentModes = const {},
    required this.onFiltersApplied,
  });

  @override
  _FilterResultsDrawerState createState() => _FilterResultsDrawerState();
}

class _FilterResultsDrawerState extends State<FilterResultsDrawer> {
  // Filter state variables - initialize from widget's passed values
  late String _selectedSortOption;
  late RangeValues _priceRange;
  late Set<String> _selectedFeatures;
  late Set<String> _selectedFuelTypes;
  late Set<String> _selectedTransmissionTypes;
  late Set<String> _selectedRentModes;
  late List<Map<String, dynamic>> _filteredResults;

  // Existing code
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

    // Initialize filter state with saved values from the parent widget
    // Don't set a default sort option - use the one passed from the parent or empty string
    _selectedSortOption = widget.initialSortOption;
    _selectedFeatures = Set.from(widget.initialFeatures);
    _selectedFuelTypes = Set.from(widget.initialFuelTypes);
    _selectedTransmissionTypes = Set.from(widget.initialTransmissionTypes);
    _selectedRentModes = Set.from(widget.initialRentModes);
    _filteredResults = List.from(widget.initialResults);

    // Initialize price range with saved value, but ensure it's valid for current data
    if (widget.initialPriceRange.start == 0 &&
        widget.initialPriceRange.end == 50000 &&
        widget.initialResults.isNotEmpty) {
      // No saved price range, calculate from data
      _setPriceRangeFromData();
    } else {
      // Use saved price range
      _priceRange = widget.initialPriceRange;
    }
  }

  // Add helper method to set price range from data
  void _setPriceRangeFromData() {
    if (widget.initialResults.isNotEmpty) {
      double minPrice = double.infinity;
      double maxPrice = 0;

      for (var vehicle in widget.initialResults) {
        final price = vehicle['pricing']?['daily']?['vehicleOnly']?['price'];
        if (price != null && price is num) {
          if (price < minPrice) minPrice = price.toDouble();
          if (price > maxPrice) maxPrice = price.toDouble();
        }
      }

      // Set the widest possible range based on data
      if (minPrice == double.infinity) minPrice = 0;
      maxPrice = maxPrice > 0 ? maxPrice + 5000 : 50000;
      if (maxPrice > 50000) maxPrice = 50000;

      setState(() {
        _priceRange = RangeValues(minPrice, maxPrice);
      });
    } else {
      _priceRange = RangeValues(0, 50000);
    }
  }

  // Update the _applyFilters method to not set a default sort option
  void _applyFilters() {
    // Start with a fresh copy of the initial results
    List<Map<String, dynamic>> results = List.from(widget.initialResults);
    print("Initial results count: ${results.length}");

    // Apply price range filter
    results = results.where((vehicle) {
      final price = vehicle['pricing']?['daily']?['vehicleOnly']?['price'];
      if (price == null) return false;

      // Handle both num and String price values
      double numPrice;
      if (price is num) {
        numPrice = price.toDouble();
      } else if (price is String) {
        numPrice = double.tryParse(price) ?? 0.0;
      } else {
        return false;
      }

      return numPrice >= _priceRange.start && numPrice <= _priceRange.end;
    }).toList();
    print("After price filter: ${results.length}");

    // Apply rent mode filter
    if (_selectedRentModes.isNotEmpty) {
      results = results.where((vehicle) {
        final rentMode = vehicle['rentalConditions']?['rentMode'];
        if (rentMode == null) return false;

        // Handle special cases in rental modes
        String normalizedRentMode = rentMode.toString().trim();

        // For "With or Without Driver" match either "With Driver" or "Vehicle Only"
        if (normalizedRentMode == 'With or Without Driver') {
          return _selectedRentModes
              .any((mode) => mode == 'With Driver' || mode == 'Vehicle Only');
        }

        // For "Vehicle Only" also match "Self Drive" if it's in the selected modes
        if (normalizedRentMode == 'Vehicle Only' &&
            _selectedRentModes.contains('Self Drive')) {
          return true;
        }

        // For "Self Drive" also match "Vehicle Only" if it's in the selected modes
        if (normalizedRentMode == 'Self Drive' &&
            _selectedRentModes.contains('Vehicle Only')) {
          return true;
        }

        return _selectedRentModes.contains(normalizedRentMode);
      }).toList();
      print("After rentMode filter: ${results.length}");
    }

    // Apply fuel type filter with case-insensitive comparison
    if (_selectedFuelTypes.isNotEmpty) {
      results = results.where((vehicle) {
        final fuelType = vehicle['fuelType'];
        if (fuelType == null) return false;

        final normalizedFuelType = fuelType.toString().trim();

        return _selectedFuelTypes.any(
            (type) => type.toLowerCase() == normalizedFuelType.toLowerCase());
      }).toList();
      print("After fuelType filter: ${results.length}");
    }

    // Apply transmission filter with case-insensitive comparison
    if (_selectedTransmissionTypes.isNotEmpty) {
      results = results.where((vehicle) {
        final transmission = vehicle['transmission'];
        if (transmission == null) return false;

        final normalizedTransmission = transmission.toString().trim();

        return _selectedTransmissionTypes.any((type) =>
            type.toLowerCase() == normalizedTransmission.toLowerCase());
      }).toList();
      print("After transmission filter: ${results.length}");
    }

    // Apply features filter - only include vehicles that have ALL selected features
    if (_selectedFeatures.isNotEmpty) {
      results = results.where((vehicle) {
        final features =
            vehicle['extras']?['features'] as Map<String, dynamic>?;
        if (features == null) return false;

        // Check if vehicle has all selected features
        for (var feature in _selectedFeatures) {
          bool featureFound = false;

          // Check exact match first
          if (features[feature] == true) {
            featureFound = true;
          } else {
            // Try case-insensitive matches for feature keys
            for (var key in features.keys) {
              if (key.toString().toLowerCase() == feature.toLowerCase() &&
                  features[key] == true) {
                featureFound = true;
                break;
              }
            }
          }

          if (!featureFound) return false;
        }
        return true;
      }).toList();
      print("After features filter: ${results.length}");
    }

    // Only apply sort if a sort option is explicitly selected
    if (_selectedSortOption.isNotEmpty) {
      _sortResults(results);
    }

    // Update state with filtered results
    setState(() {
      _filteredResults = results;
    });
    print("Final filtered results: ${_filteredResults.length}");
  }

  // Update the sort method to handle different data types
  void _sortResults(List<Map<String, dynamic>> results) {
    switch (_selectedSortOption) {
      case 'price_low_to_high':
        results.sort((a, b) {
          final aPrice = _extractNumericPrice(
              a['pricing']?['daily']?['vehicleOnly']?['price']);
          final bPrice = _extractNumericPrice(
              b['pricing']?['daily']?['vehicleOnly']?['price']);
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'price_high_to_low':
        results.sort((a, b) {
          final aPrice = _extractNumericPrice(
              a['pricing']?['daily']?['vehicleOnly']?['price']);
          final bPrice = _extractNumericPrice(
              b['pricing']?['daily']?['vehicleOnly']?['price']);
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
          final aRating = _extractNumericRating(a['rating']);
          final bRating = _extractNumericRating(b['rating']);
          return bRating.compareTo(aRating);
        });
        break;
    }
  }

  // Add helper methods to safely extract numeric values
  double _extractNumericPrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  double _extractNumericRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is num) return rating.toDouble();
    if (rating is String) {
      return double.tryParse(rating) ?? 0.0;
    }
    return 0.0;
  }

  void _toggleFeature(String feature) {
    setState(() {
      if (_selectedFeatures.contains(feature)) {
        _selectedFeatures.remove(feature);
      } else {
        _selectedFeatures.add(feature);
      }
    });
  }

  void _toggleFuelType(String fuelType) {
    setState(() {
      if (_selectedFuelTypes.contains(fuelType)) {
        _selectedFuelTypes.remove(fuelType);
      } else {
        _selectedFuelTypes.add(fuelType);
      }
    });
  }

  void _toggleTransmissionType(String transmissionType) {
    setState(() {
      if (_selectedTransmissionTypes.contains(transmissionType)) {
        _selectedTransmissionTypes.remove(transmissionType);
      } else {
        _selectedTransmissionTypes.add(transmissionType);
      }
    });
  }

  void _toggleRentMode(String rentMode) {
    setState(() {
      if (_selectedRentModes.contains(rentMode)) {
        _selectedRentModes.remove(rentMode);
      } else {
        _selectedRentModes.add(rentMode);
      }
    });
  }

  void _updatePriceRange(RangeValues values) {
    setState(() {
      _priceRange = values;
    });
  }

  void _changeSortOption(String option) {
    setState(() {
      _selectedSortOption = option;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedFeatures = {};
      _selectedFuelTypes = {};
      _selectedTransmissionTypes = {};
      _selectedRentModes = {};

      // Reset price range to the initial range
      if (widget.initialResults.isNotEmpty) {
        double minPrice = double.infinity;
        double maxPrice = 0;

        for (var vehicle in widget.initialResults) {
          final price = vehicle['pricing']?['daily']?['vehicleOnly']?['price'];
          if (price != null && price is num) {
            if (price < minPrice) minPrice = price.toDouble();
            if (price > maxPrice) maxPrice = price.toDouble();
          }
        }

        maxPrice = maxPrice + 5000;
        if (maxPrice > 50000) maxPrice = 50000;
        if (minPrice == double.infinity) minPrice = 0;

        _priceRange = RangeValues(minPrice, maxPrice);
      } else {
        _priceRange = RangeValues(0, 50000);
      }

      _filteredResults = List.from(widget.initialResults);
    });
  }

  // Update the Widget build method for consistent colors
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Container(
      width: screenSize.width * 0.85,
      height: screenSize.height,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.neutralDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Keep consistent with Refine Search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort options
                  _buildSectionHeader('Sort By', isDarkMode),
                  const SizedBox(height: 12),
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

                  const SizedBox(height: 24),

                  // Price range
                  _buildSectionHeader('Price Range (LKR per day)', isDarkMode),
                  const SizedBox(height: 12),
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

                  const SizedBox(height: 24),

                  // Rent mode section
                  _buildSectionHeader('Rent Mode', isDarkMode),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                          'Vehicle Only', _selectedRentModes, _toggleRentMode),
                      _buildFilterChip(
                          'With Driver', _selectedRentModes, _toggleRentMode),
                      _buildFilterChip(
                          'Self Drive', _selectedRentModes, _toggleRentMode),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Fuel type section
                  _buildSectionHeader('Fuel Type', isDarkMode),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                          'Petrol', _selectedFuelTypes, _toggleFuelType),
                      _buildFilterChip(
                          'Diesel', _selectedFuelTypes, _toggleFuelType),
                      _buildFilterChip(
                          'Electric', _selectedFuelTypes, _toggleFuelType),
                      _buildFilterChip(
                          'Hybrid', _selectedFuelTypes, _toggleFuelType),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Transmission section
                  _buildSectionHeader('Transmission', isDarkMode),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Automatic', _selectedTransmissionTypes,
                          _toggleTransmissionType),
                      _buildFilterChip('Manual', _selectedTransmissionTypes,
                          _toggleTransmissionType),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Features section
                  _buildSectionHeader('Features', isDarkMode),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonFeatures
                        .map((feature) => _buildFilterChip(
                            feature, _selectedFeatures, _toggleFeature))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                // Close button
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Apply button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filters
                      _applyFilters();

                      // Pass filtered results and all filter state back to parent
                      widget.onFiltersApplied(
                          _filteredResults,
                          _selectedSortOption,
                          _priceRange,
                          _selectedFeatures,
                          _selectedFuelTypes,
                          _selectedTransmissionTypes,
                          _selectedRentModes);

                      // Close the drawer
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'APPLY FILTERS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  // Add helper method for section headers to match Refine Search
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  // Update sort option styling to match Refine Search
  Widget _buildSortOption(String value, String label) {
    final isSelected = _selectedSortOption == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _changeSortOption(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDarkMode
                    ? Colors.white70
                    : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Update filter chip styling to match Refine Search
  Widget _buildFilterChip(
      String label, Set<String> selectedItems, Function(String) onToggle) {
    final isSelected = selectedItems.contains(label);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.primary
              : isDarkMode
                  ? Colors.white
                  : Colors.black87,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      onSelected: (_) => onToggle(label),
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      backgroundColor: isDarkMode
          ? AppColors.neutralDark.withOpacity(0.7)
          : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}
