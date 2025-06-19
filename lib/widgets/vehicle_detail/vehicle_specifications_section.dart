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

          
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              // Row 1
              _buildSpecItem(
                context,
                icon: Icons.calendar_today_rounded,
                title: 'Year',
                value: vehicleDetails['year'] ?? 'N/A',
                iconColor: Colors.indigo,
              ),
              _buildSpecItem(
                context,
                icon: Icons.door_sliding_rounded,
                title: 'Doors',
                value: vehicleDetails['doors']?.toString() ?? 'N/A',
                iconColor: Colors.teal,
              ),
              _buildSpecItem(
                context,
                icon: Icons.airline_seat_recline_normal_rounded,
                title: 'Seats',
                value: vehicleDetails['seatingCapacity']?.toString() ?? 'N/A',
                iconColor: Colors.amber,
              ),

              // Row 2
              _buildSpecItem(
                context,
                icon: Icons.settings_rounded,
                title: 'Transmission',
                value: vehicleDetails['transmission'] ?? 'N/A',
                iconColor: Colors.deepPurple,
              ),
              _buildSpecItem(
                context,
                icon: Icons.local_gas_station_rounded,
                title: 'Fuel Type',
                value: vehicleDetails['fuelType'] ?? 'N/A',
                iconColor: Colors.red,
              ),
              _buildSpecItem(
                context,
                icon: Icons.speed_rounded,
                title: 'Engine',
                value: '${vehicleDetails['engineCapacity'] ?? 'N/A'} cc',
                iconColor: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with circular background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 4),

          // Value
          Text(
            value,
            textAlign: TextAlign.center,
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
