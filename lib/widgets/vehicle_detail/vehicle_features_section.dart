import 'package:flutter/material.dart';
import '../../helpers/feature_icon_helper.dart';

class VehicleFeaturesSection extends StatelessWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleFeaturesSection({
    super.key,
    required this.vehicleDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Extract features that are set to true
    final Map<String, dynamic>? features =
        vehicleDetails['extras']?['features'] as Map<String, dynamic>?;

    final List<String> activeFeatures = [];

    if (features != null) {
      features.forEach((key, value) {
        if (value == true) {
          activeFeatures.add(key);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features & Extras',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (activeFeatures.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No features specified',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeFeatures.map((feature) {
                return Chip(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  avatar: Icon(
                    FeatureIconHelper.getFeatureIcon(feature),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    feature,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
