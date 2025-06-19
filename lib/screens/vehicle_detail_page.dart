import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';

class VehicleDetailPage extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailPage({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  int _currentImageIndex = 0;
  List<String> _imageUrls = [];
  late Map<String, dynamic> _vehicleDetails;

  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _vehicleDetails = widget.vehicle;
    _extractImages();
  }

  void _extractImages() {
    List<String> images = [];

    try {
      // Add primary image first if available
      if (_vehicleDetails['images']?['primaryImageUrl'] != null) {
        images.add(_vehicleDetails['images']['primaryImageUrl']);
      }

      // Add all other images if available
      if (_vehicleDetails['images']?['imageUrls'] is List) {
        for (var url in _vehicleDetails['images']['imageUrls']) {
          if (url != _vehicleDetails['images']?['primaryImageUrl']) {
            images.add(url);
          }
        }
      }
    } catch (e) {
      print('Error extracting images: $e');
    }

    setState(() {
      _imageUrls = images;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                    items: _imageUrls.isNotEmpty
                        ? _imageUrls
                            .map((url) => _buildCarouselItem(url))
                            .toList()
                        : [_buildPlaceholderImage()],
                  ),
                  // Dots indicator
                  if (_imageUrls.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _imageUrls.asMap().entries.map((entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Vehicle info section below carousel
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand logo and vehicle name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Brand logo placeholder
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: _getCarLogo(_vehicleDetails['make']),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Vehicle name and year
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_vehicleDetails['make'] ?? ''} ${_vehicleDetails['model'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_vehicleDetails['category'] ?? 'Vehicle'} - ${_vehicleDetails['year'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            (_vehicleDetails['rating'] != null &&
                                    index <
                                        (_vehicleDetails['rating'] as num? ?? 0)
                                            .floor())
                                ? Icons.star
                                : Icons.star_border,
                            size: 20,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_vehicleDetails['rating'] ?? '0.0'} (${_vehicleDetails['reviewsCount'] ?? '0'} reviews)',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location and Trips row
                  Row(
                    children: [
                      // Location info
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_vehicleDetails['collectionPoint']?['city'] ?? 'N/A'}, ${_vehicleDetails['collectionPoint']?['district'] ?? ''}',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Number of trips
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_vehicleDetails['tripsCount'] ?? '0'} trips',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider for separation
                  const Divider(),
                ],
              ),
            ),
          ),

          // Content for vehicle specifications and other details will go here
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Vehicle details, specifications, etc. will be added here
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Rental Information section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  Text(
                    'Rental Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rental Pricing Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Daily Pricing
                          if (_vehicleDetails['pricing']?['daily']
                                  ?['vehicleOnly'] !=
                              null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Rate:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'LKR ${_vehicleDetails['pricing']['daily']['vehicleOnly']['price']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mileage Limit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      size: 16,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Mileage Limit:'),
                                  ],
                                ),
                                Text(
                                  '${_vehicleDetails['pricing']['daily']['vehicleOnly']['mileageLimit']} km/day',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Extra Mileage Charge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.money,
                                      size: 16,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Extra Mileage:'),
                                  ],
                                ),
                                Text(
                                  'LKR ${_vehicleDetails['pricing']['daily']['vehicleOnly']['extraMileageCharge']}/km',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],

                          if (_vehicleDetails['pricing']?['daily']
                                  ?['withDriver'] !=
                              null) ...[
                            const Divider(height: 24),
                            Text(
                              'With Driver',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Daily Rate:'),
                                Text(
                                  'LKR ${_vehicleDetails['pricing']['daily']['withDriver']['price']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rental Conditions Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rental Conditions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Min Rental Period
                          if (_vehicleDetails['rentalConditions']
                                  ?['minRentalPeriod'] !=
                              null)
                            _buildRentalConditionRow(
                              'Minimum Rental:',
                              '${_vehicleDetails['rentalConditions']['minRentalPeriod']['value']} ${_vehicleDetails['rentalConditions']['minRentalPeriod']['unit']}',
                              Icons.timelapse,
                            ),

                          // Max Rental Period
                          if (_vehicleDetails['rentalConditions']
                                  ?['maxRentalPeriod'] !=
                              null)
                            _buildRentalConditionRow(
                              'Maximum Rental:',
                              '${_vehicleDetails['rentalConditions']['maxRentalPeriod']['value']} ${_vehicleDetails['rentalConditions']['maxRentalPeriod']['unit']}',
                              Icons.date_range,
                            ),

                          // Advance Notice Period
                          if (_vehicleDetails['rentalConditions']
                                  ?['advanceRentalPeriod'] !=
                              null)
                            _buildRentalConditionRow(
                              'Advance Notice:',
                              '${_vehicleDetails['rentalConditions']['advanceRentalPeriod']['value']} ${_vehicleDetails['rentalConditions']['advanceRentalPeriod']['unit']}',
                              Icons.notifications_active,
                            ),

                          // Security Deposit
                          if (_vehicleDetails['rentalConditions']
                                  ?['securityDeposit'] !=
                              null)
                            _buildRentalConditionRow(
                              'Security Deposit:',
                              'LKR ${_vehicleDetails['rentalConditions']['securityDeposit']}',
                              Icons.security,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.car_rental, size: 80, color: Colors.grey),
    );
  }

  Widget _getCarLogo(String? make) {
    // For Toyota, use a local asset image
    if (make == 'Toyota') {
      return Image.asset(
        'assets/car logo/Toyota.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if local image fails to load
          return Center(
            child: Text(
              'T',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          );
        },
      );
    }

    // For other makes, continue using online sources
    final logoMap = {
      'Honda': 'https://www.car-logos.org/wp-content/uploads/2011/09/honda.png',
      'Nissan':
          'https://www.car-logos.org/wp-content/uploads/2011/09/nissan.png',
      'Suzuki':
          'https://www.car-logos.org/wp-content/uploads/2011/09/suzuki.png',
      'Mitsubishi':
          'https://www.car-logos.org/wp-content/uploads/2011/09/mitsubishi.png',
      'Mazda': 'https://www.car-logos.org/wp-content/uploads/2011/09/mazda.png',
      'Subaru':
          'https://www.car-logos.org/wp-content/uploads/2011/09/subaru.png',
      'BMW': 'https://www.car-logos.org/wp-content/uploads/2011/09/bmw.png',
      'Mercedes-Benz':
          'https://www.car-logos.org/wp-content/uploads/2011/09/mercedes.png',
      'Audi': 'https://www.car-logos.org/wp-content/uploads/2011/09/audi.png',
      'Volkswagen':
          'https://www.car-logos.org/wp-content/uploads/2011/09/volkswagen.png',
      'Ford': 'https://www.car-logos.org/wp-content/uploads/2011/09/ford.png',
      'Hyundai':
          'https://www.car-logos.org/wp-content/uploads/2011/09/hyundai.png',
      'Kia': 'https://www.car-logos.org/wp-content/uploads/2011/09/kia.png',
      'Lexus': 'https://www.car-logos.org/wp-content/uploads/2011/09/lexus.png',
      'Bajaj':
          'https://seeklogo.com/images/B/Bajaj-logo-0B669C9905-seeklogo.com.png',
      'Hero':
          'https://seeklogo.com/images/H/hero-motocorp-logo-86B709D919-seeklogo.com.png',
      'TVS':
          'https://seeklogo.com/images/T/TVS-logo-66AF311B17-seeklogo.com.png',
      'Yamaha':
          'https://www.car-logos.org/wp-content/uploads/2011/09/yamaha.png',
      'Tata': 'https://www.car-logos.org/wp-content/uploads/2011/09/tata.png',
      'Mahindra':
          'https://seeklogo.com/images/M/Mahindra-logo-63AE37E286-seeklogo.com.png',
      'Maruti Suzuki':
          'https://seeklogo.com/images/M/maruti-suzuki-logo-B7309F69D3-seeklogo.com.png',
      'Jeep': 'https://www.car-logos.org/wp-content/uploads/2011/09/jeep.png',
      'Land Rover':
          'https://www.car-logos.org/wp-content/uploads/2011/09/land-rover.png',
    };

    if (make != null && logoMap.containsKey(make)) {
      return CachedNetworkImage(
        imageUrl: logoMap[make]!,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          color: Colors.transparent,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Center(
          child: Text(
            make.substring(0, 1),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    } else {
      // For makes not in our map, show the first letter
      return Center(
        child: Text(
          make?.substring(0, 1) ?? 'V',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }
  }

  // Add the missing methods needed by the page
  Widget _buildRentalConditionRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
