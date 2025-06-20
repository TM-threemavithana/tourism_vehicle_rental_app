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

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Extras & Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Wrap widget for feature chips
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              // Common features with real data checks
              if (_getFeatureValue('Alloys'))
                _buildFeatureChip(context, 'Alloys'),
              if (_getFeatureValue('Spoiler'))
                _buildFeatureChip(context, 'Spoiler'),
              if (_getFeatureValue('Rear Wiper'))
                _buildFeatureChip(context, 'Rear Wiper'),
              if (_getFeatureValue('Rear Defroster'))
                _buildFeatureChip(context, 'Rear Defroster'),
              if (_getFeatureValue('Power Steering'))
                _buildFeatureChip(context, 'Power Steering'),
              if (_getFeatureValue('USB')) _buildFeatureChip(context, 'USB'),
              if (_getFeatureValue('AWD')) _buildFeatureChip(context, 'AWD'),
              if (_getFeatureValue('Tyre Repair Kit'))
                _buildFeatureChip(context, 'Tyre Repair Kit'),
              if (_getFeatureValue('Power Shutters'))
                _buildFeatureChip(context, 'Power Shutters'),
              if (_getFeatureValue('Power Mirrors'))
                _buildFeatureChip(context, 'Power Mirrors'),
              if (_getFeatureValue('Power Locks'))
                _buildFeatureChip(context, 'Power Locks'),
              if (_getFeatureValue('Navigation'))
                _buildFeatureChip(context, 'Navigation'),
              if (_getFeatureValue('Multi Functional Steering'))
                _buildFeatureChip(context, 'Multi Functional Steering'),
              if (_getFeatureValue('Keyless Entry'))
                _buildFeatureChip(context, 'Keyless Entry'),
              if (_getFeatureValue('DVD')) _buildFeatureChip(context, 'DVD'),
              if (_getFeatureValue('Cruise Control'))
                _buildFeatureChip(context, 'Cruise Control'),
              if (_getFeatureValue('Airbag Passenger'))
                _buildFeatureChip(context, 'Airbag Passenger'),
              if (_getFeatureValue('Airbag Driver'))
                _buildFeatureChip(context, 'Airbag Driver'),
            ],
          ),

          // If no features are available, show a message
          if (_checkNoFeaturesEnabled())
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 36,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No extra features specified for this vehicle',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, String feature) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FeatureIconHelper.getFeatureIcon(feature),
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              feature,
              style: TextStyle(
                color: isDarkMode ? Colors.white : theme.colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _getFeatureValue(String feature) {
    // First check if feature exists directly in extras
    if (vehicleDetails['extras']?[feature] == true) {
      return true;
    }

    // Then check in the features map structure
    final features =
        vehicleDetails['extras']?['features'] as Map<String, dynamic>?;
    return features?[feature] == true;
  }

  bool _checkNoFeaturesEnabled() {
    // Check both structures
    bool noDirectFeatures = true;
    bool noMapFeatures = true;

    // Check direct extras
    if (vehicleDetails['extras'] is Map<String, dynamic>) {
      final Map<String, dynamic> extras =
          vehicleDetails['extras'] as Map<String, dynamic>;

      for (final key in extras.keys) {
        if (key != 'features' && extras[key] == true) {
          noDirectFeatures = false;
          break;
        }
      }
    }

    // Check features map
    final features =
        vehicleDetails['extras']?['features'] as Map<String, dynamic>?;
    if (features != null) {
      for (final key in features.keys) {
        if (features[key] == true) {
          noMapFeatures = false;
          break;
        }
      }
    }

    return noDirectFeatures && noMapFeatures;
  }
}
