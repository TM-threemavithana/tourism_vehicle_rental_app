import 'package:flutter/material.dart';
import '../../helpers/car_logo_helper.dart';
import '../../utils/app_colors.dart';

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
    final rating = vehicleDetails['rating'] as num?;
    final reviewsCount = vehicleDetails['reviewsCount'] as int? ?? 0;
    final tripsCount = vehicleDetails['tripsCount'] as int? ?? 0;

    
    final district = vehicleDetails['collectionPoint']?['district'] as String?;
    

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with brand logo and price
          Row(
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
                      overflow: TextOverflow.ellipsis,
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
                  ],
                ),
              ),

              // Daily rate
              if (vehicleDetails['pricing']?['daily']?['vehicleOnly']
                      ?['price'] !=
                  null)
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

          const SizedBox(height: 16),

          // Stats row (rating, trips, location)
          Row(
            children: [
              // Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating != null
                              ? '${rating.toStringAsFixed(1)}/5'
                              : 'New',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewsCount)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trips count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trips',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$tripsCount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tripsCount == 1 ? 'trip' : 'trips',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  district ?? 'Location not specified',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
