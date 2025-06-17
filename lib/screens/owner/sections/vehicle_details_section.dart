import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../utils/form_data_constants.dart';
import '../../../widgets/form_widgets.dart';

class VehicleDetailsSection extends StatefulWidget {
  final VehicleBasicDetails vehicleDetails;
  final Function(VehicleBasicDetails) onVehicleDetailsChanged;

  const VehicleDetailsSection({
    Key? key,
    required this.vehicleDetails,
    required this.onVehicleDetailsChanged,
  }) : super(key: key);

  @override
  _VehicleDetailsSectionState createState() => _VehicleDetailsSectionState();
}

class _VehicleDetailsSectionState extends State<VehicleDetailsSection> {
  late TextEditingController _gradeController;
  late TextEditingController _vehicleNoController;
  late TextEditingController _chassisNoController;
  late TextEditingController _engineNoController;
  late TextEditingController _engineCapacityController;
  late TextEditingController _seatingCapacityController;
  late TextEditingController _doorsController;
  
  List<String> _yearOptions = [];

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(text: widget.vehicleDetails.grade ?? '');
    _vehicleNoController = TextEditingController(text: widget.vehicleDetails.vehicleNo);
    _chassisNoController = TextEditingController(text: widget.vehicleDetails.chassisNo);
    _engineNoController = TextEditingController(text: widget.vehicleDetails.engineNo);
    _engineCapacityController = TextEditingController(text: widget.vehicleDetails.engineCapacity);
    _seatingCapacityController = TextEditingController(text: widget.vehicleDetails.seatingCapacity);
    _doorsController = TextEditingController(text: widget.vehicleDetails.doors);

    // Generate year options from current year down to 1990
    final currentYear = DateTime.now().year;
    _yearOptions = List.generate(
      currentYear - 1990 + 1,
      (index) => (currentYear - index).toString(),
    );

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _gradeController.addListener(_updateVehicleDetails);
    _vehicleNoController.addListener(_updateVehicleDetails);
    _chassisNoController.addListener(_updateVehicleDetails);
    _engineNoController.addListener(_updateVehicleDetails);
    _engineCapacityController.addListener(_updateVehicleDetails);
    _seatingCapacityController.addListener(_updateVehicleDetails);
    _doorsController.addListener(_updateVehicleDetails);
  }

  void _updateVehicleDetails() {
    final updatedDetails = VehicleBasicDetails(
      vehicleType: widget.vehicleDetails.vehicleType,
      make: widget.vehicleDetails.make,
      model: widget.vehicleDetails.model,
      category: widget.vehicleDetails.category,
      year: widget.vehicleDetails.year,
      transmission: widget.vehicleDetails.transmission,
      fuelType: widget.vehicleDetails.fuelType,
      color: widget.vehicleDetails.color,
      
      // Updated values from controllers
      grade: _gradeController.text,
      vehicleNo: _vehicleNoController.text,
      chassisNo: _chassisNoController.text,
      engineNo: _engineNoController.text,
      engineCapacity: _engineCapacityController.text,
      seatingCapacity: _seatingCapacityController.text,
      doors: _doorsController.text,
    );
    
    widget.onVehicleDetailsChanged(updatedDetails);
  }

  void _updateModelOptions() {
    final updatedDetails = VehicleBasicDetails(
      vehicleType: widget.vehicleDetails.vehicleType,
      make: widget.vehicleDetails.make,
      model: null,  // Reset model when make changes
      category: widget.vehicleDetails.category,
      grade: _gradeController.text,
      year: widget.vehicleDetails.year,
      vehicleNo: _vehicleNoController.text,
      chassisNo: _chassisNoController.text,
      engineNo: _engineNoController.text,
      engineCapacity: _engineCapacityController.text,
      transmission: widget.vehicleDetails.transmission,
      fuelType: widget.vehicleDetails.fuelType,
      color: widget.vehicleDetails.color,
      seatingCapacity: _seatingCapacityController.text,
      doors: _doorsController.text,
    );
    
    widget.onVehicleDetailsChanged(updatedDetails);
  }

  void _updateMakeOptions() {
    final updatedDetails = VehicleBasicDetails(
      vehicleType: widget.vehicleDetails.vehicleType,
      make: null,  // Reset make when vehicle type changes
      model: null,  // Reset model when vehicle type changes
      category: null,  // Reset category when vehicle type changes
      grade: _gradeController.text,
      year: widget.vehicleDetails.year,
      vehicleNo: _vehicleNoController.text,
      chassisNo: _chassisNoController.text,
      engineNo: _engineNoController.text,
      engineCapacity: _engineCapacityController.text,
      transmission: widget.vehicleDetails.transmission,
      fuelType: widget.vehicleDetails.fuelType,
      color: widget.vehicleDetails.color,
      seatingCapacity: _seatingCapacityController.text,
      doors: _doorsController.text,
    );
    
    widget.onVehicleDetailsChanged(updatedDetails);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Vehicle Type
        FormWidgets.buildSectionHeader('Vehicle Type'),
        const SizedBox(height: 12),
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.vehicleType,
          items: VehicleFormConstants.vehicleTypes
              .map((type) => DropdownMenuItem<String>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(VehicleFormConstants.getVehicleIcon(type)),
                        const SizedBox(width: 12),
                        Text(type),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              final updatedDetails = VehicleBasicDetails(
                vehicleType: value,
                make: null,
                model: null,
                category: null,
                grade: _gradeController.text,
                year: widget.vehicleDetails.year,
                vehicleNo: _vehicleNoController.text,
                chassisNo: _chassisNoController.text,
                engineNo: _engineNoController.text,
                engineCapacity: _engineCapacityController.text,
                transmission: widget.vehicleDetails.transmission,
                fuelType: widget.vehicleDetails.fuelType,
                color: widget.vehicleDetails.color,
                seatingCapacity: _seatingCapacityController.text,
                doors: _doorsController.text,
              );
              widget.onVehicleDetailsChanged(updatedDetails);
            }
          },
          labelText: 'Vehicle Type *',
        ),
        const SizedBox(height: 24),

        // Section: Vehicle Details
        FormWidgets.buildSectionHeader('Vehicle Details'),
        const SizedBox(height: 16),
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.make,
          items: widget.vehicleDetails.vehicleType != null
              ? VehicleFormConstants.makesMap[widget.vehicleDetails.vehicleType]
                      ?.map((make) => DropdownMenuItem<String>(
                            value: make,
                            child: Text(make),
                          ))
                      .toList() ??
                  []
              : [],
          onChanged: (value) {
            final updatedDetails = VehicleBasicDetails(
              vehicleType: widget.vehicleDetails.vehicleType,
              make: value,
              model: null,  // Reset model when make changes
              category: widget.vehicleDetails.category,
              grade: _gradeController.text,
              year: widget.vehicleDetails.year,
              vehicleNo: _vehicleNoController.text,
              chassisNo: _chassisNoController.text,
              engineNo: _engineNoController.text,
              engineCapacity: _engineCapacityController.text,
              transmission: widget.vehicleDetails.transmission,
              fuelType: widget.vehicleDetails.fuelType,
              color: widget.vehicleDetails.color,
              seatingCapacity: _seatingCapacityController.text,
              doors: _doorsController.text,
            );
            widget.onVehicleDetailsChanged(updatedDetails);
          },
          labelText: 'Make/Brand *',
        ),
        const SizedBox(height: 16),
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.model,
          items: (widget.vehicleDetails.vehicleType != null &&
                  widget.vehicleDetails.make != null &&
                  VehicleFormConstants.modelsMap[widget.vehicleDetails.vehicleType]?[widget.vehicleDetails.make] != null)
              ? VehicleFormConstants.modelsMap[widget.vehicleDetails.vehicleType]![widget.vehicleDetails.make]!
                  .map((model) => DropdownMenuItem<String>(
                        value: model,
                        child: Text(model),
                      ))
                  .toList()
              : [],
          onChanged: (value) {
            final updatedDetails = VehicleBasicDetails(
              vehicleType: widget.vehicleDetails.vehicleType,
              make: widget.vehicleDetails.make,
              model: value,
              category: widget.vehicleDetails.category,
              grade: _gradeController.text,
              year: widget.vehicleDetails.year,
              vehicleNo: _vehicleNoController.text,
              chassisNo: _chassisNoController.text,
              engineNo: _engineNoController.text,
              engineCapacity: _engineCapacityController.text,
              transmission: widget.vehicleDetails.transmission,
              fuelType: widget.vehicleDetails.fuelType,
              color: widget.vehicleDetails.color,
              seatingCapacity: _seatingCapacityController.text,
              doors: _doorsController.text,
            );
            widget.onVehicleDetailsChanged(updatedDetails);
          },
          labelText: 'Model *',
        ),
        const SizedBox(height: 16),
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.category,
          items: widget.vehicleDetails.vehicleType != null
              ? VehicleFormConstants.categoriesMap[widget.vehicleDetails.vehicleType]
                      ?.map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ))
                      .toList() ??
                  []
              : [],
          onChanged: (value) {
            final updatedDetails = VehicleBasicDetails(
              vehicleType: widget.vehicleDetails.vehicleType,
              make: widget.vehicleDetails.make,
              model: widget.vehicleDetails.model,
              category: value,
              grade: _gradeController.text,
              year: widget.vehicleDetails.year,
              vehicleNo: _vehicleNoController.text,
              chassisNo: _chassisNoController.text,
              engineNo: _engineNoController.text,
              engineCapacity: _engineCapacityController.text,
              transmission: widget.vehicleDetails.transmission,
              fuelType: widget.vehicleDetails.fuelType,
              color: widget.vehicleDetails.color,
              seatingCapacity: _seatingCapacityController.text,
              doors: _doorsController.text,
            );
            widget.onVehicleDetailsChanged(updatedDetails);
          },
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
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.year,
          items: _yearOptions
              .map((year) => DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  ))
              .toList(),
          onChanged: (value) {
            final updatedDetails = VehicleBasicDetails(
              vehicleType: widget.vehicleDetails.vehicleType,
              make: widget.vehicleDetails.make,
              model: widget.vehicleDetails.model,
              category: widget.vehicleDetails.category,
              grade: _gradeController.text,
              year: value,
              vehicleNo: _vehicleNoController.text,
              chassisNo: _chassisNoController.text,
              engineNo: _engineNoController.text,
              engineCapacity: _engineCapacityController.text,
              transmission: widget.vehicleDetails.transmission,
              fuelType: widget.vehicleDetails.fuelType,
              color: widget.vehicleDetails.color,
              seatingCapacity: _seatingCapacityController.text,
              doors: _doorsController.text,
            );
            widget.onVehicleDetailsChanged(updatedDetails);
          },
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
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.transmission,
          items: VehicleFormConstants.transmissionOptions
              .map((transmission) => DropdownMenuItem<String>(
                    value: transmission,
                    child: Text(transmission),
                  ))
              .toList(),
          onChanged: (value) {
            final updatedDetails = VehicleBasicDetails(
              vehicleType: widget.vehicleDetails.vehicleType,
              make: widget.vehicleDetails.make,
              model: widget.vehicleDetails.model,
              category: widget.vehicleDetails.category,
              grade: _gradeController.text,
              year: widget.vehicleDetails.year,
              vehicleNo: _vehicleNoController.text,
              chassisNo: _chassisNoController.text,
              engineNo: _engineNoController.text,
              engineCapacity: _engineCapacityController.text,
              transmission: value,
              fuelType: widget.vehicleDetails.fuelType,
              color: widget.vehicleDetails.color,
              seatingCapacity: _seatingCapacityController.text,
              doors: _doorsController.text,
            );
            widget.onVehicleDetailsChanged(updatedDetails);
          },
          labelText: 'Transmission *',
        ),
        const SizedBox(height: 16),
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.fuelType,
          items: VehicleFormConstants.fuelTypeOptions
              .map((fuel) => DropdownMenuItem<String>(
                    value: fuel,
                    child: Text(fuel),
                  ))
              .toList(),
          onChanged: (value) {
            final updatedDetails = VehicleBasicDetails(
              vehicleType: widget.vehicleDetails.vehicleType,
              make: widget.vehicleDetails.make,
              model: widget.vehicleDetails.model,
              category: widget.vehicleDetails.category,
              grade: _gradeController.text,
              year: widget.vehicleDetails.year,
              vehicleNo: _vehicleNoController.text,
              chassisNo: _chassisNoController.text,
              engineNo: _engineNoController.text,
              engineCapacity: _engineCapacityController.text,
              transmission: widget.vehicleDetails.transmission,
              fuelType: value,
              color: widget.vehicleDetails.color,
              seatingCapacity: _seatingCapacityController.text,
              doors: _doorsController.text,
            );
            widget.onVehicleDetailsChanged(updatedDetails);
          },
          labelText: 'Fuel Type *',
        ),
        const SizedBox(height: 16),
        FormWidgets.buildDropdown(
          value: widget.vehicleDetails.color,
          items: VehicleFormConstants.colorOptions
              .map((color) => DropdownMenuItem<String>(
                    value: color,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: VehicleFormConstants.getColorValue(color),
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
          onChanged: (value) {
            final updatedDetails = VehicleBasicDetails(
              vehicleType: widget.vehicleDetails.vehicleType,
              make: widget.vehicleDetails.make,
              model: widget.vehicleDetails.model,
              category: widget.vehicleDetails.category,
              grade: _gradeController.text,
              year: widget.vehicleDetails.year,
              vehicleNo: _vehicleNoController.text,
              chassisNo: _chassisNoController.text,
              engineNo: _engineNoController.text,
              engineCapacity: _engineCapacityController.text,
              transmission: widget.vehicleDetails.transmission,
              fuelType: widget.vehicleDetails.fuelType,
              color: value,
              seatingCapacity: _seatingCapacityController.text,
              doors: _doorsController.text,
            );
            widget.onVehicleDetailsChanged(updatedDetails);
          },
          labelText: 'Color *',
        ),
        const SizedBox(height: 16),
        FormWidgets.buildNoteContainer(
          'Note: Please put 0 when Seating Capacity & Number of Doors not applicable for your vehicle type.',
          color: Colors.amber,
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
      ],
    );
  }
}