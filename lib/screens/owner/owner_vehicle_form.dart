import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cloudinary_service.dart';

class OwnerVehicleForm extends StatefulWidget {
  const OwnerVehicleForm({super.key});

  @override
  State<OwnerVehicleForm> createState() => _OwnerVehicleFormState();
}

class _OwnerVehicleFormState extends State<OwnerVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = false;

  String? _vehicleType;
  final List<String> _vehicleTypes = ['Car', 'Bike', 'Three-Wheeler'];

  // Makes/Brands for different vehicle types
  final Map<String, List<String>> _makesMap = {
    'Car': [
      'Toyota',
      'Honda',
      'Nissan',
      'Suzuki',
      'Mitsubishi',
      'BMW',
      'Mercedes-Benz',
      'Audi',
      'Ford',
      'Other'
    ],
    'Bike': [
      'Honda',
      'Yamaha',
      'Suzuki',
      'Kawasaki',
      'Royal Enfield',
      'Bajaj',
      'TVS',
      'Hero',
      'KTM',
      'Other'
    ],
    'Three-Wheeler': ['Bajaj', 'TVS', 'Piaggio', 'Mahindra', 'Atul', 'Other'],
  };

  // Models for different makes
  final Map<String, Map<String, List<String>>> _modelsMap = {
    'Car': {
      'Toyota': [
        'Corolla',
        'Camry',
        'Prius',
        'RAV4',
        'Land Cruiser',
        'Hilux',
        'Yaris',
        'Other'
      ],
      'Honda': [
        'Civic',
        'Accord',
        'CR-V',
        'City',
        'Jazz',
        'Fit',
        'HR-V',
        'Other'
      ],
      'Nissan': [
        'Sunny',
        'X-Trail',
        'Qashqai',
        'Patrol',
        'Navara',
        'Juke',
        'Other'
      ],
      'Suzuki': [
        'Swift',
        'Alto',
        'Vitara',
        'Jimny',
        'Wagon R',
        'Ertiga',
        'Other'
      ],
      'Mitsubishi': [
        'Outlander',
        'Pajero',
        'Lancer',
        'ASX',
        'Eclipse',
        'Other'
      ],
      'BMW': ['3 Series', '5 Series', '7 Series', 'X1', 'X3', 'X5', 'Other'],
      'Mercedes-Benz': [
        'C-Class',
        'E-Class',
        'S-Class',
        'GLA',
        'GLC',
        'GLE',
        'Other'
      ],
      'Audi': ['A3', 'A4', 'A6', 'Q3', 'Q5', 'Q7', 'Other'],
      'Ford': [
        'Focus',
        'Fiesta',
        'Mustang',
        'Ranger',
        'EcoSport',
        'Explorer',
        'Other'
      ],
      'Other': ['Other']
    },
    'Bike': {
      'Honda': ['CBR', 'CB', 'Hornet', 'Dio', 'Activa', 'Other'],
      'Yamaha': ['YZF', 'FZ', 'MT', 'R15', 'R3', 'Fascino', 'Other'],
      'Suzuki': ['GSX', 'Hayabusa', 'Intruder', 'Access', 'Gixxer', 'Other'],
      'Kawasaki': ['Ninja', 'Z', 'Versys', 'Vulcan', 'Other'],
      'Royal Enfield': ['Classic', 'Bullet', 'Himalayan', 'Meteor', 'Other'],
      'Bajaj': ['Pulsar', 'Dominar', 'Avenger', 'Platina', 'Other'],
      'TVS': ['Apache', 'Jupiter', 'Ntorq', 'Star City', 'Other'],
      'Hero': ['Splendor', 'Passion', 'Glamour', 'Xpulse', 'Other'],
      'KTM': ['Duke', 'RC', 'Adventure', 'Other'],
      'Other': ['Other']
    },
    'Three-Wheeler': {
      'Bajaj': ['RE', 'Maxima', 'Compact', 'Other'],
      'TVS': ['King', 'Auto', 'Other'],
      'Piaggio': ['Ape', 'Other'],
      'Mahindra': ['Alfa', 'Treo', 'Other'],
      'Atul': ['Gem', 'Smart', 'Other'],
      'Other': ['Other']
    }
  };

  // Vehicle categories based on type
  final Map<String, List<String>> _categoriesMap = {
    'Car': ['Budget', 'Compact', 'Full-Size', 'Luxury', 'SUV', 'Van'],
    'Bike': ['Standard', 'Sports', 'Cruiser', 'Touring', 'Scooter', 'Offroad'],
    'Three-Wheeler': ['Passenger', 'Cargo', 'Mixed Use']
  };

  // Year of Manufacture options
  List<String> _yearOptions = [];

  // Transmission options
  final List<String> _transmissionOptions = [
    'Automatic',
    'Manual',
    'Semi-Automatic',
    'CVT'
  ];

  // Fuel type options
  final List<String> _fuelTypeOptions = [
    'Petrol',
    'Diesel',
    'Hybrid',
    'Electric',
    'LPG/CNG'
  ];

  // Color options
  final List<String> _colorOptions = [
    'Black',
    'White',
    'Silver',
    'Gray',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Brown',
    'Purple',
    'Gold',
    'Beige',
    'Other'
  ];

  // Controllers for form fields
  String? _selectedMake;
  String? _selectedModel;
  String? _selectedCategory;
  final TextEditingController _gradeController = TextEditingController();
  String? _selectedYear;
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _chassisNoController = TextEditingController();
  final TextEditingController _engineNoController = TextEditingController();
  final TextEditingController _engineCapacityController =
      TextEditingController();
  String? _transmission;
  String? _fuelType;
  String? _color;
  final TextEditingController _seatingCapacityController =
      TextEditingController();
  final TextEditingController _doorsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Generate year options from current year down to 1990
    final currentYear = DateTime.now().year;
    _yearOptions = List.generate(
      currentYear - 1990 + 1,
      (index) => (currentYear - index).toString(),
    );
    // No default value for selected year
  }

  void _updateMakeOptions() {
    setState(() {
      _selectedMake = null;
      _updateModelOptions();
      _selectedCategory = null;
    });
  }

  void _updateModelOptions() {
    setState(() {
      _selectedModel = null;
    });
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _vehicleNoController.dispose();
    _chassisNoController.dispose();
    _engineNoController.dispose();
    _engineCapacityController.dispose();
    _seatingCapacityController.dispose();
    _doorsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare vehicle data
      final vehicleData = {
        'type': _vehicleType,
        'make': _selectedMake,
        'model': _selectedModel,
        'category': _selectedCategory,
        'grade': _gradeController.text,
        'year': _selectedYear,
        'vehicleNo': _vehicleNoController.text,
        'chassisNo': _chassisNoController.text,
        'engineNo': _engineNoController.text,
        'engineCapacity': _engineCapacityController.text,
        'transmission': _transmission,
        'fuelType': _fuelType,
        'color': _color,
        'seatingCapacity': _seatingCapacityController.text,
        'doors': _doorsController.text,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'listingDate': DateTime.now().toIso8601String(),
        'status': 'available',
      };

      // TODO: Implement database storage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Vehicle'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ownership status indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "You've confirmed you are the registered owner of this vehicle.",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Vehicle Type
                    _buildSectionHeader('Vehicle Type'),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: _vehicleType,
                      items: _vehicleTypes
                          .map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(_getVehicleIcon(type)),
                                    const SizedBox(width: 12),
                                    Text(type),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _vehicleType = value;
                            _updateMakeOptions();
                          });
                        }
                      },
                      labelText: 'Vehicle Type *',
                    ),
                    const SizedBox(height: 24),

                    // Section: Vehicle Details
                    _buildSectionHeader('Vehicle Details'),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedMake,
                      items: _vehicleType != null
                          ? _makesMap[_vehicleType]
                                  ?.map((make) => DropdownMenuItem<String>(
                                        value: make,
                                        child: Text(make),
                                      ))
                                  .toList() ??
                              []
                          : [],
                      onChanged: (value) {
                        setState(() {
                          _selectedMake = value;
                          _updateModelOptions();
                        });
                      },
                      labelText: 'Make/Brand *',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedModel,
                      items: (_vehicleType != null &&
                              _selectedMake != null &&
                              _modelsMap[_vehicleType]?[_selectedMake] != null)
                          ? _modelsMap[_vehicleType]![_selectedMake]!
                              .map((model) => DropdownMenuItem<String>(
                                    value: model,
                                    child: Text(model),
                                  ))
                              .toList()
                          : [],
                      onChanged: (value) =>
                          setState(() => _selectedModel = value),
                      labelText: 'Model *',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedCategory,
                      items: _vehicleType != null
                          ? _categoriesMap[_vehicleType]
                                  ?.map((category) => DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category),
                                      ))
                                  .toList() ??
                              []
                          : [],
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      labelText: 'Category *',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Grade',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedYear,
                      items: _yearOptions
                          .map((year) => DropdownMenuItem<String>(
                                value: year,
                                child: Text(year),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedYear = value),
                      labelText: 'Year of Manufacture *',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleNoController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter vehicle number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _chassisNoController,
                      decoration: const InputDecoration(
                        labelText: 'Chassis Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter chassis number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _engineNoController,
                      decoration: const InputDecoration(
                        labelText: 'Engine Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter engine number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _engineCapacityController,
                      decoration: const InputDecoration(
                        labelText: 'Engine Capacity (cc) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter engine capacity';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _transmission,
                      items: _transmissionOptions
                          .map((transmission) => DropdownMenuItem<String>(
                                value: transmission,
                                child: Text(transmission),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _transmission = value),
                      labelText: 'Transmission *',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _fuelType,
                      items: _fuelTypeOptions
                          .map((fuel) => DropdownMenuItem<String>(
                                value: fuel,
                                child: Text(fuel),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _fuelType = value),
                      labelText: 'Fuel Type *',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _color,
                      items: _colorOptions
                          .map((color) => DropdownMenuItem<String>(
                                value: color,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getColorValue(color),
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(color),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _color = value),
                      labelText: 'Color *',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Text(
                        'Note: Please put 0 when Seating Capacity & Number of Doors not applicable for your vehicle type.',
                        style: TextStyle(
                            color: Colors.amber, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seatingCapacityController,
                      decoration: const InputDecoration(
                        labelText: 'Seating Capacity *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter seating capacity';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'Please enter a valid non-negative number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _doorsController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Doors *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter number of doors';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'Please enter a valid non-negative number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Required fields note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fields marked with * are required',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'LIST MY VEHICLE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    required String labelText,
  }) {
    final isRequired = labelText.endsWith('*');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        value: value,
        items: items,
        onChanged: onChanged,
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? 'This field is required' : null
            : null,
        isExpanded: true,
        dropdownColor: Colors.white,
        hint: Text('Select ${labelText.replaceAll(' *', '')}'),
      ),
    );
  }

  IconData _getVehicleIcon(String type) => switch (type) {
        'Bike' => Icons.directions_bike,
        'Three-Wheeler' => Icons.directions_car_filled,
        _ => Icons.directions_car,
      };

  Color _getColorValue(String colorName) => switch (colorName.toLowerCase()) {
        'black' => Colors.black,
        'white' => Colors.white,
        'silver' => const Color(0xFFC0C0C0),
        'gray' => Colors.grey,
        'red' => Colors.red,
        'blue' => Colors.blue,
        'green' => Colors.green,
        'yellow' => Colors.yellow,
        'orange' => Colors.orange,
        'brown' => Colors.brown,
        'purple' => Colors.purple,
        'gold' => const Color(0xFFFFD700),
        'beige' => const Color(0xFFF5F5DC),
        _ => Colors.grey.withOpacity(0.5),
      };
}
