import 'package:flutter/material.dart';

class RentalInfoSection extends StatelessWidget {
  final Map<String, dynamic> vehicleDetails;

  const RentalInfoSection({
    super.key,
    required this.vehicleDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pricing = vehicleDetails['pricing'];
    final rentalConditions = vehicleDetails['rentalConditions'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rental Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Rental conditions
          if (rentalConditions != null) ...[
            _buildSubheading(context, 'Rental Conditions'),
            _buildInfoRow(
              context,
              label: 'Rent Mode',
              value: rentalConditions['rentMode'] ?? 'Not specified',
            ),
            if (rentalConditions['minRentalPeriod'] != null)
              _buildInfoRow(
                context,
                label: 'Minimum Rental Period',
                value:
                    '${rentalConditions['minRentalPeriod']['value']} ${rentalConditions['minRentalPeriod']['unit']}',
              ),
            if (rentalConditions['maxRentalPeriod'] != null)
              _buildInfoRow(
                context,
                label: 'Maximum Rental Period',
                value:
                    '${rentalConditions['maxRentalPeriod']['value']} ${rentalConditions['maxRentalPeriod']['unit']}',
              ),
            if (rentalConditions['advanceRentalPeriod'] != null)
              _buildInfoRow(
                context,
                label: 'Advance Booking Period',
                value:
                    '${rentalConditions['advanceRentalPeriod']['value']} ${rentalConditions['advanceRentalPeriod']['unit']}',
              ),
            const SizedBox(height: 16),
          ],

          // Available rental periods
          if (pricing != null && pricing['rentalPeriods'] != null) ...[
            _buildSubheading(context, 'Available Rental Periods'),
            for (final period in ['hourly', 'daily', 'weekly', 'monthly'])
              if (pricing['rentalPeriods'][period] == true)
                _buildInfoRow(
                  context,
                  label: _capitalize(period),
                  value: 'Available',
                ),
            const SizedBox(height: 16),
          ],

          // Pricing details - rates for daily rental
          if (pricing != null && pricing['daily'] != null) ...[
            _buildSubheading(context, 'Daily Rates'),

            // Vehicle only
            if (pricing['daily']['vehicleOnly'] != null)
              _buildPricingCard(
                context,
                title: 'Vehicle Only',
                price: pricing['daily']['vehicleOnly']['price']?.toString() ??
                    'N/A',
                mileageLimit: pricing['daily']['vehicleOnly']['mileageLimit']
                        ?.toString() ??
                    'N/A',
                extraCharge: pricing['daily']['vehicleOnly']
                            ['extraMileageCharge']
                        ?.toString() ??
                    'N/A',
              ),

            // With driver
            if (pricing['daily']['withDriver'] != null)
              _buildPricingCard(
                context,
                title: 'With Driver',
                price: pricing['daily']['withDriver']['price']?.toString() ??
                    'N/A',
                mileageLimit: pricing['daily']['withDriver']['mileageLimit']
                        ?.toString() ??
                    'N/A',
                extraCharge: pricing['daily']['withDriver']
                            ['extraMileageCharge']
                        ?.toString() ??
                    'N/A',
              ),
          ],

          // Always show negotiable price notice
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All prices are negotiable - Contact owner for best rates!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubheading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required String label, required String value}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String mileageLimit,
    required String extraCharge,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'LKR $price',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            label: 'Mileage Limit',
            value: '$mileageLimit km',
          ),
          _buildInfoRow(
            context,
            label: 'Extra Mileage Charge',
            value: 'LKR $extraCharge/km',
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
