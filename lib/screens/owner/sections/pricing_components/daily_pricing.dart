import 'package:flutter/material.dart';
import '../../../../models/vehicle_form_models.dart';
import '../../../../widgets/form_widgets.dart';

class DailyPricingComponent extends StatefulWidget {
  final PeriodPricing dailyPricing;
  final Function(PeriodPricing) onPricingChanged;

  const DailyPricingComponent({
    Key? key,
    required this.dailyPricing,
    required this.onPricingChanged,
  }) : super(key: key);

  @override
  _DailyPricingComponentState createState() => _DailyPricingComponentState();
}

class _DailyPricingComponentState extends State<DailyPricingComponent> {
  late TextEditingController _vehicleOnlyPriceController;
  late TextEditingController _vehicleOnlyMileageLimitController;
  late TextEditingController _vehicleOnlyExtraMileageController;
  late TextEditingController _withDriverPriceController;
  late TextEditingController _withDriverMileageLimitController;
  late TextEditingController _withDriverExtraMileageController;

  @override
  void initState() {
    super.initState();
    
    _vehicleOnlyPriceController = TextEditingController(text: widget.dailyPricing.vehicleOnlyPrice ?? '');
    _vehicleOnlyMileageLimitController = TextEditingController(text: widget.dailyPricing.vehicleOnlyMileageLimit ?? '');
    _vehicleOnlyExtraMileageController = TextEditingController(text: widget.dailyPricing.vehicleOnlyExtraMileage ?? '');
    _withDriverPriceController = TextEditingController(text: widget.dailyPricing.withDriverPrice ?? '');
    _withDriverMileageLimitController = TextEditingController(text: widget.dailyPricing.withDriverMileageLimit ?? '');
    _withDriverExtraMileageController = TextEditingController(text: widget.dailyPricing.withDriverExtraMileage ?? '');

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _vehicleOnlyPriceController.addListener(_updatePricing);
    _vehicleOnlyMileageLimitController.addListener(_updatePricing);
    _vehicleOnlyExtraMileageController.addListener(_updatePricing);
    _withDriverPriceController.addListener(_updatePricing);
    _withDriverMileageLimitController.addListener(_updatePricing);
    _withDriverExtraMileageController.addListener(_updatePricing);
  }

  void _updatePricing() {
    final PeriodPricing updatedPricing = PeriodPricing(
      vehicleOnlyPrice: _vehicleOnlyPriceController.text.isNotEmpty ? _vehicleOnlyPriceController.text : null,
      vehicleOnlyMileageLimit: _vehicleOnlyMileageLimitController.text.isNotEmpty ? _vehicleOnlyMileageLimitController.text : null,
      vehicleOnlyExtraMileage: _vehicleOnlyExtraMileageController.text.isNotEmpty ? _vehicleOnlyExtraMileageController.text : null,
      withDriverPrice: _withDriverPriceController.text.isNotEmpty ? _withDriverPriceController.text : null,
      withDriverMileageLimit: _withDriverMileageLimitController.text.isNotEmpty ? _withDriverMileageLimitController.text : null,
      withDriverExtraMileage: _withDriverExtraMileageController.text.isNotEmpty ? _withDriverExtraMileageController.text : null,
    );
    
    widget.onPricingChanged(updatedPricing);
  }

  @override
  void dispose() {
    _vehicleOnlyPriceController.dispose();
    _vehicleOnlyMileageLimitController.dispose();
    _vehicleOnlyExtraMileageController.dispose();
    _withDriverPriceController.dispose();
    _withDriverMileageLimitController.dispose();
    _withDriverExtraMileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormWidgets.buildSectionSubheader('Daily Pricing'),
            const SizedBox(height: 16),
            
            // Vehicle Only Pricing
            const Text(
              'Vehicle Only Pricing',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Price per day
            FormWidgets.buildPricingField(
              controller: _vehicleOnlyPriceController,
              label: 'Price Per Day',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter daily price';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Mileage limit
            FormWidgets.buildMileageField(
              controller: _vehicleOnlyMileageLimitController,
              label: 'Mileage Limit (km)',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mileage limit';
                }
                if (int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Extra mileage charge
            FormWidgets.buildPricingField(
              controller: _vehicleOnlyExtraMileageController,
              label: 'Extra Mileage Charge (per km)',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter extra mileage charge';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            FormWidgets.buildMileageNote(),
            const Divider(height: 32),
            
            // With Driver Pricing
            const Text(
              'With Driver Pricing',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Price per day
            FormWidgets.buildPricingField(
              controller: _withDriverPriceController,
              label: 'Price Per Day (With Driver)',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter daily price with driver';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Mileage limit
            FormWidgets.buildMileageField(
              controller: _withDriverMileageLimitController,
              label: 'Mileage Limit (km)',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mileage limit';
                }
                if (int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Extra mileage charge
            FormWidgets.buildPricingField(
              controller: _withDriverExtraMileageController,
              label: 'Extra Mileage Charge (per km)',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter extra mileage charge';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            FormWidgets.buildMileageNote(),
          ],
        ),
      ),
    );
  }
}