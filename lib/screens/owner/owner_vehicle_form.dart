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

  // District options for collection point
  final List<String> _districtOptions = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya'
  ];

  // Time units for rental periods
  final List<String> _timeUnits = ['Hour(s)', 'Day(s)', 'Week(s)', 'Month(s)'];

  // Rent mode options
  final List<String> _rentModeOptions = [
    'Vehicle Only',
    'With Driver',
    'With or Without Driver'
  ];

  // Rental time periods
  final List<String> _rentalPeriods = ['Hourly', 'Daily', 'Weekly', 'Monthly'];
  final Map<String, bool> _selectedRentalPeriods = {
    'Hourly': false,
    'Daily': false,
    'Weekly': false,
    'Monthly': false,
  };

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

  // Collection point address controllers
  String? _selectedDistrict;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Rental conditions controllers
  final TextEditingController _minRentalPeriodController =
      TextEditingController();
  String _minRentalPeriodUnit = 'Day(s)';
  final TextEditingController _maxRentalPeriodController =
      TextEditingController();
  String _maxRentalPeriodUnit = 'Day(s)';
  final TextEditingController _advanceRentalPeriodController =
      TextEditingController();
  String _advanceRentalPeriodUnit = 'Hour(s)';
  String? _rentMode;

  // Driver details controllers
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverLicenseController =
      TextEditingController();

  // Pricing controllers
  final TextEditingController _vehicleValueController = TextEditingController();

  // Hourly pricing controllers
  final TextEditingController _hourlyVehicleOnlyPriceController =
      TextEditingController();
  final TextEditingController _hourlyVehicleOnlyMileageLimitController =
      TextEditingController();
  final TextEditingController _hourlyVehicleOnlyExtraMileageController =
      TextEditingController();

  final TextEditingController _hourlyWithDriverPriceController =
      TextEditingController();
  final TextEditingController _hourlyWithDriverMileageLimitController =
      TextEditingController();
  final TextEditingController _hourlyWithDriverExtraMileageController =
      TextEditingController();

  // Daily pricing controllers
  final TextEditingController _dailyVehicleOnlyPriceController =
      TextEditingController();
  final TextEditingController _dailyVehicleOnlyMileageLimitController =
      TextEditingController();
  final TextEditingController _dailyVehicleOnlyExtraMileageController =
      TextEditingController();

  final TextEditingController _dailyWithDriverPriceController =
      TextEditingController();
  final TextEditingController _dailyWithDriverMileageLimitController =
      TextEditingController();
  final TextEditingController _dailyWithDriverExtraMileageController =
      TextEditingController();

  // Weekly pricing controllers
  final TextEditingController _weeklyVehicleOnlyPriceController =
      TextEditingController();
  final TextEditingController _weeklyVehicleOnlyMileageLimitController =
      TextEditingController();
  final TextEditingController _weeklyVehicleOnlyExtraMileageController =
      TextEditingController();

  final TextEditingController _weeklyWithDriverPriceController =
      TextEditingController();
  final TextEditingController _weeklyWithDriverMileageLimitController =
      TextEditingController();
  final TextEditingController _weeklyWithDriverExtraMileageController =
      TextEditingController();

  // Monthly pricing controllers
  final TextEditingController _monthlyVehicleOnlyPriceController =
      TextEditingController();
  final TextEditingController _monthlyVehicleOnlyMileageLimitController =
      TextEditingController();
  final TextEditingController _monthlyVehicleOnlyExtraMileageController =
      TextEditingController();

  final TextEditingController _monthlyWithDriverPriceController =
      TextEditingController();
  final TextEditingController _monthlyWithDriverMileageLimitController =
      TextEditingController();
  final TextEditingController _monthlyWithDriverExtraMileageController =
      TextEditingController();

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
    _cityController.dispose();
    _addressController.dispose();
    _minRentalPeriodController.dispose();
    _maxRentalPeriodController.dispose();
    _advanceRentalPeriodController.dispose();
    _driverNameController.dispose();
    _driverLicenseController.dispose();
    _vehicleValueController.dispose();

    // Dispose hourly controllers
    _hourlyVehicleOnlyPriceController.dispose();
    _hourlyVehicleOnlyMileageLimitController.dispose();
    _hourlyVehicleOnlyExtraMileageController.dispose();
    _hourlyWithDriverPriceController.dispose();
    _hourlyWithDriverMileageLimitController.dispose();
    _hourlyWithDriverExtraMileageController.dispose();

    // Dispose daily controllers
    _dailyVehicleOnlyPriceController.dispose();
    _dailyVehicleOnlyMileageLimitController.dispose();
    _dailyVehicleOnlyExtraMileageController.dispose();
    _dailyWithDriverPriceController.dispose();
    _dailyWithDriverMileageLimitController.dispose();
    _dailyWithDriverExtraMileageController.dispose();

    // Dispose weekly controllers
    _weeklyVehicleOnlyPriceController.dispose();
    _weeklyVehicleOnlyMileageLimitController.dispose();
    _weeklyVehicleOnlyExtraMileageController.dispose();
    _weeklyWithDriverPriceController.dispose();
    _weeklyWithDriverMileageLimitController.dispose();
    _weeklyWithDriverExtraMileageController.dispose();

    // Dispose monthly controllers
    _monthlyVehicleOnlyPriceController.dispose();
    _monthlyVehicleOnlyMileageLimitController.dispose();
    _monthlyVehicleOnlyExtraMileageController.dispose();
    _monthlyWithDriverPriceController.dispose();
    _monthlyWithDriverMileageLimitController.dispose();
    _monthlyWithDriverExtraMileageController.dispose();

    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one rental period is selected
    if (!_selectedRentalPeriods.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one rental time period')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare pricing data based on selected rental periods and rent mode
      final Map<String, dynamic> pricingData = {
        'vehicleValue': _vehicleValueController.text,
        'rentalPeriods': _selectedRentalPeriods,
      };

      // Add hourly pricing if selected
      if (_selectedRentalPeriods['Hourly']!) {
        pricingData['hourly'] = {};

        if (_rentMode == 'Vehicle Only' ||
            _rentMode == 'With or Without Driver') {
          pricingData['hourly']['vehicleOnly'] = {
            'price': _hourlyVehicleOnlyPriceController.text,
            'mileageLimit': _hourlyVehicleOnlyMileageLimitController.text,
            'extraMileageCharge': _hourlyVehicleOnlyExtraMileageController.text,
          };
        }

        if (_rentMode == 'With Driver' ||
            _rentMode == 'With or Without Driver') {
          pricingData['hourly']['withDriver'] = {
            'price': _hourlyWithDriverPriceController.text,
            'mileageLimit': _hourlyWithDriverMileageLimitController.text,
            'extraMileageCharge': _hourlyWithDriverExtraMileageController.text,
          };
        }
      }

      // Add daily pricing if selected
      if (_selectedRentalPeriods['Daily']!) {
        pricingData['daily'] = {};

        if (_rentMode == 'Vehicle Only' ||
            _rentMode == 'With or Without Driver') {
          pricingData['daily']['vehicleOnly'] = {
            'price': _dailyVehicleOnlyPriceController.text,
            'mileageLimit': _dailyVehicleOnlyMileageLimitController.text,
            'extraMileageCharge': _dailyVehicleOnlyExtraMileageController.text,
          };
        }

        if (_rentMode == 'With Driver' ||
            _rentMode == 'With or Without Driver') {
          pricingData['daily']['withDriver'] = {
            'price': _dailyWithDriverPriceController.text,
            'mileageLimit': _dailyWithDriverMileageLimitController.text,
            'extraMileageCharge': _dailyWithDriverExtraMileageController.text,
          };
        }
      }

      // Add weekly pricing if selected
      if (_selectedRentalPeriods['Weekly']!) {
        pricingData['weekly'] = {};

        if (_rentMode == 'Vehicle Only' ||
            _rentMode == 'With or Without Driver') {
          pricingData['weekly']['vehicleOnly'] = {
            'price': _weeklyVehicleOnlyPriceController.text,
            'mileageLimit': _weeklyVehicleOnlyMileageLimitController.text,
            'extraMileageCharge': _weeklyVehicleOnlyExtraMileageController.text,
          };
        }

        if (_rentMode == 'With Driver' ||
            _rentMode == 'With or Without Driver') {
          pricingData['weekly']['withDriver'] = {
            'price': _weeklyWithDriverPriceController.text,
            'mileageLimit': _weeklyWithDriverMileageLimitController.text,
            'extraMileageCharge': _weeklyWithDriverExtraMileageController.text,
          };
        }
      }

      // Add monthly pricing if selected
      if (_selectedRentalPeriods['Monthly']!) {
        pricingData['monthly'] = {};

        if (_rentMode == 'Vehicle Only' ||
            _rentMode == 'With or Without Driver') {
          pricingData['monthly']['vehicleOnly'] = {
            'price': _monthlyVehicleOnlyPriceController.text,
            'mileageLimit': _monthlyVehicleOnlyMileageLimitController.text,
            'extraMileageCharge':
                _monthlyVehicleOnlyExtraMileageController.text,
          };
        }

        if (_rentMode == 'With Driver' ||
            _rentMode == 'With or Without Driver') {
          pricingData['monthly']['withDriver'] = {
            'price': _monthlyWithDriverPriceController.text,
            'mileageLimit': _monthlyWithDriverMileageLimitController.text,
            'extraMileageCharge': _monthlyWithDriverExtraMileageController.text,
          };
        }
      }

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
        'collectionPoint': {
          'district': _selectedDistrict,
          'city': _cityController.text,
          'address': _addressController.text,
        },
        'rentalConditions': {
          'minRentalPeriod': {
            'value': _minRentalPeriodController.text,
            'unit': _minRentalPeriodUnit,
          },
          'maxRentalPeriod': {
            'value': _maxRentalPeriodController.text,
            'unit': _maxRentalPeriodUnit,
          },
          'advanceRentalPeriod': {
            'value': _advanceRentalPeriodController.text,
            'unit': _advanceRentalPeriodUnit,
          },
          'rentMode': _rentMode,
        },
        'pricing': pricingData,
      };

      // Add driver details if applicable
      if (_rentMode == 'With Driver' || _rentMode == 'With or Without Driver') {
        vehicleData['driverDetails'] = {
          'name': _driverNameController.text,
          'licenseNo': _driverLicenseController.text,
        };
      }

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

  bool _shouldShowDriverDetails() {
    return _rentMode == 'With Driver' || _rentMode == 'With or Without Driver';
  }

  bool _shouldShowVehicleOnlyPricing() {
    return _rentMode == 'Vehicle Only' || _rentMode == 'With or Without Driver';
  }

  bool _shouldShowWithDriverPricing() {
    return _rentMode == 'With Driver' || _rentMode == 'With or Without Driver';
  }

  bool _isAnyRentalPeriodSelected() {
    return _selectedRentalPeriods.values.contains(true);
  }

  bool _isPricingApplicable() {
    return _rentMode != null && _isAnyRentalPeriodSelected();
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
                    );
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
                    );
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
                    );
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
                    );
                    const SizedBox(height: 16);
                    TextFormField(
                      controller: _chassisNoController,
                      decoration: const InputDecoration(
                        labelText: 'Chassis Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter chassis number'
                          : null,
                    );
                    const SizedBox(height: 16);
                    TextFormField(
                      controller: _engineNoController,
                      decoration: const InputDecoration(
                        labelText: 'Engine Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter engine number'
                          : null,
                    );
                    const SizedBox(height: 16);
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
                    );
                    const SizedBox(height: 16);
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
                    );
                    const SizedBox(height: 16);
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
                    );
                    const SizedBox(height: 16);
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
                    );
                    const SizedBox(height: 16);
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
                    );
                    const SizedBox(height: 16);
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
                    );
                    const SizedBox(height: 16);
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
                    );
                    const SizedBox(height: 24),

                    // Section: Collection Point Address
                    _buildSectionHeader('Collection Point Address'),
                    const SizedBox(height: 16),

                    // District dropdown
                    _buildDropdown(
                      value: _selectedDistrict,
                      items: _districtOptions
                          .map((district) => DropdownMenuItem<String>(
                                value: district,
                                child: Text(district),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDistrict = value),
                      labelText: 'District *',
                    );
                    const SizedBox(height: 16),

                    // City field
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter the city'
                          : null,
                    );
                    const SizedBox(height: 16),

                    // Address field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter the collection point address'
                          : null,
                    );
                    const SizedBox(height: 24),

                    // Section: Rental Conditions
                    _buildSectionHeader('Rental Conditions'),
                    const SizedBox(height: 16),

                    // Minimum Rental Period
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _minRentalPeriodController,
                            decoration: const InputDecoration(
                              labelText: 'Minimum Rental Period *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _minRentalPeriodUnit,
                                items: _timeUnits
                                    .map((unit) => DropdownMenuItem<String>(
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                                onChanged: (value) => setState(
                                    () => _minRentalPeriodUnit = value!),
                                hint: const Text('Unit'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                    const SizedBox(height: 16),

                    // Maximum Rental Period
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _maxRentalPeriodController,
                            decoration: const InputDecoration(
                              labelText: 'Maximum Rental Period *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _maxRentalPeriodUnit,
                                items: _timeUnits
                                    .map((unit) => DropdownMenuItem<String>(
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                                onChanged: (value) => setState(
                                    () => _maxRentalPeriodUnit = value!),
                                hint: const Text('Unit'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                    const SizedBox(height: 16),

                    // Advance Rental Period
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _advanceRentalPeriodController,
                            decoration: const InputDecoration(
                              labelText: 'Advance Notice Period *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _advanceRentalPeriodUnit,
                                items: _timeUnits
                                    .map((unit) => DropdownMenuItem<String>(
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                                onChanged: (value) => setState(
                                    () => _advanceRentalPeriodUnit = value!),
                                hint: const Text('Unit'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                    const SizedBox(height: 8),
                    const Text(
                      'Note: The advance notice period is the minimum notice period for booking a vehicle.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    );
                    const SizedBox(height: 16),

                    // Rent Mode
                    _buildDropdown(
                      value: _rentMode,
                      items: _rentModeOptions
                          .map((mode) => DropdownMenuItem<String>(
                                value: mode,
                                child: Text(mode),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _rentMode = value),
                      labelText: 'Rent Mode *',
                    );
                    const SizedBox(height: 24),

                    // Driver Details Section (conditionally shown)
                    if (_shouldShowDriverDetails()) ...[
                      _buildSectionHeader('Driver Details'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _driverNameController,
                        decoration: const InputDecoration(
                          labelText: 'Driver Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: _shouldShowDriverDetails()
                            ? (value) => value == null || value.isEmpty
                                ? 'Please enter driver name'
                                : null
                            : null,
                      );
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _driverLicenseController,
                        decoration: const InputDecoration(
                          labelText: 'Driver License Number *',
                          border: OutlineInputBorder(),
                        ),
                        validator: _shouldShowDriverDetails()
                            ? (value) => value == null || value.isEmpty
                                ? 'Please enter driver license number'
                                : null
                            : null,
                      );
                      const SizedBox(height: 24),
                    ],

                    // Pricing Section
                    _buildSectionHeader('Pricing'),
                    const SizedBox(height: 16),

                    // Current Market Value
                    TextFormField(
                      controller: _vehicleValueController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Value (LKR) *',
                        border: OutlineInputBorder(),
                        hintText: 'Current market value of the vehicle',
                        prefixText: 'Rs. ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle value';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    );
                    const SizedBox(height: 16),

                    // Rental Time Period Selection
                    const Text(
                      'Please select at least one rental time period *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: _rentalPeriods.map((period) {
                        return FilterChip(
                          label: Text(period),
                          selected: _selectedRentalPeriods[period]!,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRentalPeriods[period] = selected;
                            });
                          },
                          selectedColor:
                              theme.colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: theme.colorScheme.primary,
                        );
                      }).toList(),
                    );
                    const SizedBox(height: 24),

                    // Show pricing inputs based on selected periods and rent mode
                    if (_rentMode == null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Text(
                          'Please select a rent mode to add pricing.',
                          style: TextStyle(
                            color: Colors.amber, 
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ] else if (!_isAnyRentalPeriodSelected()) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Text(
                          'Please select at least one rental time period.',
                          style: TextStyle(
                            color: Colors.amber, 
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Hourly pricing
                      if (_selectedRentalPeriods['Hourly']!) ...[
                        const SizedBox(height: 16),
                        _buildSectionSubheader('Hourly Rental Price'),
                        const SizedBox(height: 12),

                        // Vehicle Only pricing (if applicable)
                        if (_shouldShowVehicleOnlyPricing()) ...[
                          const Text(
                            'Vehicle Only',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _hourlyVehicleOnlyPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Hour Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Hourly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter hourly price';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _hourlyVehicleOnlyMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Hourly Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Hourly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter hourly mileage limit';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _hourlyVehicleOnlyExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Hourly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8),
                          const Text(
                            'Note: Please put 0 (zero) for both Hourly Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                          const SizedBox(height: 16),
                        ],

                        // With Driver pricing (if applicable)
                        if (_shouldShowWithDriverPricing()) ...[
                          const Text(
                            'With Driver',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _hourlyWithDriverPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Hour Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Hourly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter hourly price with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _hourlyWithDriverMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Hourly Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Hourly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter hourly mileage limit with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _hourlyWithDriverExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Hourly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8),
                          const Text(
                            'Note: Please put 0 (zero) for both Hourly Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                        ];
                      ],

                      // Daily pricing
                      if (_selectedRentalPeriods['Daily']!) ...[
                        const SizedBox(height: 24),
                        _buildSectionSubheader('Daily Rental Price'),
                        const SizedBox(height: 12),

                        // Vehicle Only pricing (if applicable)
                        if (_shouldShowVehicleOnlyPricing()) ...[
                          const Text(
                            'Vehicle Only',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dailyVehicleOnlyPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Day Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Daily']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter daily price';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dailyVehicleOnlyMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Daily Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Daily']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter daily mileage limit';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dailyVehicleOnlyExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Daily']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8);
                          const Text(
                            'Note: Please put 0 (zero) for both Daily Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                          const SizedBox(height: 16),
                        ],

                        // With Driver pricing (if applicable)
                        if (_shouldShowWithDriverPricing()) ...[
                          const Text(
                            'With Driver',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dailyWithDriverPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Day Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Daily']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter daily price with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dailyWithDriverMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Daily Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Daily']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter daily mileage limit with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dailyWithDriverExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Daily']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8);
                          const Text(
                            'Note: Please put 0 (zero) for both Daily Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                        ];
                      ],

                      // Weekly pricing
                      if (_selectedRentalPeriods['Weekly']!) ...[
                        const SizedBox(height: 24),
                        _buildSectionSubheader('Weekly Rental Price'),
                        const SizedBox(height: 12),

                        // Vehicle Only pricing (if applicable)
                        if (_shouldShowVehicleOnlyPricing()) ...[
                          const Text(
                            'Vehicle Only',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _weeklyVehicleOnlyPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Week Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Weekly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter weekly price';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _weeklyVehicleOnlyMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Weekly Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Weekly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter weekly mileage limit';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _weeklyVehicleOnlyExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Weekly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8);
                          const Text(
                            'Note: Please put 0 (zero) for both Weekly Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                          const SizedBox(height: 16),
                        ],

                        // With Driver pricing (if applicable)
                        if (_shouldShowWithDriverPricing()) ...[
                          const Text(
                            'With Driver',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _weeklyWithDriverPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Week Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Weekly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter weekly price with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _weeklyWithDriverMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Weekly Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Weekly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter weekly mileage limit with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _weeklyWithDriverExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Weekly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8);
                          const Text(
                            'Note: Please put 0 (zero) for both Weekly Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                        ];
                      ],

                      // Monthly pricing
                      if (_selectedRentalPeriods['Monthly']!) ...[
                        const SizedBox(height: 24),
                        _buildSectionSubheader('Monthly Rental Price'),
                        const SizedBox(height: 12),

                        // Vehicle Only pricing (if applicable)
                        if (_shouldShowVehicleOnlyPricing()) ...[
                          const Text(
                            'Vehicle Only',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _monthlyVehicleOnlyPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Month Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Monthly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter monthly price';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _monthlyVehicleOnlyMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Monthly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter monthly mileage limit';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _monthlyVehicleOnlyExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowVehicleOnlyPricing() &&
                                  _selectedRentalPeriods['Monthly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8);
                          const Text(
                            'Note: Please put 0 (zero) for both Monthly Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                          const SizedBox(height: 16),
                        ],

                        // With Driver pricing (if applicable)
                        if (_shouldShowWithDriverPricing()) ...[
                          const Text(
                            'With Driver',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _monthlyWithDriverPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Per Month Price (LKR) *',
                              border: OutlineInputBorder(),
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Monthly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter monthly price with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _monthlyWithDriverMileageLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Mileage Limit (KM) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Monthly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter monthly mileage limit with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 12),
                          TextFormField(
                            controller:
                                _monthlyWithDriverExtraMileageController,
                            decoration: const InputDecoration(
                              labelText: 'Extra Mileage Charge (LKR) *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter 0 for unlimited',
                              prefixText: 'Rs. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_shouldShowWithDriverPricing() &&
                                  _selectedRentalPeriods['Monthly']! &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter extra mileage charge with driver';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) < 0)) {
                                return 'Please enter a valid non-negative number';
                              }
                              return null;
                            },
                          );
                          const SizedBox(height: 8);
                          const Text(
                            'Note: Please put 0 (zero) for both Monthly Milage Limit and Extra Milage Charge for unlimited limits.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          );
                        ];
                      ],
                    ],

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
                    );
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
                    );
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

  Widget _buildSectionSubheader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
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

// Helper widget for SizedBox
class SizedSize extends StatelessWidget {
  final double width;
  final double height;

  const SizedSize({super.key, this.width = 0, this.height = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height);
  }
}
