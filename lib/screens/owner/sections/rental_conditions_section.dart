import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../utils/form_data_constants.dart';
import '../../../widgets/form_widgets.dart';

class RentalConditionsSection extends StatefulWidget {
  final RentalConditions rentalConditions;
  final Function(RentalConditions) onRentalConditionsChanged;

  const RentalConditionsSection({
    Key? key,
    required this.rentalConditions,
    required this.onRentalConditionsChanged,
  }) : super(key: key);

  @override
  _RentalConditionsSectionState createState() =>
      _RentalConditionsSectionState();
}

class _RentalConditionsSectionState extends State<RentalConditionsSection> {
  late TextEditingController _minRentalPeriodController;
  late TextEditingController _maxRentalPeriodController;
  late TextEditingController _advanceRentalPeriodController;

  @override
  void initState() {
    super.initState();
    _minRentalPeriodController = TextEditingController(
        text: widget.rentalConditions.minRentalPeriod.value);
    _maxRentalPeriodController = TextEditingController(
        text: widget.rentalConditions.maxRentalPeriod.value);
    _advanceRentalPeriodController = TextEditingController(
        text: widget.rentalConditions.advanceRentalPeriod.value);

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _minRentalPeriodController.addListener(_updateRentalConditions);
    _maxRentalPeriodController.addListener(_updateRentalConditions);
    _advanceRentalPeriodController.addListener(_updateRentalConditions);
  }

  void _updateRentalConditions() {
    final updatedConditions = RentalConditions(
      minRentalPeriod: RentalPeriod(
        value: _minRentalPeriodController.text,
        unit: widget.rentalConditions.minRentalPeriod.unit,
      ),
      maxRentalPeriod: RentalPeriod(
        value: _maxRentalPeriodController.text,
        unit: widget.rentalConditions.maxRentalPeriod.unit,
      ),
      advanceRentalPeriod: RentalPeriod(
        value: _advanceRentalPeriodController.text,
        unit: widget.rentalConditions.advanceRentalPeriod.unit,
      ),
      rentMode: widget.rentalConditions.rentMode,
      // Keep the existing rentalPeriods but don't show UI for it
      rentalPeriods: widget.rentalConditions.rentalPeriods,
    );

    widget.onRentalConditionsChanged(updatedConditions);
  }

  @override
  void dispose() {
    _minRentalPeriodController.dispose();
    _maxRentalPeriodController.dispose();
    _advanceRentalPeriodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Rental Conditions'),
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
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
                    value: widget.rentalConditions.minRentalPeriod.unit,
                    items: VehicleFormConstants.timeUnits
                        .map((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final updatedConditions = RentalConditions(
                          minRentalPeriod: RentalPeriod(
                            value: _minRentalPeriodController.text,
                            unit: value,
                          ),
                          maxRentalPeriod:
                              widget.rentalConditions.maxRentalPeriod,
                          advanceRentalPeriod:
                              widget.rentalConditions.advanceRentalPeriod,
                          rentMode: widget.rentalConditions.rentMode,
                          rentalPeriods: widget.rentalConditions.rentalPeriods,
                        );
                        widget.onRentalConditionsChanged(updatedConditions);
                      }
                    },
                    hint: const Text('Unit'),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
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
                    value: widget.rentalConditions.maxRentalPeriod.unit,
                    items: VehicleFormConstants.timeUnits
                        .map((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final updatedConditions = RentalConditions(
                          minRentalPeriod:
                              widget.rentalConditions.minRentalPeriod,
                          maxRentalPeriod: RentalPeriod(
                            value: _maxRentalPeriodController.text,
                            unit: value,
                          ),
                          advanceRentalPeriod:
                              widget.rentalConditions.advanceRentalPeriod,
                          rentMode: widget.rentalConditions.rentMode,
                          rentalPeriods: widget.rentalConditions.rentalPeriods,
                        );
                        widget.onRentalConditionsChanged(updatedConditions);
                      }
                    },
                    hint: const Text('Unit'),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
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
                    value: widget.rentalConditions.advanceRentalPeriod.unit,
                    items: VehicleFormConstants.timeUnits
                        .map((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final updatedConditions = RentalConditions(
                          minRentalPeriod:
                              widget.rentalConditions.minRentalPeriod,
                          maxRentalPeriod:
                              widget.rentalConditions.maxRentalPeriod,
                          advanceRentalPeriod: RentalPeriod(
                            value: _advanceRentalPeriodController.text,
                            unit: value,
                          ),
                          rentMode: widget.rentalConditions.rentMode,
                          rentalPeriods: widget.rentalConditions.rentalPeriods,
                        );
                        widget.onRentalConditionsChanged(updatedConditions);
                      }
                    },
                    hint: const Text('Unit'),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Note: The advance notice period is the minimum notice period for booking a vehicle.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Rent Mode
        FormWidgets.buildDropdown(
          value: widget.rentalConditions.rentMode,
          items: VehicleFormConstants.rentModeOptions
              .map((mode) => DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode),
                  ))
              .toList(),
          onChanged: (value) {
            final updatedConditions = RentalConditions(
              minRentalPeriod: widget.rentalConditions.minRentalPeriod,
              maxRentalPeriod: widget.rentalConditions.maxRentalPeriod,
              advanceRentalPeriod: widget.rentalConditions.advanceRentalPeriod,
              rentMode: value,
              rentalPeriods: widget.rentalConditions.rentalPeriods,
            );
            widget.onRentalConditionsChanged(updatedConditions);
          },
          labelText: 'Rent Mode *',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
