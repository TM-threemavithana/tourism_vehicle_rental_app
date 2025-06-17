import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../widgets/form_widgets.dart';

class DriverDetailsSection extends StatefulWidget {
  final DriverDetails driverDetails;
  final Function(DriverDetails) onDriverDetailsChanged;

  const DriverDetailsSection({
    super.key,
    required this.driverDetails,
    required this.onDriverDetailsChanged,
  });

  @override
  _DriverDetailsSectionState createState() => _DriverDetailsSectionState();
}

class _DriverDetailsSectionState extends State<DriverDetailsSection> {
  late TextEditingController _driverNameController;
  late TextEditingController _driverLicenseController;

  @override
  void initState() {
    super.initState();
    _driverNameController = TextEditingController(text: widget.driverDetails.name);
    _driverLicenseController = TextEditingController(text: widget.driverDetails.licenseNo);

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _driverNameController.addListener(_updateDriverDetails);
    _driverLicenseController.addListener(_updateDriverDetails);
  }

  void _updateDriverDetails() {
    final updatedDetails = DriverDetails(
      name: _driverNameController.text,
      licenseNo: _driverLicenseController.text,
    );
    
    widget.onDriverDetailsChanged(updatedDetails);
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverLicenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Driver Details'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _driverNameController,
          decoration: const InputDecoration(
            labelText: 'Driver Name *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter driver name'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _driverLicenseController,
          decoration: const InputDecoration(
            labelText: 'Driver License Number *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter driver license number'
              : null,
        ),
      ],
    );
  }
}