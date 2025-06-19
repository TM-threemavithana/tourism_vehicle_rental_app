import 'package:flutter/material.dart';

class VehicleSpecificationsSection extends StatelessWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleSpecificationsSection({
    super.key,
    required this.vehicleDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Grid of specifications
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            children: [
              _buildSpecCard(
                context,
                icon: Icons.speed,
                title: 'Engine',
                value: '${vehicleDetails['engineCapacity'] ?? 'N/A'} cc',
              ),
              _buildSpecCard(
                context,
                icon: Icons.settings,
                title: 'Transmission',
                value: vehicleDetails['transmission'] ?? 'N/A',
              ),
              _buildSpecCard(
                context,
                icon: Icons.local_gas_station,
                title: 'Fuel Type',
                value: vehicleDetails['fuelType'] ?? 'N/A',
              ),
              _buildSpecCard(
                context,
                icon: Icons.event_seat,
                title: 'Seats',
                value: vehicleDetails['seatingCapacity']?.toString() ?? 'N/A',
              ),
              _buildSpecCard(
                context,
                icon: Icons.door_back_door,
                title: 'Doors',
                value: vehicleDetails['doors']?.toString() ?? 'N/A',
              ),
              _buildSpecCard(
                context,
                icon: Icons.color_lens,
                title: 'Color',
                value: vehicleDetails['color'] ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
