import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/form_data_constants.dart';
import '../utils/app_colors.dart';

class RefineSearch extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final String location;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool flexibleDates;
  final Function(Set<String>, String, DateTime, TimeOfDay, DateTime, TimeOfDay,
      bool, String?, String?) onApplyFilters;

  const RefineSearch({
    super.key,
    required this.selectedVehicleTypes,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.flexibleDates,
    required this.onApplyFilters,
  });

  @override
  _RefineSearchState createState() => _RefineSearchState();
}

class _RefineSearchState extends State<RefineSearch> {
  late Set<String> _selectedVehicles;
  late TextEditingController _locationController;
  late DateTime _pickupDate;
  late TimeOfDay _pickupTime;
  late DateTime _returnDate;
  late TimeOfDay _returnTime;
  late bool _flexibleDates;

  // Added for brand and model filtering
  String? _selectedVehicleType;
  String? _selectedMake;
  String? _selectedModel;

  // Vehicle types available for selection
  final List<String> _vehicleTypes = ['Car', 'Three-Wheeler', 'Bike'];

  // Popular Sri Lankan coastal destinations
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

  @override
  void initState() {
    super.initState();
    // Initialize with the passed values
    _selectedVehicles = Set.from(widget.selectedVehicleTypes);
    _locationController = TextEditingController(text: widget.location);
    _pickupDate = widget.pickupDate;
    _pickupTime = widget.pickupTime;
    _returnDate = widget.returnDate;
    _returnTime = widget.returnTime;
    _flexibleDates = widget.flexibleDates;

    // Set the selected vehicle type if only one is selected
    if (_selectedVehicles.length == 1) {
      _selectedVehicleType = _selectedVehicles.first;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _toggleVehicleSelection(String type) {
    setState(() {
      if (_selectedVehicles.contains(type)) {
        _selectedVehicles.remove(type);
        if (type == _selectedVehicleType) {
          _selectedVehicleType = null;
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

  void _selectVehicleType(String? type) {
    if (type != null) {
      setState(() {
        _selectedVehicleType = type;
        _selectedMake = null;
        _selectedModel = null;

        // Ensure this vehicle type is in the selected vehicles
        if (!_selectedVehicles.contains(type)) {
          _selectedVehicles.add(type);
        }
      });
    }
  }

  void _selectMake(String? make) {
    setState(() {
      _selectedMake = make;
      _selectedModel = null;
    });
  }

  void _selectModel(String? model) {
    setState(() {
      _selectedModel = model;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup ? _pickupDate : _returnDate,
      firstDate: isPickup ? DateTime.now() : _pickupDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          // If return date is before the newly selected pickup date, adjust it
          if (_returnDate.isBefore(picked)) {
            _returnDate = picked.add(const Duration(days: 7));
          }
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

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.period == DayPeriod.pm ? 'pm' : 'am'}';
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double drawerWidth = screenSize.width * 0.8;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: drawerWidth,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.neutralDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and decorative element
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                          'Refine Search',
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

              // Scrollable content area with enhanced styling
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    const SizedBox(height: 20),

                    // Vehicle type section with enhanced styling
                    _buildSectionHeader('Vehicle Type', isDarkMode),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 8.0,
                      children: _vehicleTypes.map((type) {
                        final isSelected = _selectedVehicles.contains(type);
                        return GestureDetector(
                          onTap: () => _toggleVehicleSelection(type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : isDarkMode
                                      ? AppColors.neutralDark.withOpacity(0.7)
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.2),
                                        blurRadius: 4.0,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : isDarkMode
                                              ? Colors.grey[400]!
                                              : Colors.grey[400]!,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Make/Brand section with enhanced styling
                    if (_selectedVehicleType != null) ...[
                      _buildSectionHeader('Make/Brand', isDarkMode),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        value: _selectedMake,
                        hint: 'Select make/brand',
                        items: VehicleFormConstants
                                .makesMap[_selectedVehicleType]
                                ?.map((make) => DropdownMenuItem<String>(
                                    value: make, child: Text(make)))
                                .toList() ??
                            [],
                        onChanged: _selectMake,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Model section with enhanced styling
                    if (_selectedVehicleType != null &&
                        _selectedMake != null) ...[
                      _buildSectionHeader('Model', isDarkMode),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        value: _selectedModel,
                        hint: 'Select model',
                        items: VehicleFormConstants
                                .modelsMap[_selectedVehicleType]?[_selectedMake]
                                ?.map((model) => DropdownMenuItem<String>(
                                    value: model, child: Text(model)))
                                .toList() ??
                            [],
                        onChanged: _selectModel,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Location section with enhanced styling
                    _buildSectionHeader('Location', isDarkMode),
                    const SizedBox(height: 8),
                    _buildAutocompleteField(
                      drawerWidth: drawerWidth,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 24),

                    // Dates section with enhanced styling
                    _buildSectionHeader('Dates', isDarkMode),
                    const SizedBox(height: 12),

                    // Pickup date & time with enhanced styling
                    _buildDateTimeRow(
                      label: 'Pick up:',
                      date: _pickupDate,
                      time: _pickupTime,
                      onDateTap: () => _selectDate(context, true),
                      onTimeTap: () => _selectTime(context, true),
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 12),

                    // Return date & time with enhanced styling
                    _buildDateTimeRow(
                      label: 'Return:',
                      date: _returnDate,
                      time: _returnTime,
                      onDateTap: () => _selectDate(context, false),
                      onTimeTap: () => _selectTime(context, false),
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 16),

                    // Flexible dates option with enhanced styling
                    _buildCheckboxOption(
                      label: 'My dates are flexible',
                      isSelected: _flexibleDates,
                      onToggle: () {
                        setState(() {
                          _flexibleDates = !_flexibleDates;
                        });
                      },
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom action buttons with enhanced styling
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

                    // Search button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedVehicles.isNotEmpty
                            ? () {
                                widget.onApplyFilters(
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
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade400,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'SEARCH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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
      ),
    );
  }

  // Helper methods to build UI components
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

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required double drawerWidth,
    required bool isDarkMode,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return _popularLocations;
        }
        return _popularLocations.where((location) => location
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        setState(() {
          _locationController.text = selection;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.text = _locationController.text;

        controller.addListener(() {
          if (_locationController.text != controller.text) {
            _locationController.text = controller.text;
          }
        });

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Select or type destination',
              hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[500]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              suffixIcon: Icon(Icons.search,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: drawerWidth - 32,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                    hoverColor:
                        isDarkMode ? Colors.grey[700] : Colors.grey[100],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTimeRow({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _formatDate(date),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onTimeTap,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(time),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption({
    required String label,
    required bool isSelected,
    required VoidCallback onToggle,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey,
                  width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
