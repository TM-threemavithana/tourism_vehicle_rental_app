import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/form_data_constants.dart';

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
    Key? key,
    required this.selectedVehicleTypes,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.flexibleDates,
    required this.onApplyFilters,
  }) : super(key: key);

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

    // Set drawer width to 80% of screen width
    final double drawerWidth = screenSize.width * 0.8;

    return Drawer(
      width: drawerWidth,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  'Refine Search',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const Divider(),

              // Scrollable content area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    const SizedBox(height: 16),

                    // Vehicle type selection
                    Text(
                      'Vehicle Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10.0,
                      runSpacing: 8.0,
                      children: _vehicleTypes.map((type) {
                        final isSelected = _selectedVehicles.contains(type);
                        return GestureDetector(
                          onTap: () => _toggleVehicleSelection(type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
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
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
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

                    // Vehicle Make/Brand selection (when a vehicle type is selected)
                    if (_selectedVehicleType != null) ...[
                      Text(
                        'Make/Brand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedMake,
                            hint: Text('Select make/brand'),
                            items: VehicleFormConstants
                                    .makesMap[_selectedVehicleType]
                                    ?.map((make) => DropdownMenuItem<String>(
                                        value: make, child: Text(make)))
                                    .toList() ??
                                [],
                            onChanged: _selectMake,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Vehicle Model selection (when a make is selected)
                    if (_selectedVehicleType != null &&
                        _selectedMake != null) ...[
                      Text(
                        'Model',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedModel,
                            hint: Text('Select model'),
                            items: VehicleFormConstants
                                    .modelsMap[_selectedVehicleType]
                                        ?[_selectedMake]
                                    ?.map((model) => DropdownMenuItem<String>(
                                        value: model, child: Text(model)))
                                    .toList() ??
                                [],
                            onChanged: _selectModel,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Location search field
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Autocomplete<String>(
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
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        controller.text = _locationController.text;

                        controller.addListener(() {
                          if (_locationController.text != controller.text) {
                            _locationController.text = controller.text;
                          }
                        });

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Select or type destination',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                              suffixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
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
                                    title: Text(option),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Date section
                    Text(
                      'Dates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pickup date & time
                    Row(
                      children: [
                        const Text(
                          'Pick up:',
                          style: TextStyle(
                            color: Colors.black87,
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
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _formatDate(_pickupDate),
                                        style: TextStyle(
                                          color: Colors.black87,
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
                                  onTap: () => _selectTime(context, true),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _formatTime(_pickupTime),
                                        style: TextStyle(
                                          color: Colors.black87,
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
                    ),

                    const SizedBox(height: 12),

                    // Return date & time
                    Row(
                      children: [
                        const Text(
                          'Return:  ',
                          style: TextStyle(
                            color: Colors.black87,
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
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _formatDate(_returnDate),
                                        style: TextStyle(
                                          color: Colors.black87,
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
                                  onTap: () => _selectTime(context, false),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _formatTime(_returnTime),
                                        style: TextStyle(
                                          color: Colors.black87,
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
                    ),

                    const SizedBox(height: 16),

                    // Flexible dates option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _flexibleDates = !_flexibleDates;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _flexibleDates
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _flexibleDates
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'My dates are flexible',
                            style:
                                TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom action buttons
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 5,
                      spreadRadius: 0,
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text('CLOSE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedVehicles.isNotEmpty
                            ? () {
                                // Only call the callback - no additional Navigator.pop needed here
                                // as we're handling it in the _applyFilters method
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
}
