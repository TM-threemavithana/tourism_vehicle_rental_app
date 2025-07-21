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
    // Start with a fresh copy of all initial results
    List<Map<String, dynamic>> results = List.from(widget.initialResults);

    // Apply price range filter
    results = results.where((vehicle) {
      final price = vehicle['pricing']?['daily']?['vehicleOnly']?['price'];
      if (price == null) return false;

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

    // Only apply rent mode filter if modes are selected
    if (_selectedRentModes.isNotEmpty) {
      results = results.where((vehicle) {
        final rentMode = vehicle['rentalConditions']?['rentMode'];
        if (rentMode == null) return false;

        String normalizedRentMode = rentMode.toString().trim();

        // Special logic for "With or Without Driver"
        if (_selectedRentModes.contains('With or Without Driver')) {
          if (normalizedRentMode == 'With Driver' ||
              normalizedRentMode == 'Vehicle Only') {
            return true;
          }
        }

        return _selectedRentModes.contains(normalizedRentMode);
      }).toList();
    }

    if (_selectedFuelTypes.isNotEmpty) {
      results = results.where((vehicle) {
        final fuelType = vehicle['fuelType'];
        if (fuelType == null) return false;
        String normalizedFuelType = fuelType.toString().trim();
        return _selectedFuelTypes.contains(normalizedFuelType);
      }).toList();
    }

    if (_selectedTransmissionTypes.isNotEmpty) {
      results = results.where((vehicle) {
        final transmission = vehicle['transmission'];
        if (transmission == null) return false;
        String normalizedTransmission = transmission.toString().trim();
        return _selectedTransmissionTypes.contains(normalizedTransmission);
      }).toList();
    }

    if (_selectedFeatures.isNotEmpty) {
      results = results.where((vehicle) {
        final features =
            vehicle['extras']?['features'] as Map<String, dynamic>?;
        if (features == null) return false;

        for (var feature in _selectedFeatures) {
          bool featureFound = false;

          if (features[feature] == true) {
            featureFound = true;
          } else {
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
    }

    // Sort results if a sort option is selected
    if (_selectedSortOption.isNotEmpty) {
      _sortResults(results);
    }

    // Update filtered results
    setState(() {
      _filteredResults = results;
    });
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

  void _toggleRentMode(String rentMode) {
    setState(() {
      if (_selectedRentModes.contains(rentMode)) {
        _selectedRentModes.remove(rentMode);
      } else {
        _selectedRentModes.add(rentMode);
      }
      _applyFilters(); // Apply filters after toggling
    });
  }

  void _toggleFeature(String feature) {
    setState(() {
      if (_selectedFeatures.contains(feature)) {
        _selectedFeatures.remove(feature);
      } else {
        _selectedFeatures.add(feature);
      }
      _applyFilters(); // Apply filters after toggling
    });
  }

  void _toggleFuelType(String fuelType) {
    setState(() {
      if (_selectedFuelTypes.contains(fuelType)) {
        _selectedFuelTypes.remove(fuelType);
      } else {
        _selectedFuelTypes.add(fuelType);
      }
      _applyFilters(); // Apply filters after toggling
    });
  }

  void _toggleTransmissionType(String transmissionType) {
    setState(() {
      if (_selectedTransmissionTypes.contains(transmissionType)) {
        _selectedTransmissionTypes.remove(transmissionType);
      } else {
        _selectedTransmissionTypes.add(transmissionType);
      }
      _applyFilters(); // Apply filters after toggling
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
      _applyFilters();
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
        _setPriceRangeFromData();
      } else {
        _priceRange = const RangeValues(0, 50000);
      }

      // Clear sort option
      _selectedSortOption = '';

      // Apply filters to update results
      _applyFilters();

      // Immediately pass the updated results back to the parent screen
      widget.onFiltersApplied(
        _filteredResults,
        _selectedSortOption,
        _priceRange,
        _selectedFeatures,
        _selectedFuelTypes,
        _selectedTransmissionTypes,
        _selectedRentModes,
      );
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
      height: screenSize.height - MediaQuery.of(context).padding.top,
      child: Column(
        children: [
            // Header - match Refine Search
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20, right: 8, top: MediaQuery.of(context).padding.top + 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Results',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
            ),
            // Main filter content in a white card with rounded top corners
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                            _buildSortOption('price_low_to_high', 'Price: Low to High'),
                            _buildSortOption('price_high_to_low', 'Price: High to Low'),
                            _buildSortOption('newest_first', 'Newest First'),
                            _buildSortOption('rating', 'Highest Rated'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Price Range (LKR per day)', isDarkMode),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'LKR ${_priceRange.start.round()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
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
                              onChangeEnd: (values) {
                                _applyFilters();
                              },
                            ),
                          ),
                          Text(
                            'LKR ${_priceRange.end.round()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Rent Mode', isDarkMode),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip('With Driver', _selectedRentModes, _toggleRentMode),
                          _buildFilterChip('With or Without Driver', _selectedRentModes, _toggleRentMode),
                          _buildFilterChip('Vehicle Only', _selectedRentModes, _toggleRentMode),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Fuel Type', isDarkMode),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip('Petrol', _selectedFuelTypes, _toggleFuelType),
                          _buildFilterChip('Diesel', _selectedFuelTypes, _toggleFuelType),
                          _buildFilterChip('Electric', _selectedFuelTypes, _toggleFuelType),
                          _buildFilterChip('Hybrid', _selectedFuelTypes, _toggleFuelType),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Transmission', isDarkMode),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip('Automatic', _selectedTransmissionTypes, _toggleTransmissionType),
                          _buildFilterChip('Manual', _selectedTransmissionTypes, _toggleTransmissionType),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Features', isDarkMode),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _commonFeatures
                            .map((feature) => _buildFilterChip(feature, _selectedFeatures, _toggleFeature))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyAndReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
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
              : Colors.black87,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      onSelected: (_) => onToggle(label),
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  // When filters are applied, ensure proper results or error message
  void _applyAndReturn() {
    // First apply the current filters
    _applyFilters();

    // Check if filters have been removed/changed and results are empty
    if (_filteredResults.isEmpty) {
      // Pass the filtered results and current filter state back to parent
      widget.onFiltersApplied(
        _filteredResults,
        _selectedSortOption,
        _priceRange,
        _selectedFeatures,
        _selectedFuelTypes,
        _selectedTransmissionTypes,
        _selectedRentModes,
      );

      // Close the filter drawer
      Navigator.pop(context);

      // No need to trigger refine search if using end drawer
      return;
    }

    // Normal case with results
    widget.onFiltersApplied(
      _filteredResults,
      _selectedSortOption,
      _priceRange,
      _selectedFeatures,
      _selectedFuelTypes,
      _selectedTransmissionTypes,
      _selectedRentModes,
    );
    Navigator.pop(context);
  }
}
