import 'package:flutter/material.dart';
import '../../utils/form_data_constants.dart';
import '../../widgets/form_widgets.dart';

class VehicleDetailsSection extends StatefulWidget {
  final String? vehicleType;
  final String? selectedMake;
  final String? selectedModel;
  final String? selectedCategory;
  final TextEditingController gradeController;
  final String? selectedYear;
  final TextEditingController vehicleNoController;
  final TextEditingController chassisNoController;
  final TextEditingController engineNoController;
  final TextEditingController engineCapacityController;
  final String? transmission;
  final String? fuelType;
  final String? color;
  final TextEditingController seatingCapacityController;
  final TextEditingController doorsController;
  final Function(String?) onVehicleTypeChanged;
  final Function(String?) onMakeChanged;
  final Function(String?) onModelChanged;
  final Function(String?) onCategoryChanged;
  final Function(String?) onYearChanged;
  final Function(String?) onTransmissionChanged;
  final Function(String?) onFuelTypeChanged;
  final Function(String?) onColorChanged;

  const VehicleDetailsSection({
    Key? key,
    required this.vehicleType,
    required this.selectedMake,
    required this.selectedModel,
    required this.selectedCategory,
    required this.gradeController,
    required this.selectedYear,
    required this.vehicleNoController,
    required this.chassisNoController,
    required this.engineNoController,
    required this.engineCapacityController,
    required this.transmission,
    required this.fuelType,
    required this.color,
    required this.seatingCapacityController,
    required this.doorsController,
    required this.onVehicleTypeChanged,
    required this.onMakeChanged,
    required this.onModelChanged,
    required this.onCategoryChanged,
    required this.onYearChanged,
    required this.onTransmissionChanged,
    required this.onFuelTypeChanged,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<VehicleDetailsSection> createState() => _VehicleDetailsSectionState();
}

class _VehicleDetailsSectionState extends State<VehicleDetailsSection> {
  final List<String> _yearOptions = VehicleFormConstants.generateYearOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Vehicle Details'),
        const SizedBox(height: 16),
        
        // Vehicle type dropdown
        FormWidgets.buildDropdown(
          value: widget.vehicleType,
          items: VehicleFormConstants.vehicleTypes.map((type) => 
            DropdownMenuItem<String>(value: type, child: Text(type))
          ).toList(),
          onChanged: widget.onVehicleTypeChanged,
          labelText: 'Vehicle Type *',
        ),
        const SizedBox(height: 16),
        
        // Make/Brand dropdown
        FormWidgets.buildDropdown(
          value: widget.selectedMake,
          items: widget.vehicleType != null
              ? VehicleFormConstants.makesMap[widget.vehicleType]!
                  .map((make) => DropdownMenuItem<String>(value: make, child: Text(make)))
                  .toList()
              : [],
          onChanged: widget.onMakeChanged,
          labelText: 'Make/Brand *',
        ),
        const SizedBox(height: 16),
        
        // Model dropdown
        FormWidgets.buildDropdown(
          value: widget.selectedModel,
          items: (widget.vehicleType != null &&
                  widget.selectedMake != null &&
                  VehicleFormConstants.modelsMap[widget.vehicleType]?[widget.selectedMake] != null)
              ? VehicleFormConstants.modelsMap[widget.vehicleType]![widget.selectedMake]!
                  .map((model) => DropdownMenuItem<String>(value: model, child: Text(model)))
                  .toList()
              : [],
          onChanged: widget.onModelChanged,
          labelText: 'Model *',
        ),
        const SizedBox(height: 16),
        
        // Category dropdown
        FormWidgets.buildDropdown(
          value: widget.selectedCategory,
          items: widget.vehicleType != null
              ? VehicleFormConstants.categoriesMap[widget.vehicleType]!
                  .map((category) => DropdownMenuItem<String>(value: category, child: Text(category)))
                  .toList()
              : [],
          onChanged: widget.onCategoryChanged,
          labelText: 'Category *',
        ),
        const SizedBox(height: 16),
        
        // Grade field
        TextFormField(
          controller: widget.gradeController,
          decoration: const InputDecoration(
            labelText: 'Grade',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Year dropdown
        FormWidgets.buildDropdown(
          value: widget.selectedYear,
          items: _yearOptions.map((year) => 
            DropdownMenuItem<String>(value: year, child: Text(year))
          ).toList(),
          onChanged: widget.onYearChanged,
          labelText: 'Year of Manufacture *',
        ),
        const SizedBox(height: 16),
        
        // Vehicle Number field
        TextFormField(
          controller: widget.vehicleNoController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Number *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter vehicle number'
              : null,
        ),
        const SizedBox(height: 16),
        
        // Chassis Number field
        TextFormField(
          controller: widget.chassisNoController,
          decoration: const InputDecoration(
            labelText: 'Chassis Number *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter chassis number'
              : null,
        ),
        const SizedBox(height: 16),
        
        // Engine Number field
        TextFormField(
          controller: widget.engineNoController,
          decoration: const InputDecoration(
            labelText: 'Engine Number *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter engine number'
              : null,
        ),
        const SizedBox(height: 16),
        
        // Engine Capacity field
        TextFormField(
          controller: widget.engineCapacityController,
          decoration: const InputDecoration(
            labelText: 'Engine Capacity (cc) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter engine capacity';
            }
            if (int.tryParse(value) == null || int.parse(value) < 0) {
              return 'Please enter a valid non-negative number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Transmission dropdown
        FormWidgets.buildDropdown(
          value: widget.transmission,
          items: VehicleFormConstants.transmissionOptions.map((transmission) => 
            DropdownMenuItem<String>(value: transmission, child: Text(transmission))
          ).toList(),
          onChanged: widget.onTransmissionChanged,
          labelText: 'Transmission *',
        ),
        const SizedBox(height: 16),
        
        // Fuel Type dropdown
        FormWidgets.buildDropdown(
          value: widget.fuelType,
          items: VehicleFormConstants.fuelTypeOptions.map((fuel) => 
            DropdownMenuItem<String>(value: fuel, child: Text(fuel))
          ).toList(),
          onChanged: widget.onFuelTypeChanged,
          labelText: 'Fuel Type *',
        ),
        const SizedBox(height: 16),
        
        // Color dropdown
        FormWidgets.buildDropdown(
          value: widget.color,
          items: VehicleFormConstants.colorOptions.map((color) => 
            DropdownMenuItem<String>(value: color, child: Text(color))
          ).toList(),
          onChanged: widget.onColorChanged,
          labelText: 'Color *',
        ),
        const SizedBox(height: 16),
        
        // Note about seating capacity and doors
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: const Text(
            'Note: Please put 0 when Seating Capacity & Number of Doors not applicable for your vehicle type.',
            style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),
        
        // Seating Capacity field
        TextFormField(
          controller: widget.seatingCapacityController,
          decoration: const InputDecoration(
            labelText: 'Seating Capacity *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter seating capacity';
            }
            if (int.tryParse(value) == null || int.parse(value) < 0) {
              return 'Please enter a valid non-negative number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Number of Doors field
        TextFormField(
          controller: widget.doorsController,
          decoration: const InputDecoration(
            labelText: 'Number of Doors *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of doors';
            }
            if (int.tryParse(value) == null || int.parse(value) < 0) {
              return 'Please enter a valid non-negative number';
            }
            return null;
          },
        ),
      ],
    );
  }
}