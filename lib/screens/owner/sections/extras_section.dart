import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../widgets/form_widgets.dart';

class ExtrasSection extends StatefulWidget {
  final VehicleExtras extras;
  final Function(VehicleExtras) onExtrasChanged;
  final VehicleBasicDetails vehicleDetails;

  const ExtrasSection({
    super.key,
    required this.extras,
    required this.onExtrasChanged,
    required this.vehicleDetails,
  });

  @override
  _ExtrasSectionState createState() => _ExtrasSectionState();
}

class _ExtrasSectionState extends State<ExtrasSection> {
  bool _isVehicleModelSelected() {
    return widget.vehicleDetails.vehicleType != null &&
        widget.vehicleDetails.make != null &&
        widget.vehicleDetails.model != null;
  }

  void _toggleFeature(String feature) {
    if (!_isVehicleModelSelected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle model first')),
      );
      return;
    }

    Map<String, bool> updatedFeatures = Map.from(widget.extras.features);
    updatedFeatures[feature] = !updatedFeatures[feature]!;

    final updatedExtras = VehicleExtras(features: updatedFeatures);
    widget.onExtrasChanged(updatedExtras);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Vehicle Extras'),
        const SizedBox(height: 16),
        if (!_isVehicleModelSelected()) ...[
          // Show message when no vehicle model is selected
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: const Text(
              'Please select a vehicle model to view extras',
              style: TextStyle(
                color: Colors.amber,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ] else ...[
          // Show available extras when vehicle model is selected
          const Text(
            'Select all extras that are available with this vehicle:',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.extras.features.entries.map((entry) {
              final feature = entry.key;
              final isSelected = entry.value;

              return FilterChip(
                label: Text(feature),
                selected: isSelected,
                onSelected: (_) => _toggleFeature(feature),
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
