import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import 'vehicle_detail_page.dart';
import '../helpers/car_logo_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'merged_filter_drawer.dart';

class VehicleSearchResultsScreen extends StatefulWidget {
  final Set<String> selectedVehicleTypes;
  final String location;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool flexibleDates;
  final String? make;
  final String? model;

  const VehicleSearchResultsScreen({
    super.key,
    required this.selectedVehicleTypes,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.flexibleDates,
    this.make,
    this.model,
  });

  @override
  State<VehicleSearchResultsScreen> createState() =>
      _VehicleSearchResultsScreenState();
}

class _VehicleSearchResultsScreenState
    extends State<VehicleSearchResultsScreen> {
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filter state variables
  String _selectedSortOption = '';
  RangeValues _priceRange = const RangeValues(0, 50000);
  Set<String> _selectedFeatures = {};
  Set<String> _selectedFuelTypes = {};
  Set<String> _selectedTransmissionTypes = {};
  Set<String> _selectedRentModes = {};

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(VehicleSearchResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedVehicleTypes != widget.selectedVehicleTypes ||
        oldWidget.location != widget.location ||
        oldWidget.pickupDate != widget.pickupDate ||
        oldWidget.returnDate != widget.returnDate ||
        oldWidget.make != widget.make ||
        oldWidget.model != widget.model) {
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('vehicles');

      if (widget.selectedVehicleTypes.isNotEmpty) {
        query =
            query.where('type', whereIn: widget.selectedVehicleTypes.toList());
      }

      query = query.where('status', isEqualTo: 'available');

      final QuerySnapshot snapshot = await query.get();
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        bool locationMatches = false;
        if (widget.location.isNotEmpty) {
          final collectionPoint =
              data['collectionPoint'] as Map<String, dynamic>?;
          if (collectionPoint != null) {
            final district = collectionPoint['district'] as String?;
            final city = collectionPoint['city'] as String?;

            if ((district
                        ?.toLowerCase()
                        .contains(widget.location.toLowerCase()) ==
                    true) ||
                (city?.toLowerCase().contains(widget.location.toLowerCase()) ==
                    true) ||
                (district?.toLowerCase() == widget.location.toLowerCase()) ||
                (city?.toLowerCase() == widget.location.toLowerCase())) {
              locationMatches = true;
            }
          }
        } else {
          locationMatches = true;
        }

        bool makeMatches = true;
        if (widget.make != null && widget.make!.isNotEmpty) {
          makeMatches = (data['make'] as String?)?.toLowerCase() ==
              widget.make!.toLowerCase();
        }

        bool modelMatches = true;
        if (widget.model != null && widget.model!.isNotEmpty) {
          modelMatches = (data['model'] as String?)?.toLowerCase() ==
              widget.model!.toLowerCase();
        }

        bool dateMatches = true;

        if (locationMatches && makeMatches && modelMatches && dateMatches) {
          results.add({...data, 'id': doc.id});
        }
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching for vehicles: $e';
        _isLoading = false;
      });
    }
  }

  void _showMergedFilterDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // Helper to clean phone number for WhatsApp
  String cleanPhoneNumber(String number) {
    // Remove all non-digit characters except leading +
    String cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    // Remove leading zeros after country code
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.replaceFirst('00', '');
    }
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDarkMode ? AppColors.neutralDark : AppColors.neutralBackground,
      drawer: MergedFilterDrawer(
        selectedVehicleTypes: widget.selectedVehicleTypes,
        location: widget.location,
        pickupDate: widget.pickupDate,
        pickupTime: widget.pickupTime,
        returnDate: widget.returnDate,
        returnTime: widget.returnTime,
        flexibleDates: widget.flexibleDates,
        make: widget.make,
        model: widget.model,
        initialResults: _searchResults,
        onApplySearch: _applySearchFilters,
        onApplyFilters: _applyResultFilters,
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _buildSearchTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Yellow status bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top,
              color: const Color(0xFFFFC107),
            ),
          ),
          Column(
            children: [
              Container(
                color: isDarkMode ? AppColors.neutralDark : AppColors.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showMergedFilterDrawer,
                        child: Row(
                          children: const [
                            Icon(Icons.tune, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Search & Filter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          )
                        : _searchResults.isEmpty
                            ? _buildNoResultsView()
                            : _buildResultsListView(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyResultFilters(
    List<Map<String, dynamic>> filteredResults,
    String sortOption,
    RangeValues priceRange,
    Set<String> features,
    Set<String> fuelTypes,
    Set<String> transmissionTypes,
    Set<String> rentModes,
  ) {
    setState(() {
      _searchResults = filteredResults;
      _selectedSortOption = sortOption;
      _priceRange = priceRange;
      _selectedFeatures = features;
      _selectedFuelTypes = fuelTypes;
      _selectedTransmissionTypes = transmissionTypes;
      _selectedRentModes = rentModes;
    });
  }

  void _applySearchFilters(
    Set<String> selectedVehicleTypes,
    String location,
    DateTime pickupDate,
    TimeOfDay pickupTime,
    DateTime returnDate,
    TimeOfDay returnTime,
    bool flexibleDates,
    String? make,
    String? model,
  ) {
    // Check if the search parameters are actually different from current ones
    bool paramsChanged =
        selectedVehicleTypes.length != widget.selectedVehicleTypes.length ||
            !selectedVehicleTypes
                .every((type) => widget.selectedVehicleTypes.contains(type)) ||
            location != widget.location ||
            pickupDate != widget.pickupDate ||
            pickupTime != widget.pickupTime ||
            returnDate != widget.returnDate ||
            returnTime != widget.returnTime ||
            flexibleDates != widget.flexibleDates ||
            make != widget.make ||
            model != widget.model;

    // Only perform navigation if parameters have actually changed
    if (paramsChanged) {
      // Reset filter state when performing new search
      setState(() {
        _selectedSortOption = '';
        _selectedFeatures = {};
        _selectedFuelTypes = {};
        _selectedTransmissionTypes = {};
        _selectedRentModes = {};
      });

      // Use pushReplacement with a more direct approach
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleSearchResultsScreen(
            selectedVehicleTypes: selectedVehicleTypes,
            location: location,
            pickupDate: pickupDate,
            pickupTime: pickupTime,
            returnDate: returnDate,
            returnTime: returnTime,
            flexibleDates: flexibleDates,
            make: make,
            model: model,
          ),
        ),
      );
    }
  }

  Widget _buildNoResultsView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color:
                isDarkMode ? AppColors.neutralMedium : AppColors.neutralLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No vehicles found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search criteria',
            style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? AppColors.neutralLight
                    : AppColors.neutralMedium),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Search'),
          )
        ],
      ),
    );
  }

  // Update the vehicle card in the search results
  Widget _buildVehicleCard(
      BuildContext context, Map<String, dynamic> vehicle, bool isDarkMode) {
    final String make = vehicle['make'] ?? 'Unknown';
    final String model = vehicle['model'] ?? '';
    final String? year = vehicle['year']?.toString();
    final String? category = vehicle['category'];
    final String? whatsappNumber = vehicle['driverDetails']?['whatsappNumber'];
    final String? contactNumber =
        (whatsappNumber != null && whatsappNumber.isNotEmpty)
            ? whatsappNumber
            : vehicle['contactNumber'];
    final String? imageUrl = vehicle['images']?['primaryImageUrl'];
    final String? city = vehicle['collectionPoint']?['city'];
    final String? district = vehicle['collectionPoint']?['district'];
    final double? rating = (vehicle['rating'] is num)
        ? (vehicle['rating'] as num).toDouble()
        : null;
    final int? trips = vehicle['trips'] is int ? vehicle['trips'] : null;
    final String? price =
        vehicle['pricing']?['daily']?['vehicleOnly']?['price']?.toString();
    final String? rentMode =
        vehicle['rentalConditions']?['rentMode'] ?? 'Vehicle Only';
    final String locationString = [city, district]
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailPage(vehicle: vehicle),
          ),
        );
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: isDarkMode ? AppColors.neutralDark : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image only
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 140,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 140,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 140,
                              height: 150,
                              color: Colors.grey[200],
                              child: const Icon(Icons.car_rental,
                                  size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 140,
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(Icons.car_rental,
                                size: 40, color: Colors.grey),
                          ),
                  ),
                  if ((price ?? '').isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFC107).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Rs. ${price ?? ''} / Day',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Info and actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Make/model/price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand logo to the left of make/model
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: CarLogoHelper.getCarLogo(make),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$make $model',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : AppColors.neutralDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (year != null && year.isNotEmpty)
                                    Text(
                                      year,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : AppColors.neutralMedium,
                                      ),
                                    ),
                                  if (category != null &&
                                      category.isNotEmpty) ...[
                                    if (year != null && year.isNotEmpty)
                                      const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.skyBlue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Stats row
                    Row(
                      children: [
                        // Rating
                        Icon(Icons.star, color: AppColors.warning, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          rating != null ? rating.toStringAsFixed(1) : '0.0',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.neutralDark,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Trips
                        Icon(Icons.directions_car,
                            color: AppColors.rentedColor, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          trips != null ? '$trips trips' : '0 trips',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[300]
                                : AppColors.neutralMedium,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Location
                        Icon(Icons.location_on,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          locationString,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[300]
                                : AppColors.neutralMedium,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Rent mode
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: AppColors.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          rentMode ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.grey[200]
                                : AppColors.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (contactNumber != null && contactNumber.isNotEmpty)
                          _buildActionButton(
                            context,
                            icon: Icons.phone,
                            label: 'Call',
                            color: AppColors.success,
                            onTap: () async {
                              final uri =
                                  Uri(scheme: 'tel', path: contactNumber);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Cannot make a call from this device.')),
                                );
                              }
                            },
                          ),
                        if (contactNumber != null && contactNumber.isNotEmpty)
                          const SizedBox(width: 10),
                        if (contactNumber != null && contactNumber.isNotEmpty)
                          _buildActionButton(
                            context,
                            icon: FontAwesomeIcons.whatsapp,
                            label: 'WhatsApp',
                            color: AppColors.primary,
                            isFaIcon: true,
                            onTap: () async {
                              final cleanedNumber =
                                  cleanPhoneNumber(contactNumber);
                              final whatsappUrl =
                                  Uri.parse('https://wa.me/$cleanedNumber');
                              // Try to launch WhatsApp
                              if (await canLaunchUrl(whatsappUrl)) {
                                final launched = await launchUrl(
                                  whatsappUrl,
                                  mode: LaunchMode.externalApplication,
                                );
                                if (!launched) {
                                  // Fallback: try to open in browser
                                  final browserLaunched = await launchUrl(
                                    whatsappUrl,
                                    mode: LaunchMode.platformDefault,
                                  );
                                  if (!browserLaunched) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Could not open WhatsApp or browser. Please make sure WhatsApp is installed and the number is valid.')),
                                    );
                                  }
                                }
                              } else {
                                // Fallback: try to open in browser
                                final browserLaunched = await launchUrl(
                                  whatsappUrl,
                                  mode: LaunchMode.platformDefault,
                                );
                                if (!browserLaunched) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Could not open WhatsApp or browser. Please make sure WhatsApp is installed and the number is valid.')),
                                  );
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required dynamic icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
      bool isFaIcon = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: isFaIcon
          ? FaIcon(icon as IconData, color: Colors.white, size: 18)
          : Icon(icon as IconData, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  String _buildSearchTitle() {
    if (widget.selectedVehicleTypes.isEmpty) {
      return 'All Vehicles in ${widget.location.isEmpty ? "All Locations" : widget.location}';
    }

    List<String> pluralizedTypes = widget.selectedVehicleTypes.map((type) {
      switch (type.toLowerCase()) {
        case 'car':
          return 'Cars';
        case 'bike':
          return 'Bikes';
        case 'three-wheeler':
          return 'Three-Wheelers';
        default:
          return '${type}s';
      }
    }).toList();

    return '${pluralizedTypes.join(", ")} in ${widget.location.isEmpty ? "All Locations" : widget.location}';
  }

  Widget _buildResultsListView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard(context, _searchResults[index], isDarkMode);
      },
    );
  }
}
