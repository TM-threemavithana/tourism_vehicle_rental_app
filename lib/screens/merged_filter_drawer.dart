import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class MergedFilterDrawer extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final String location;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool flexibleDates;
  final String? make;
  final String? model;
  final List<Map<String, dynamic>> initialResults;
  final Function(Set<String>, String, DateTime, TimeOfDay, DateTime, TimeOfDay,
      bool, String?, String?) onApplySearch;
  final Function(List<Map<String, dynamic>>, String, RangeValues, Set<String>,
      Set<String>, Set<String>, Set<String>) onApplyFilters;

  const MergedFilterDrawer({
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
    required this.initialResults,
    required this.onApplySearch,
    required this.onApplyFilters,
  });

  @override
  _MergedFilterDrawerState createState() => _MergedFilterDrawerState();
}

class _MergedFilterDrawerState extends State<MergedFilterDrawer> {
  // Search parameters
  late Set<String> _selectedVehicles;
  late TextEditingController _locationController;
  late DateTime _pickupDate;
  late TimeOfDay _pickupTime;
  late DateTime _returnDate;
  late TimeOfDay _returnTime;
  late bool _flexibleDates;
  String? _selectedVehicleType;
  String? _selectedMake;
  String? _selectedModel;

  // Focus node for handling keyboard
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  // Filter parameters
  String _selectedSortOption = '';
  RangeValues _priceRange = const RangeValues(0, 50000);
  double _minPrice = 0;
  double _maxPrice = 50000;
  Set<String> _selectedFeatures = {};
  Set<String> _selectedFuelTypes = {};
  Set<String> _selectedTransmissionTypes = {};
  Set<String> _selectedRentModes = {};

  // Constants
  final List<String> _vehicleTypes = ['Car', 'Three-Wheeler', 'Bike'];
  final List<String> _popularLocations = [
    'Colombo',
    'Galle',
    'Hikkaduwa',
    'Bentota',
    'Mirissa',
    'Unawatuna',
    'Negombo',
    'Trincomalee',
    'Arugam Bay',
    'Batticaloa',
    'Pasikuda',
    'Kalpitiya',
    'Tangalle'
  ];
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
    _initializeParameters();

    // Set up keyboard visibility listener
    _focusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _focusNode.hasFocus;
      });
    });

    // Add listener to handle keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (keyboardVisible != _isKeyboardVisible) {
        setState(() {
          _isKeyboardVisible = keyboardVisible;
        });
      }
    });
  }

  void _initializeParameters() {
    // Initialize search parameters
    _selectedVehicles = Set.from(widget.selectedVehicleTypes);
    _locationController = TextEditingController(text: widget.location);
    _pickupDate = widget.pickupDate;
    _pickupTime = widget.pickupTime;
    _returnDate = widget.returnDate;
    _returnTime = widget.returnTime;
    _flexibleDates = widget.flexibleDates;

    if (_selectedVehicles.length == 1) {
      _selectedVehicleType = _selectedVehicles.first;
    }

    // Always use 0-50000 for price range
    _minPrice = 0;
    _maxPrice = 50000;
    _priceRange = const RangeValues(0, 50000);
  }

  // Removed _setPriceRangeFromData, always use 0-50000

  @override
  void dispose() {
    _locationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double drawerWidth = (screenSize.width * 0.85).clamp(300.0, 400.0);
    // Set isDarkMode based on theme and use it in the UI components
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Update keyboard visibility state
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Stack(
      children: [
        Drawer(
          width: drawerWidth,
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside of text fields
              FocusScope.of(context).unfocus();
            },
            child: Container(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // Header
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
                      left: 20,
                      right: 8,
                      top: MediaQuery.of(context).padding.top + 16,
                      bottom: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Search & Filter',
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
                  // Main content
                  Expanded(
                    child: SafeArea(
                      top: false,
                      bottom: true,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Parameters Section
                            _buildSectionHeader(
                                'Search Parameters', isDarkMode),
                            const SizedBox(height: 16),

                            // Vehicle Types
                            _buildSectionHeader('Vehicle Types', isDarkMode),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _vehicleTypes.map((type) {
                                final isSelected =
                                    _selectedVehicles.contains(type);
                                return GestureDetector(
                                  onTap: () => _toggleVehicleSelection(type),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Location
                            _buildSectionHeader('Location', isDarkMode),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _locationController,
                              focusNode: _focusNode,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () {
                                // Close keyboard when done is pressed
                                _focusNode.unfocus();
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter location',
                                prefixIcon: const Icon(Icons.location_on),
                                suffixIcon: _focusNode.hasFocus
                                    ? IconButton(
                                        icon: const Icon(Icons.keyboard_hide),
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          // Add a small delay and then apply filters
                                          Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {
                                            _applyMergedFilters();
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _popularLocations.map((location) {
                                return GestureDetector(
                                  onTap: () {
                                    _locationController.text = location;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      location,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Dates
                            _buildSectionHeader(
                                'Pickup Date & Time', isDarkMode),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('MMM dd, yyyy')
                                                .format(_pickupDate),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectTime(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            _pickupTime.format(context),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _buildSectionHeader(
                                'Return Date & Time', isDarkMode),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('MMM dd, yyyy')
                                                .format(_returnDate),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectTime(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            _returnTime.format(context),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Filter Results Section
                            _buildSectionHeader('Filter Results', isDarkMode),
                            const SizedBox(height: 16),

                            // Active filters indicator
                            if (_selectedSortOption.isNotEmpty ||
                                _selectedFeatures.isNotEmpty ||
                                _selectedFuelTypes.isNotEmpty ||
                                _selectedTransmissionTypes.isNotEmpty ||
                                _selectedRentModes.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.filter_list,
                                        color: AppColors.primary, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Filters Active',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Sort Options
                            _buildSectionHeader('Sort By', isDarkMode),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSortOption('price_low_to_high',
                                      'Price: Low to High'),
                                  _buildSortOption('price_high_to_low',
                                      'Price: High to Low'),
                                  _buildSortOption(
                                      'newest_first', 'Newest First'),
                                  _buildSortOption('rating', 'Rating'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Price Range
                            _buildSectionHeader('Price Range', isDarkMode),
                            const SizedBox(height: 8),
                            RangeSlider(
                              values: _priceRange,
                              min: _minPrice,
                              max: _maxPrice,
                              divisions: (_maxPrice - _minPrice > 0)
                                  ? ((_maxPrice - _minPrice) ~/ 1000)
                                      .clamp(1, 50)
                                  : 1,
                              labels: RangeLabels(
                                'Rs. ${_priceRange.start.round()}',
                                'Rs. ${_priceRange.end.round()}',
                              ),
                              onChanged: (values) {
                                setState(() {
                                  _priceRange = values;
                                });
                                // Apply filters immediately when price range changes
                                _applyFilters();
                              },
                            ),
                            Text(
                              'Price Range: Rs. ${_priceRange.start.round()} - Rs. ${_priceRange.end.round()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Features
                            _buildSectionHeader('Features', isDarkMode),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _commonFeatures.map((feature) {
                                return _buildFilterChip(
                                  feature,
                                  _selectedFeatures,
                                  _toggleFeature,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Fuel Types
                            _buildSectionHeader('Fuel Type', isDarkMode),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'Petrol',
                                'Diesel',
                                'Electric',
                                'Hybrid'
                              ].map((fuelType) {
                                return _buildFilterChip(
                                  fuelType,
                                  _selectedFuelTypes,
                                  _toggleFuelType,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Transmission
                            _buildSectionHeader('Transmission', isDarkMode),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  ['Manual', 'Automatic'].map((transmission) {
                                return _buildFilterChip(
                                  transmission,
                                  _selectedTransmissionTypes,
                                  _toggleTransmissionType,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Rent Modes
                            _buildSectionHeader('Rent Mode', isDarkMode),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'With Driver',
                                'Vehicle Only',
                                'With or Without Driver'
                              ].map((rentMode) {
                                return _buildFilterChip(
                                  rentMode,
                                  _selectedRentModes,
                                  _toggleRentMode,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _resetAllFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('RESET',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyMergedFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('APPLY',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Done & Apply button
        if (_isKeyboardVisible)
          Positioned(
            bottom: 80, // Adjust this value to position the button
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _applyMergedFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'DONE & APPLY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  // Helper methods
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

  Widget _buildSortOption(String value, String label) {
    final isSelected = _selectedSortOption == value;

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
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, Set<String> selectedItems, Function(String) onToggle) {
    final isSelected = selectedItems.contains(label);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      onSelected: (_) => onToggle(label),
      selectedColor: AppColors.primary,
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

  // Event handlers
  void _toggleVehicleSelection(String type) {
    setState(() {
      if (_selectedVehicles.contains(type)) {
        _selectedVehicles.remove(type);
        if (_selectedVehicleType == type) {
          _selectedVehicleType =
              _selectedVehicles.isNotEmpty ? _selectedVehicles.first : null;
          _selectedMake = null;
          _selectedModel = null;
        }
      } else {
        _selectedVehicles.add(type);
        if (_selectedVehicles.length == 1) {
          _selectedVehicleType = type;
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup ? _pickupDate : _returnDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isPickup ? _pickupTime : _returnTime,
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _returnTime = picked;
        }
      });
    }
  }

  void _changeSortOption(String option) {
    setState(() {
      _selectedSortOption = option;
    });
    // Apply filters immediately when sort option changes
    _applyFilters();
  }

  void _toggleFeature(String feature) {
    setState(() {
      if (_selectedFeatures.contains(feature)) {
        _selectedFeatures.remove(feature);
      } else {
        _selectedFeatures.add(feature);
      }
    });
    // Apply filters immediately when features change
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
    // Apply filters immediately when fuel type changes
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
    // Apply filters immediately when transmission changes
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
    // Apply filters immediately when rent mode changes
    _applyFilters();
  }

  void _applyFilters() {
    // Apply all filters to the current results
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

    // Apply rent mode filter
    if (_selectedRentModes.isNotEmpty) {
      results = results.where((vehicle) {
        final rentMode = vehicle['rentalConditions']?['rentMode'];
        if (rentMode == null) return false;
        String normalizedRentMode = rentMode.toString().trim();
        if (_selectedRentModes.contains('With or Without Driver')) {
          if (normalizedRentMode == 'With Driver' ||
              normalizedRentMode == 'Vehicle Only') {
            return true;
          }
        }
        return _selectedRentModes.contains(normalizedRentMode);
      }).toList();
    }

    // Apply fuel type filter
    if (_selectedFuelTypes.isNotEmpty) {
      results = results.where((vehicle) {
        final fuelType = vehicle['fuelType'];
        if (fuelType == null) return false;
        String normalizedFuelType = fuelType.toString().trim();
        return _selectedFuelTypes.contains(normalizedFuelType);
      }).toList();
    }

    // Apply transmission filter
    if (_selectedTransmissionTypes.isNotEmpty) {
      results = results.where((vehicle) {
        final transmission = vehicle['transmission'];
        if (transmission == null) return false;
        String normalizedTransmission = transmission.toString().trim();
        return _selectedTransmissionTypes.contains(normalizedTransmission);
      }).toList();
    }

    // Apply features filter
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

    // Pass filtered results back to parent
    widget.onApplyFilters(
      results,
      _selectedSortOption,
      _priceRange,
      _selectedFeatures,
      _selectedFuelTypes,
      _selectedTransmissionTypes,
      _selectedRentModes,
    );
  }

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

  void _resetAllFilters() {
    setState(() {
      // Reset filter parameters
      _selectedFeatures = {};
      _selectedFuelTypes = {};
      _selectedTransmissionTypes = {};
      _selectedRentModes = {};
      _selectedSortOption = '';

      // Reset search parameters to original values
      _selectedVehicles = Set.from(widget.selectedVehicleTypes);
      _locationController.text = widget.location;
      _pickupDate = widget.pickupDate;
      _pickupTime = widget.pickupTime;
      _returnDate = widget.returnDate;
      _returnTime = widget.returnTime;
      _flexibleDates = widget.flexibleDates;
      _selectedVehicleType = null;
      _selectedMake = null;
      _selectedModel = null;
    });

    // Reset price range
    if (widget.initialResults.isNotEmpty) {
      _minPrice = 0;
      _maxPrice = 50000;
      _priceRange = const RangeValues(0, 50000);
    } else {
      _minPrice = 0;
      _maxPrice = 50000;
      _priceRange = const RangeValues(0, 50000);
    }

    // Apply reset filters to show all results
    _applyFilters();
  }

  void _applyMergedFilters() {
    // Always apply current filters first
    _applyFilters();

    // Check if search parameters have changed
    bool searchParamsChanged =
        _selectedVehicles.length != widget.selectedVehicleTypes.length ||
            !_selectedVehicles
                .every((type) => widget.selectedVehicleTypes.contains(type)) ||
            _locationController.text != widget.location ||
            _pickupDate != widget.pickupDate ||
            _pickupTime != widget.pickupTime ||
            _returnDate != widget.returnDate ||
            _returnTime != widget.returnTime ||
            _flexibleDates != widget.flexibleDates ||
            _selectedMake != widget.make ||
            _selectedModel != widget.model;

    // Close the drawer first
    Navigator.pop(context);

    // Only perform new search if search parameters have actually changed
    if (searchParamsChanged) {
      // Use a small delay to ensure the drawer is closed before navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onApplySearch(
          _selectedVehicles,
          _locationController.text,
          _pickupDate,
          _pickupTime,
          _returnDate,
          _returnTime,
          _flexibleDates,
          _selectedMake,
          _selectedModel,
        );
      });
    }
  }
}
