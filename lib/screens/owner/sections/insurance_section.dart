import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../widgets/form_widgets.dart';

class InsuranceSection extends StatefulWidget {
  final VehicleInsurance insurance;
  final Function(VehicleInsurance) onInsuranceChanged;
  final String? rentMode;

  const InsuranceSection({
    super.key,
    required this.insurance,
    required this.onInsuranceChanged,
    this.rentMode,
  });

  @override
  _InsuranceSectionState createState() => _InsuranceSectionState();
}

class _InsuranceSectionState extends State<InsuranceSection> {
  late TextEditingController _securityDepositController;

  @override
  void initState() {
    super.initState();
    _securityDepositController =
        TextEditingController(text: widget.insurance.securityDeposit);
    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _securityDepositController.addListener(_updateInsurance);
  }

  void _updateInsurance() {
    final updatedInsurance = VehicleInsurance(
      hasInsurance: widget.insurance.hasInsurance,
      securityDeposit: _securityDepositController.text,
    );

    widget.onInsuranceChanged(updatedInsurance);
  }

  void _toggleInsurance(bool? value) {
    if (value != null) {
      final updatedInsurance = VehicleInsurance(
        hasInsurance: value,
        securityDeposit: _securityDepositController.text,
      );

      widget.onInsuranceChanged(updatedInsurance);
    }
  }

  bool _shouldShowSecurityDeposit() {
    return widget.rentMode == 'Vehicle Only' ||
        widget.rentMode == 'With or Without Driver';
  }

  @override
  void dispose() {
    _securityDepositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Insurance'),
        const SizedBox(height: 16),

        // Insurance checkbox
        Row(
          children: [
            Checkbox(
              value: widget.insurance.hasInsurance,
              onChanged: _toggleInsurance,
            ),
            const Text('Vehicle has rental insurance'),
          ],
        ),

        // Insurance note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Text(
            'Note: Make sure to insure your vehicle at its current market value to get the full benefit of the insurance.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.blue,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Security deposit field - only show for vehicle only or with/without driver options
        if (_shouldShowSecurityDeposit()) ...[
          FormWidgets.buildPricingField(
            controller: _securityDepositController,
            label: 'Security Deposit (LKR)',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter security deposit amount';
              }
              if (double.tryParse(value) == null || double.parse(value) < 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Security deposit will not be applied to with driver rentals.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
