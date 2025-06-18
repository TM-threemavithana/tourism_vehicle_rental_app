import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../widgets/form_widgets.dart';

class OwnerDetailsSection extends StatefulWidget {
  final OwnerDetails ownerDetails;
  final Function(OwnerDetails) onOwnerDetailsChanged;

  const OwnerDetailsSection({
    super.key,
    required this.ownerDetails,
    required this.onOwnerDetailsChanged,
  });

  @override
  _OwnerDetailsSectionState createState() => _OwnerDetailsSectionState();
}

class _OwnerDetailsSectionState extends State<OwnerDetailsSection> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactNoController;
  late TextEditingController _emailController;
  late TextEditingController _nicNoController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ownerDetails.name);
    _addressController =
        TextEditingController(text: widget.ownerDetails.address);
    _contactNoController =
        TextEditingController(text: widget.ownerDetails.contactNo);
    _emailController = TextEditingController(text: widget.ownerDetails.email);
    _nicNoController = TextEditingController(text: widget.ownerDetails.nicNo);

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _nameController.addListener(_updateOwnerDetails);
    _addressController.addListener(_updateOwnerDetails);
    _contactNoController.addListener(_updateOwnerDetails);
    _emailController.addListener(_updateOwnerDetails);
    _nicNoController.addListener(_updateOwnerDetails);
  }

  void _updateOwnerDetails() {
    final updatedDetails = OwnerDetails(
      name: _nameController.text,
      address: _addressController.text,
      contactNo: _contactNoController.text,
      email: _emailController.text,
      nicNo: _nicNoController.text,
    );

    widget.onOwnerDetailsChanged(updatedDetails);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactNoController.dispose();
    _emailController.dispose();
    _nicNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Current Owner Details'),
        const SizedBox(height: 16),

        // Owner name field
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter owner\'s full name'
              : null,
        ),
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
              ? 'Please enter owner\'s address'
              : null,
        ),
        const SizedBox(height: 16),

        // Contact No. field
        TextFormField(
          controller: _contactNoController,
          decoration: const InputDecoration(
            labelText: 'Contact No. *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter owner\'s contact number'
              : null,
        ),
        const SizedBox(height: 16),

        // Email field
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter owner\'s email';
            }
            // Basic email validation regex
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // NIC No. field
        TextFormField(
          controller: _nicNoController,
          decoration: const InputDecoration(
            labelText: 'NIC No. *',
            border: OutlineInputBorder(),
            hintText: 'National Identity Card Number',
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter owner\'s NIC number'
              : null,
        ),
      ],
    );
  }
}
