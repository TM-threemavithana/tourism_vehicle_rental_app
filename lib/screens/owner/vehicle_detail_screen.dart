import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;
  List<String> _imageUrls = [];
  Map<String, dynamic> _vehicleDetails = {};

  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _vehicleDetails = widget.vehicle;

    // Add this debug call
    _debugPrintVehicleData();

    // Extract all images
    _extractImages();
  }

  void _extractImages() {
    List<String> images = [];

    // Add primary image first
    if (_vehicleDetails['images']?['primaryImageUrl'] != null) {
      images.add(_vehicleDetails['images']['primaryImageUrl']);
    }

    // Add all other images
    if (_vehicleDetails['images']?['imageUrls'] is List) {
      for (String url in _vehicleDetails['images']['imageUrls']) {
        if (url != _vehicleDetails['images']?['primaryImageUrl']) {
          images.add(url);
        }
      }
    }

    setState(() {
      _imageUrls = images;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
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
                                  ? theme.colorScheme.primary
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
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _editVehicle(),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _showDeleteDialog(),
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle title and status
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_vehicleDetails['make'] ?? ''} ${_vehicleDetails['model'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_vehicleDetails['category'] ?? 'Vehicle'} - ${_vehicleDetails['year'] ?? ''}',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_vehicleDetails['pricing']?['daily']?['vehicleOnly']
                              ?['price'] !=
                          null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LKR ${_vehicleDetails['pricing']['daily']['vehicleOnly']['price']}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Text(
                              'per day',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Status chip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Chip(
                    backgroundColor: _getStatusColor(_vehicleDetails['status'])
                        .withOpacity(0.2),
                    label: Text(
                      _vehicleDetails['status'] != null
                          ? _vehicleDetails['status']
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase()
                          : 'UNKNOWN',
                      style: TextStyle(
                        color: _getStatusColor(_vehicleDetails['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Vehicle Registration Details
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Vehicle No: ${_vehicleDetails['vehicleNo'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),

                // Location
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_vehicleDetails['collectionPoint']?['city'] ?? 'N/A'}, ${_vehicleDetails['collectionPoint']?['district'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 32),

                // Tabs for more details
                DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor:
                            isDarkMode ? Colors.white70 : Colors.grey[700],
                        indicatorColor: theme.colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Specs'),
                          Tab(text: 'Features'),
                          Tab(text: 'Rental'),
                          Tab(text: 'Insurance'),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.6, // Use a percentage of screen height
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSpecificationsTab(),
                            _buildFeaturesTab(),
                            _buildRentalDetailsTab(),
                            _buildInsuranceTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildSpecificationRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Add this helper method for subsection headers
  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Section
          _buildSectionHeader('Basic Information'),
          _buildSpecificationRow(
              'Vehicle Type', _vehicleDetails['type'] ?? 'N/A'),
          _buildSpecificationRow('Make', _vehicleDetails['make'] ?? 'N/A'),
          _buildSpecificationRow('Model', _vehicleDetails['model'] ?? 'N/A'),
          _buildSpecificationRow(
              'Category', _vehicleDetails['category'] ?? 'N/A'),
          _buildSpecificationRow('Grade', _vehicleDetails['grade'] ?? 'N/A'),
          _buildSpecificationRow(
              'Year', _vehicleDetails['year']?.toString() ?? 'N/A'),
          _buildSpecificationRow('Color', _vehicleDetails['color'] ?? 'N/A'),
          const Divider(height: 24),

          // Technical Specifications Section
          _buildSectionHeader('Technical Specifications'),
          _buildSpecificationRow(
              'Transmission', _vehicleDetails['transmission'] ?? 'N/A'),
          _buildSpecificationRow(
              'Fuel Type', _vehicleDetails['fuelType'] ?? 'N/A'),
          _buildSpecificationRow('Engine Capacity',
              '${_vehicleDetails['engineCapacity'] ?? 'N/A'} cc'),
          _buildSpecificationRow('Seating Capacity',
              _vehicleDetails['seatingCapacity']?.toString() ?? 'N/A'),
          _buildSpecificationRow(
              'Doors', _vehicleDetails['doors']?.toString() ?? 'N/A'),
          const Divider(height: 24),

          // Registration Information Section
          _buildSectionHeader('Registration Information'),
          _buildSpecificationRow(
              'Vehicle Number', _vehicleDetails['vehicleNo'] ?? 'N/A'),
          _buildSpecificationRow(
              'Chassis Number', _vehicleDetails['chassisNo'] ?? 'N/A'),
          _buildSpecificationRow(
              'Engine Number', _vehicleDetails['engineNo'] ?? 'N/A'),
          const Divider(height: 24),

          // Collection Point Section
          _buildSectionHeader('Collection Point'),
          _buildSpecificationRow('District',
              _vehicleDetails['collectionPoint']?['district'] ?? 'N/A'),
          _buildSpecificationRow(
              'City', _vehicleDetails['collectionPoint']?['city'] ?? 'N/A'),
          _buildSpecificationRow('Address',
              _vehicleDetails['collectionPoint']?['address'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    // Check if extras exists and if it has a features property that is a Map
    final Map<String, dynamic>? features =
        _vehicleDetails['extras']?['features'] as Map<String, dynamic>?;

    // Get a list of all features that are set to true
    final List<String> featuresList = [];

    if (features != null) {
      features.forEach((key, value) {
        if (value == true) {
          featuresList.add(key);
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Vehicle Features & Extras'),
          const SizedBox(height: 16),
          if (featuresList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: const [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No features specified for this vehicle',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: featuresList.map((feature) {
                return Chip(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  label: Text(feature),
                  avatar: Icon(
                    _getFeatureIcon(feature),
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRentalDetailsTab() {
    final rentalConditions = _vehicleDetails['rentalConditions'];
    final pricing = _vehicleDetails['pricing'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Rental Information'),

          // Vehicle Value display
          if (pricing != null && pricing['vehicleValue'] != null) ...[
            _buildSpecificationRow(
                'Vehicle Value', 'LKR ${pricing['vehicleValue']}'),
            const Divider(height: 24),
          ],

          // Rental Conditions section
          if (rentalConditions != null) ...[
            _buildSubSectionHeader('Rental Conditions'),
            if (rentalConditions['rentMode'] != null)
              _buildSpecificationRow('Rent Mode', rentalConditions['rentMode']),
            if (rentalConditions['minRentalPeriod'] != null)
              _buildSpecificationRow('Minimum Rental Period',
                  '${rentalConditions['minRentalPeriod']['value']} ${rentalConditions['minRentalPeriod']['unit']}'),
            if (rentalConditions['maxRentalPeriod'] != null)
              _buildSpecificationRow('Maximum Rental Period',
                  '${rentalConditions['maxRentalPeriod']['value']} ${rentalConditions['maxRentalPeriod']['unit']}'),
            if (rentalConditions['advanceRentalPeriod'] != null)
              _buildSpecificationRow('Advance Booking Period',
                  '${rentalConditions['advanceRentalPeriod']['value']} ${rentalConditions['advanceRentalPeriod']['unit']}'),
            const Divider(height: 24),
          ],

          // Available Rental Periods section
          if (pricing != null && pricing['rentalPeriods'] != null) ...[
            _buildSubSectionHeader('Available Rental Periods'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var period in ['hourly', 'daily', 'weekly', 'monthly'])
                  if (pricing['rentalPeriods'][period] == true)
                    _buildSpecificationRow(period.capitalize(), 'Available'),
              ],
            ),
            const Divider(height: 24),
          ],

          // Pricing Details section
          _buildSubSectionHeader('Pricing'),

          // Debug info - helps identify structure issues
          if (pricing == null)
            Text("No pricing information available",
                style: TextStyle(color: Colors.red)),

          // Hourly pricing section
          if (pricing != null && pricing['hourly'] != null) ...[
            const Text('Hourly Rates',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (pricing['hourly']['vehicleOnly'] != null) ...[
              _buildSpecificationRow('Vehicle Only Price',
                  'LKR ${pricing['hourly']['vehicleOnly']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['hourly']['vehicleOnly']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['hourly']['vehicleOnly']['extraMileageCharge']}/km'),
            ],
            if (pricing['hourly']['withDriver'] != null) ...[
              const SizedBox(height: 8),
              _buildSpecificationRow('With Driver Price',
                  'LKR ${pricing['hourly']['withDriver']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['hourly']['withDriver']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['hourly']['withDriver']['extraMileageCharge']}/km'),
            ],
            const Divider(height: 24),
          ],

          // Daily pricing section
          if (pricing != null && pricing['daily'] != null) ...[
            const Text('Daily Rates',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (pricing['daily']['vehicleOnly'] != null) ...[
              _buildSpecificationRow('Vehicle Only Price',
                  'LKR ${pricing['daily']['vehicleOnly']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['daily']['vehicleOnly']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['daily']['vehicleOnly']['extraMileageCharge']}/km'),
            ],
            if (pricing['daily']['withDriver'] != null) ...[
              const SizedBox(height: 8),
              _buildSpecificationRow('With Driver Price',
                  'LKR ${pricing['daily']['withDriver']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['daily']['withDriver']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['daily']['withDriver']['extraMileageCharge']}/km'),
            ],
            const Divider(height: 24),
          ],

          // Weekly pricing section
          if (pricing != null && pricing['weekly'] != null) ...[
            const Text('Weekly Rates',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (pricing['weekly']['vehicleOnly'] != null) ...[
              _buildSpecificationRow('Vehicle Only Price',
                  'LKR ${pricing['weekly']['vehicleOnly']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['weekly']['vehicleOnly']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['weekly']['vehicleOnly']['extraMileageCharge']}/km'),
            ],
            if (pricing['weekly']['withDriver'] != null) ...[
              const SizedBox(height: 8),
              _buildSpecificationRow('With Driver Price',
                  'LKR ${pricing['weekly']['withDriver']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['weekly']['withDriver']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['weekly']['withDriver']['extraMileageCharge']}/km'),
            ],
            const Divider(height: 24),
          ],

          // Monthly pricing section
          if (pricing != null && pricing['monthly'] != null) ...[
            const Text('Monthly Rates',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (pricing['monthly']['vehicleOnly'] != null) ...[
              _buildSpecificationRow('Vehicle Only Price',
                  'LKR ${pricing['monthly']['vehicleOnly']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['monthly']['vehicleOnly']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['monthly']['vehicleOnly']['extraMileageCharge']}/km'),
            ],
            if (pricing['monthly']['withDriver'] != null) ...[
              const SizedBox(height: 8),
              _buildSpecificationRow('With Driver Price',
                  'LKR ${pricing['monthly']['withDriver']['price']}'),
              _buildSpecificationRow('Mileage Limit',
                  '${pricing['monthly']['withDriver']['mileageLimit']} km'),
              _buildSpecificationRow('Extra Mileage Charge',
                  'LKR ${pricing['monthly']['withDriver']['extraMileageCharge']}/km'),
            ],
            const Divider(height: 24),
          ],

          // Driver Details section
          if (_vehicleDetails['driverDetails'] != null) ...[
            _buildSubSectionHeader('Driver Details'),
            _buildSpecificationRow('Driver Name',
                _vehicleDetails['driverDetails']['name'] ?? 'N/A'),
            _buildSpecificationRow('License No.',
                _vehicleDetails['driverDetails']['licenseNo'] ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildInsuranceTab() {
    final insurance = _vehicleDetails['insurance'];
    final hasInsurance = insurance?['hasInsurance'] == true;
    final securityDeposit = insurance?['securityDeposit'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Insurance Details'),
          if (!hasInsurance && securityDeposit == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: const [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No insurance details available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpecificationRow('Insurance Status',
                    hasInsurance ? 'Insured' : 'Not Insured'),
                if (hasInsurance) ...[
                  if (insurance?['provider'] != null)
                    _buildSpecificationRow(
                        'Insurance Provider', insurance['provider']),
                  if (insurance?['policyNumber'] != null)
                    _buildSpecificationRow(
                        'Policy Number', insurance['policyNumber']),
                  if (insurance?['expiryDate'] != null)
                    _buildSpecificationRow(
                        'Expiry Date',
                        DateFormat('MMM dd, yyyy')
                            .format(DateTime.parse(insurance['expiryDate']))),
                  if (insurance?['coverageType'] != null)
                    _buildSpecificationRow(
                        'Coverage Type', insurance['coverageType']),
                ],
                if (securityDeposit != null) ...[
                  const Divider(height: 24),
                  _buildSpecificationRow(
                      'Security Deposit', 'LKR $securityDeposit'),

                  // Information about security deposit
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Text(
                        'Security deposit is refundable at the end of the rental period, subject to vehicle condition assessment.',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // Method to get feature icon
  IconData _getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'air conditioning':
        return Icons.ac_unit;
      case 'power steering':
        return Icons.zoom_out_map; // Changed from Icons.steering
      case 'power windows':
        return Icons.crop_square;
      case 'abs':
        return Icons.do_not_disturb_on; // Changed from Icons.brake_alert
      case 'airbags':
        return Icons.airline_seat_recline_normal;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'cruise control':
        return Icons.speed;
      case 'parking sensors':
        return Icons.sensors;
      case 'backup camera':
        return Icons.camera_rear;
      case 'navigation system':
        return Icons.gps_fixed;
      case 'sunroof':
        return Icons.wb_sunny;
      case 'leather seats':
        return Icons.event_seat;
      case 'heated seats':
        return Icons.heat_pump;
      case 'usb port':
        return Icons.usb;
      case 'aux input':
        return Icons.headphones;
      case 'fm radio':
        return Icons.radio;
      default:
        return Icons.check_circle;
    }
  }

  // Methods for actions
  void _editVehicle() {
    // Navigate to edit vehicle screen (implement later)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit vehicle functionality coming soon!')),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: const Text(
            'Are you sure you want to delete this vehicle? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteVehicle();
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle() async {
    try {
      // Get the document ID for this vehicle
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('vehicleNo', isEqualTo: _vehicleDetails['vehicleNo'])
          .get();

      if (vehiclesSnapshot.docs.isNotEmpty) {
        await vehiclesSnapshot.docs.first.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to refresh the dashboard
      } else {
        throw Exception('Vehicle not found');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting vehicle: $e')),
      );
    }
  }

  // Add this method for debugging
  void _debugPrintVehicleData() {
    print("==== VEHICLE DATA DEBUG ====");
    print("Vehicle ID: ${_vehicleDetails['id']}");

    // Print extras
    print("EXTRAS: ${_vehicleDetails['extras']}");
    if (_vehicleDetails['extras'] != null) {
      print("Features: ${_vehicleDetails['extras']['features']}");
    }

    // Print pricing
    print("PRICING: ${_vehicleDetails['pricing']}");
    if (_vehicleDetails['pricing'] != null) {
      print("Rental Periods: ${_vehicleDetails['pricing']['rentalPeriods']}");
      print("Daily Pricing: ${_vehicleDetails['pricing']['daily']}");
    }

    print("==== END DEBUG ====");
  }

  // Helper method for status color
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'rented':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'pending_verification':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

// Add this extension method for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
