import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with SingleTickerProviderStateMixin {
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
                  // Image Carousel
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: _imageUrls.isNotEmpty 
                      ? Image.network(
                          _imageUrls[0],
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.car_rental, size: 80, color: Colors.grey),
                  ),
                  
                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Image page indicator
                  if (_imageUrls.length > 1)
                    Positioned(
                      bottom: 20,
                      right: 0,
                      left: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _imageUrls.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  // Status badge
                  Positioned(
                    top: 50,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_vehicleDetails['status']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _vehicleDetails['status'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
                // Vehicle Title and Price
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
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_vehicleDetails['category'] ?? 'Vehicle'} · ${_vehicleDetails['year'] ?? ''} · ${_vehicleDetails['color'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_vehicleDetails['pricing']?['daily']?['baseRate'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LKR ${_vehicleDetails['pricing']['daily']['baseRate']}',
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
                
                // Vehicle Registration Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: isDarkMode ? Colors.white60 : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_vehicleDetails['collectionPoint']?['city'] ?? ''}, ${_vehicleDetails['collectionPoint']?['district'] ?? 'Location not set'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.grey[700],
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Specifications'),
                      Tab(text: 'Features'),
                      Tab(text: 'Rental'),
                      Tab(text: 'Insurance'),
                    ],
                  ),
                ),

                // Tab content
                SizedBox(
                  height: 500, // You can adjust or make this dynamic
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

  Widget _buildSpecificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecificationRow('Make', _vehicleDetails['make'] ?? 'N/A'),
          _buildSpecificationRow('Model', _vehicleDetails['model'] ?? 'N/A'),
          _buildSpecificationRow('Category', _vehicleDetails['category'] ?? 'N/A'),
          _buildSpecificationRow('Year', _vehicleDetails['year']?.toString() ?? 'N/A'),
          _buildSpecificationRow('Color', _vehicleDetails['color'] ?? 'N/A'),
          _buildSpecificationRow('Transmission', _vehicleDetails['transmission'] ?? 'N/A'),
          _buildSpecificationRow('Fuel Type', _vehicleDetails['fuelType'] ?? 'N/A'),
          _buildSpecificationRow('Engine Capacity', '${_vehicleDetails['engineCapacity'] ?? 'N/A'} cc'),
          _buildSpecificationRow('Seating Capacity', _vehicleDetails['seatingCapacity']?.toString() ?? 'N/A'),
          _buildSpecificationRow('Doors', _vehicleDetails['doors']?.toString() ?? 'N/A'),
          _buildSpecificationRow('Vehicle Number', _vehicleDetails['vehicleNo'] ?? 'N/A'),
          _buildSpecificationRow('Chassis Number', _vehicleDetails['chassisNo'] ?? 'N/A'),
          _buildSpecificationRow('Engine Number', _vehicleDetails['engineNo'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    final features = _vehicleDetails['extras']?['features'] as Map<String, dynamic>?;
    final featuresList = features?.entries.where((e) => e.value == true).map((e) => e.key).toList() ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Features & Extras',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (featuresList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('No features specified'),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: featuresList.map((feature) => Chip(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
              )).toList(),
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
          const Text(
            'Rental Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Rental Conditions
          const Text(
            'Rental Conditions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildSpecificationRow('Rent Mode', rentalConditions?['rentMode'] ?? 'N/A'),
          
          // Available Periods
          const SizedBox(height: 16),
          const Text(
            'Available Rental Periods',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (pricing?['rentalPeriods'] != null) ...[
            for (var period in ['hourly', 'daily', 'weekly', 'monthly'])
              if (pricing['rentalPeriods'][period] == true)
                _buildSpecificationRow(
                  '${period.substring(0, 1).toUpperCase()}${period.substring(1)}', 
                  'Available'
                ),
          ],
          
          // Pricing Details
          const SizedBox(height: 16),
          const Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (pricing?['hourly']?['baseRate'] != null)
            _buildSpecificationRow('Hourly Rate', 'LKR ${pricing['hourly']['baseRate']}'),
          if (pricing?['daily']?['baseRate'] != null)
            _buildSpecificationRow('Daily Rate', 'LKR ${pricing['daily']['baseRate']}'),
          if (pricing?['weekly']?['baseRate'] != null)
            _buildSpecificationRow('Weekly Rate', 'LKR ${pricing['weekly']['baseRate']}'),
          if (pricing?['monthly']?['baseRate'] != null)
            _buildSpecificationRow('Monthly Rate', 'LKR ${pricing['monthly']['baseRate']}'),
          
          // Driver Details if applicable
          if (_vehicleDetails['driverDetails'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Driver Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildSpecificationRow('Driver Name', _vehicleDetails['driverDetails']['name'] ?? 'N/A'),
            _buildSpecificationRow('License No.', _vehicleDetails['driverDetails']['licenseNo'] ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildInsuranceTab() {
    final insurance = _vehicleDetails['insurance'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insurance Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (insurance == null || insurance.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('No insurance details available'),
              ),
            )
          else ...[
            _buildSpecificationRow('Insurance Provider', insurance['provider'] ?? 'N/A'),
            _buildSpecificationRow('Policy Number', insurance['policyNumber'] ?? 'N/A'),
            _buildSpecificationRow('Expiry Date', insurance['expiryDate'] != null
              ? DateFormat('MMM dd, yyyy').format(DateTime.parse(insurance['expiryDate']))
              : 'N/A'),
            _buildSpecificationRow('Coverage Type', insurance['coverageType'] ?? 'N/A'),
          ],
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
          'Are you sure you want to delete this vehicle? This action cannot be undone.'
        ),
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