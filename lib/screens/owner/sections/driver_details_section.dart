import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../widgets/form_widgets.dart';

class DriverDetailsSection extends StatefulWidget {
  final DriverDetails driverDetails;
  final Function(DriverDetails) onDriverDetailsChanged;
  final String? rentMode;

  const DriverDetailsSection({
    super.key,
    required this.driverDetails,
    required this.onDriverDetailsChanged,
    this.rentMode,
  });

  @override
  _DriverDetailsSectionState createState() => _DriverDetailsSectionState();
}

class _DriverDetailsSectionState extends State<DriverDetailsSection> {
  late TextEditingController _driverNameController;
  late TextEditingController _driverLicenseController;
  late TextEditingController _driverWhatsappController;

  @override
  void initState() {
    super.initState();
    _driverNameController =
        TextEditingController(text: widget.driverDetails.name);
    _driverLicenseController =
        TextEditingController(text: widget.driverDetails.licenseNo);
    _driverWhatsappController =
        TextEditingController(text: widget.driverDetails.whatsappNumber ?? '');

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _driverNameController.addListener(_updateDriverDetails);
    _driverLicenseController.addListener(_updateDriverDetails);
    _driverWhatsappController.addListener(_updateDriverDetails);
  }

  void _updateDriverDetails() {
    final updatedDetails = DriverDetails(
      name: _driverNameController.text,
      licenseNo: _driverLicenseController.text,
      whatsappNumber: _driverWhatsappController.text,
    );

    widget.onDriverDetailsChanged(updatedDetails);
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverLicenseController.dispose();
    _driverWhatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showDriverFields = widget.rentMode != 'Vehicle Only';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Driver & Contact Details'),
        const SizedBox(height: 16),
        // Always show WhatsApp number as main contact
        TextFormField(
          controller: _driverWhatsappController,
          decoration: InputDecoration(
            labelText: 'Vehicle WhatsApp Number',
            border: OutlineInputBorder(),
            fillColor: Colors.white,
            filled: true,
            hintText: 'e.g. +94771234567',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a WhatsApp number for this vehicle';
            }
            final phoneRegex = RegExp(r'^\+?\d{9,15}\$');
            if (!phoneRegex.hasMatch(value)) {
              return 'Enter a valid WhatsApp number';
            }
            return null;
          },
        ),
        if (showDriverFields) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _driverNameController,
            decoration: InputDecoration(
              labelText: 'Driver Name *',
              border: OutlineInputBorder(),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter driver name'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _driverLicenseController,
            decoration: InputDecoration(
              labelText: 'Driver License Number *',
              border: OutlineInputBorder(),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter driver license number'
                : null,
          ),
        ],
      ],
    );
  }
}
