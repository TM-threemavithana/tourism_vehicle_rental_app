import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../widgets/form_widgets.dart';
import '../../../utils/form_data_constants.dart';
import 'pricing_components/hourly_pricing.dart';
import 'pricing_components/daily_pricing.dart';
import 'pricing_components/weekly_pricing.dart';
import 'pricing_components/monthly_pricing.dart';

class PricingSection extends StatefulWidget {
  final VehiclePricing pricing;
  final Function(VehiclePricing) onPricingChanged;
  final String? rentMode;

  const PricingSection({
    Key? key,
    required this.pricing,
    required this.onPricingChanged,
    required this.rentMode,
  }) : super(key: key);

  @override
  _PricingSectionState createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  late TextEditingController _vehicleValueController;

  @override
  void initState() {
    super.initState();
    _vehicleValueController =
        TextEditingController(text: widget.pricing.vehicleValue);

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _vehicleValueController.addListener(_updatePricing);
  }

  void _updatePricing() {
    final updatedPricing = VehiclePricing(
      vehicleValue: _vehicleValueController.text,
      rentalPeriods: widget.pricing.rentalPeriods,
      hourly: widget.pricing.hourly,
      daily: widget.pricing.daily,
      weekly: widget.pricing.weekly,
      monthly: widget.pricing.monthly,
    );

    widget.onPricingChanged(updatedPricing);
  }

  void _togglePeriod(String period) {
    if (widget.rentMode == null) {
      // Show message that rent mode must be selected first
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rent mode first')));
      return;
    }

    Map<String, bool> updatedPeriods = Map.from(widget.pricing.rentalPeriods);
    updatedPeriods[period] = !updatedPeriods[period]!;

    final updatedPricing = VehiclePricing(
      vehicleValue: widget.pricing.vehicleValue,
      rentalPeriods: updatedPeriods,
      hourly: widget.pricing.hourly,
      daily: widget.pricing.daily,
      weekly: widget.pricing.weekly,
      monthly: widget.pricing.monthly,
    );

    widget.onPricingChanged(updatedPricing);
  }

  bool _isAnyRentalPeriodSelected() {
    return widget.pricing.rentalPeriods.values.contains(true);
  }

  @override
  void dispose() {
    _vehicleValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Pricing'),
        const SizedBox(height: 16),

        // If no rent mode is selected, only show the notice
        if (widget.rentMode == null) ...[
          // This is the only thing shown when no rent mode is selected
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
        ] else ...[
          // Vehicle Value field - always shown if rent mode is selected
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
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Rental Period Selection section
          const Text(
            'Please select at least one rental time period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Display rental period options as chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VehicleFormConstants.rentalPeriods.map((period) {
              final isSelected = widget.pricing.rentalPeriods[period] ?? false;

              return FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) => _togglePeriod(period),
                selectedColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Show pricing components based on selected periods
          if (!_isAnyRentalPeriodSelected()) ...[
            // Message to select at least one rental period
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
            // Show pricing forms based on rent mode and selected rental periods

            // Hourly pricing section
            if (widget.pricing.rentalPeriods['Hourly'] == true) ...[
              HourlyPricingComponent(
                hourlyPricing: widget.pricing.hourly ?? PeriodPricing(),
                onPricingChanged: (pricing) {
                  final updatedPricing = VehiclePricing(
                    vehicleValue: widget.pricing.vehicleValue,
                    rentalPeriods: widget.pricing.rentalPeriods,
                    hourly: pricing,
                    daily: widget.pricing.daily,
                    weekly: widget.pricing.weekly,
                    monthly: widget.pricing.monthly,
                  );
                  widget.onPricingChanged(updatedPricing);
                },
                rentMode: widget.rentMode, // Pass the rent mode
              ),
            ],

            // Daily pricing section
            if (widget.pricing.rentalPeriods['Daily'] == true) ...[
              DailyPricingComponent(
                dailyPricing: widget.pricing.daily ?? PeriodPricing(),
                onPricingChanged: (pricing) {
                  final updatedPricing = VehiclePricing(
                    vehicleValue: widget.pricing.vehicleValue,
                    rentalPeriods: widget.pricing.rentalPeriods,
                    hourly: widget.pricing.hourly,
                    daily: pricing,
                    weekly: widget.pricing.weekly,
                    monthly: widget.pricing.monthly,
                  );
                  widget.onPricingChanged(updatedPricing);
                },
                rentMode: widget.rentMode, // Pass the rent mode
              ),
            ],

            // Weekly pricing section
            if (widget.pricing.rentalPeriods['Weekly'] == true) ...[
              WeeklyPricingComponent(
                weeklyPricing: widget.pricing.weekly ?? PeriodPricing(),
                onPricingChanged: (pricing) {
                  final updatedPricing = VehiclePricing(
                    vehicleValue: widget.pricing.vehicleValue,
                    rentalPeriods: widget.pricing.rentalPeriods,
                    hourly: widget.pricing.hourly,
                    daily: widget.pricing.daily,
                    weekly: pricing,
                    monthly: widget.pricing.monthly,
                  );
                  widget.onPricingChanged(updatedPricing);
                },
                rentMode: widget.rentMode,
              ),
            ],

            // Monthly pricing section
            if (widget.pricing.rentalPeriods['Monthly'] == true) ...[
              MonthlyPricingComponent(
                monthlyPricing: widget.pricing.monthly ?? PeriodPricing(),
                onPricingChanged: (pricing) {
                  final updatedPricing = VehiclePricing(
                    vehicleValue: widget.pricing.vehicleValue,
                    rentalPeriods: widget.pricing.rentalPeriods,
                    hourly: widget.pricing.hourly,
                    daily: widget.pricing.daily,
                    weekly: widget.pricing.weekly,
                    monthly: pricing,
                  );
                  widget.onPricingChanged(updatedPricing);
                },
                rentMode: widget.rentMode,
              ),
            ],
          ],
        ],
      ],
    );
  }
}
