
import 'package:flutter/material.dart';
import '../../helpers/car_logo_helper.dart';

class VehicleInfoHeader extends StatelessWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleInfoHeader({
    super.key,
    required this.vehicleDetails,
  });

  @override
  Widget build(BuildContext context) {
    final make = vehicleDetails['make'] as String?;
    final model = vehicleDetails['model'] as String?;
    final year = vehicleDetails['year'] as String?;
    final category = vehicleDetails['category'] as String?;
    
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand logo
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: CarLogoHelper.getCarLogo(make),
          ),
          
          const SizedBox(width: 16),
          
          // Vehicle info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Make and model
                Text(
                  '${make ?? ''} ${model ?? ''}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Year and category
                Text(
                  '${year ?? ''} ${category ?? ''}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                
                // Rating if available
                if (vehicleDetails['rating'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < (vehicleDetails['rating'] as num).floor()
                              ? Icons.star
                              : Icons.star_border,
                          size: 18,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${vehicleDetails['reviewsCount'] ?? 0} reviews)',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Daily rate
          if (vehicleDetails['pricing']?['daily']?['vehicleOnly']?['price'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LKR ${vehicleDetails['pricing']['daily']['vehicleOnly']['price']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'per day',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}