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

  String? _selectedVehicleType;
  String? _selectedMake;
  String? _selectedModel;

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

  @override
  void initState() {
    super.initState();
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
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dateTime);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double drawerWidth = (screenSize.width * 0.8).clamp(300.0, 400.0);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: drawerWidth,
      child: Container(
        height: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top,
        child: Column(
          children: [
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
                    'Refine Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: true,
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    children: [
                      _buildSectionHeader('Vehicle Type', isDarkMode),
                      const SizedBox(height: 10),
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
                                    : (isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDarkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[300]!),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[500]),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDarkMode
                                              ? Colors.white
                                              : Colors.black87),
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
                      const SizedBox(height: 20),
                      _buildSectionHeader('Location', isDarkMode),
                      const SizedBox(height: 8),
                      _buildAutocompleteField(
                          drawerWidth: drawerWidth, isDarkMode: isDarkMode),
                      const SizedBox(height: 20),
                      _buildSectionHeader('From', isDarkMode),
                      const SizedBox(height: 8),
                      _buildDateTimeRow(
                        label: '',
                        date: _pickupDate,
                        time: _pickupTime,
                        onDateTap: () => _selectDate(context, true),
                        onTimeTap: () => _selectTime(context, true),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('To', isDarkMode),
                      const SizedBox(height: 8),
                      _buildDateTimeRow(
                        label: '',
                        date: _returnDate,
                        time: _returnTime,
                        onDateTap: () => _selectDate(context, false),
                        onTimeTap: () => _selectTime(context, false),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('Flexible Dates', isDarkMode),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text(
                          'Allow flexible dates',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _flexibleDates,
                        onChanged: (value) {
                          setState(() {
                            _flexibleDates = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('Make', isDarkMode),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        value: _selectedMake,
                        hint: 'All',
                        items: _selectedVehicleType != null
                            ? (VehicleFormConstants
                                        .makesMap[_selectedVehicleType] ??
                                    [])
                                .map((make) => DropdownMenuItem<String>(
                                      value: make,
                                      child: Text(make),
                                    ))
                                .toList()
                            : [
                                const DropdownMenuItem<String>(
                                    value: null, child: Text('All'))
                              ],
                        onChanged:
                            _selectedVehicleType != null ? _selectMake : null,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('Model', isDarkMode),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        value: _selectedModel,
                        hint: 'All',
                        items: _selectedVehicleType != null &&
                                _selectedMake != null
                            ? (VehicleFormConstants
                                            .modelsMap[_selectedVehicleType]
                                        ?[_selectedMake] ??
                                    [])
                                .map((model) => DropdownMenuItem<String>(
                                      value: model,
                                      child: Text(model),
                                    ))
                                .toList()
                            : [
                                const DropdownMenuItem<String>(
                                    value: null, child: Text('All'))
                              ],
                        onChanged: _selectedMake != null ? _selectModel : null,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: const [
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
                      child: const Text('CLOSE',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                          : () {
                              _showErrorSnackBar(
                                  'Please select at least one vehicle type.');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('SEARCH',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
    required Function(String?)? onChanged,
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
          hint: Text(
            hint,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          items: items,
          onChanged: onChanged,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
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
        if (textEditingValue.text.isEmpty) {
          return _popularLocations;
        }
        return _popularLocations.where((location) => location
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _locationController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: _locationController,
            focusNode: focusNode,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Select or type destination',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              suffixIcon: Icon(
                Icons.search,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
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
}
