import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/form_data_constants.dart';

class FilterResultsDrawer extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final List<Map<String, dynamic>> initialResults;
  final Function(List<Map<String, dynamic>>) onFiltersApplied;

  const FilterResultsDrawer({
    Key? key,
    required this.selectedVehicleTypes,
    required this.initialResults,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  _FilterResultsDrawerState createState() => _FilterResultsDrawerState();
}

class _FilterResultsDrawerState extends State<FilterResultsDrawer> {
  // Filter state variables
  String _selectedSortOption = 'price_low_to_high';
  RangeValues _priceRange = RangeValues(0, 50000);
  Set<String> _selectedFeatures = {};
  Set<String> _selectedFuelTypes = {};
  Set<String> _selectedTransmissionTypes = {};
  Set<String> _selectedRentModes = {};
  List<Map<String, dynamic>> _filteredResults = [];

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

    // Initialize all filter sets as empty (no default selections)
    _selectedFeatures = {};
    _selectedFuelTypes = {};
    _selectedTransmissionTypes = {};
    _selectedRentModes = {};

    // Don't set a default sort option
    _selectedSortOption = '';

    // Initialize filtered results with the initial results (no filtering)
    _filteredResults = List.from(widget.initialResults);

    // Set price range based on actual data, but don't make it a "selected" filter
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

  void _applyFilters() {
    List<Map<String, dynamic>> results = List.from(widget.initialResults);

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
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final drawerWidth = MediaQuery.of(context).size.width * 0.85;

    return Drawer(
      width: drawerWidth,
      child: Container(
        color: isDarkMode ? AppColors.neutralDark : Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              color: isDarkMode ? Colors.black : AppColors.primary,
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
                    onPressed: () => Navigator.pop(context),
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
                        _buildFilterChip('Vehicle Only', _selectedRentModes,
                            _toggleRentMode),
                        _buildFilterChip(
                            'With Driver', _selectedRentModes, _toggleRentMode),
                        _buildFilterChip(
                            'Self Drive', _selectedRentModes, _toggleRentMode),
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
                        _buildFilterChip(
                            'Automatic',
                            _selectedTransmissionTypes,
                            _toggleTransmissionType),
                        _buildFilterChip('Manual', _selectedTransmissionTypes,
                            _toggleTransmissionType),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      child: const Text('CLOSE'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Apply button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        // Pass filtered results back to parent
                        widget.onFiltersApplied(_filteredResults);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'APPLY FILTERS',
                        style: TextStyle(
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

  Widget _buildFilterChip(
      String label, Set<String> selectedItems, Function(String) onToggle) {
    final isSelected = selectedItems.contains(label);
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onToggle(label),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}
