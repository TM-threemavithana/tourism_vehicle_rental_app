import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
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
        toolbarHeight: ResponsiveHelper.getResponsiveIconSize(context,
            mobile: 44, tablet: 56, ipad: 64, ipadPro: 72, desktop: 80),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: ResponsiveHelper.getResponsiveIconSize(context,
                mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _buildSearchTitle(),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                mobile: 18, tablet: 22, ipad: 26, ipadPro: 30, desktop: 34),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Compact Filter Button
          Container(
            margin: EdgeInsets.only(
              right: ResponsiveHelper.getResponsiveSpacingIPad(
                context,
                mobile: 16,
                tablet: 20,
                ipad: 24,
                ipadPro: 32,
                desktop: 40,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _showMergedFilterDrawer,
              icon: Icon(
                Icons.filter_alt,
                color: const Color(0xFFFFC107),
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  ipad: 24,
                  ipadPro: 26,
                  desktop: 28,
                ),
              ),
              label: Text(
                'Filter',
                style: TextStyle(
                  color: const Color(0xFFFFC107),
                  fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(
                    context,
                    mobile: 14,
                    tablet: 16,
                    ipad: 18,
                    ipadPro: 20,
                    desktop: 22,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: const Color(0xFFFFC107),
                elevation: 3,
                padding: ResponsiveHelper.getResponsiveButtonPadding(
                  context,
                  mobile:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tablet:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  desktop:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(
                      context,
                      mobile: 20,
                      tablet: 22,
                      ipad: 24,
                      ipadPro: 26,
                      desktop: 28,
                    ),
                  ),
                ),
                minimumSize: Size(
                  ResponsiveHelper.getResponsiveSpacingIPad(
                    context,
                    mobile: 80,
                    tablet: 90,
                    ipad: 100,
                    ipadPro: 110,
                    desktop: 120,
                  ),
                  ResponsiveHelper.getResponsiveSpacingIPad(
                    context,
                    mobile: 36,
                    tablet: 40,
                    ipad: 44,
                    ipadPro: 48,
                    desktop: 52,
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final String? price =
        vehicle['pricing']?['daily']?['vehicleOnly']?['price']?.toString();
    final String? rentMode =
        vehicle['rentalConditions']?['rentMode'] ?? 'Vehicle Only';
    final String locationString = [city, district]
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context)),
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
        margin: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context,
              mobile: 10, tablet: 12, desktop: 16),
          horizontal: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context)),
        ),
        color: isDarkMode ? AppColors.neutralDark : Colors.white,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context,
              mobile: 10, tablet: 12, ipad: 8, ipadPro: 8, desktop: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image only
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context,
                            mobile: 14, tablet: 18, desktop: 22)),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: ResponsiveHelper.getResponsiveImageSize(
                                context,
                                mobile: 140,
                                tablet: 120,
                                ipad: 100,
                                ipadPro: 100,
                                desktop: 140),
                            height: ResponsiveHelper.getResponsiveImageSize(
                                context,
                                mobile: 150,
                                tablet: 140,
                                ipad: 120,
                                ipadPro: 120,
                                desktop: 160),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: ResponsiveHelper.getResponsiveImageSize(
                                  context,
                                  mobile: 140,
                                  tablet: 120,
                                  ipad: 100,
                                  ipadPro: 100,
                                  desktop: 140),
                              height: ResponsiveHelper.getResponsiveImageSize(
                                  context,
                                  mobile: 150,
                                  tablet: 140,
                                  ipad: 120,
                                  ipadPro: 120,
                                  desktop: 160),
                              color: Colors.grey[300],
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: ResponsiveHelper.getResponsiveImageSize(
                                  context,
                                  mobile: 140,
                                  tablet: 120,
                                  ipad: 100,
                                  ipadPro: 100,
                                  desktop: 140),
                              height: ResponsiveHelper.getResponsiveImageSize(
                                  context,
                                  mobile: 150,
                                  tablet: 140,
                                  ipad: 120,
                                  ipadPro: 120,
                                  desktop: 160),
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.car_rental,
                                size: ResponsiveHelper.getResponsiveIconSize(
                                    context,
                                    mobile: 40,
                                    tablet: 56,
                                    desktop: 72),
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: ResponsiveHelper.getResponsiveImageSize(
                                context,
                                mobile: 140,
                                tablet: 180,
                                desktop: 220),
                            height: ResponsiveHelper.getResponsiveImageSize(
                                context,
                                mobile: 150,
                                tablet: 200,
                                desktop: 250),
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.car_rental,
                              size: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 40,
                                  tablet: 56,
                                  desktop: 72),
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if ((price ?? '').isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        margin: ResponsiveHelper.getResponsivePadding(context,
                            mobile: 8, tablet: 12, desktop: 16),
                        padding: ResponsiveHelper.getResponsivePadding(context,
                            mobile: 12, tablet: 16, desktop: 20),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFC107).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16)),
                          boxShadow:
                              ResponsiveHelper.getResponsiveShadow(context),
                        ),
                        child: Text(
                          'Rs. ${price ?? ''} / Day',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 13,
                                tablet: 15,
                                desktop: 17),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 16, tablet: 20, desktop: 24)),
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
                          margin: EdgeInsets.only(
                              right: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16)),
                          width: ResponsiveHelper.getResponsiveIconSize(context,
                              mobile: 32, tablet: 40, desktop: 48),
                          height: ResponsiveHelper.getResponsiveIconSize(
                              context,
                              mobile: 32,
                              tablet: 40,
                              desktop: 48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveBorderRadius(
                                    context,
                                    mobile: 20,
                                    tablet: 25,
                                    desktop: 30)),
                            boxShadow:
                                ResponsiveHelper.getResponsiveShadow(context),
                          ),
                          padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              mobile: 4,
                              tablet: 6,
                              desktop: 8),
                          child: CarLogoHelper.getCarLogo(make),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$make $model',
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobile: 18,
                                          tablet: 22,
                                          desktop: 26),
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : AppColors.neutralDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                  height: ResponsiveHelper.getResponsiveSpacing(
                                      context,
                                      mobile: 2,
                                      tablet: 4,
                                      desktop: 6)),
                              Row(
                                children: [
                                  if (year != null && year.isNotEmpty)
                                    Text(
                                      year,
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(context,
                                                mobile: 13,
                                                tablet: 15,
                                                desktop: 17),
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : AppColors.neutralMedium,
                                      ),
                                    ),
                                  if (category != null &&
                                      category.isNotEmpty) ...[
                                    if (year != null && year.isNotEmpty)
                                      SizedBox(
                                          width: ResponsiveHelper
                                              .getResponsiveSpacing(context,
                                                  mobile: 8,
                                                  tablet: 12,
                                                  desktop: 16)),
                                    Container(
                                      padding:
                                          ResponsiveHelper.getResponsivePadding(
                                              context,
                                              mobile: 8,
                                              tablet: 12,
                                              desktop: 16),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.skyBlue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                            ResponsiveHelper
                                                .getResponsiveBorderRadius(
                                                    context,
                                                    mobile: 8,
                                                    tablet: 12,
                                                    desktop: 16)),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper
                                              .getResponsiveFontSize(context,
                                                  mobile: 12,
                                                  tablet: 14,
                                                  desktop: 16),
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
                    // Location only (removed rating and trips)
                    Row(
                      children: [
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
                      children: [
                        if (contactNumber != null && contactNumber.isNotEmpty)
                          Flexible(
                            flex: 3,
                            child: _buildActionButton(
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
                          ),
                        if (contactNumber != null && contactNumber.isNotEmpty)
                          const SizedBox(width: 8),
                        if (contactNumber != null && contactNumber.isNotEmpty)
                          Flexible(
                            flex: 4,
                            child: _buildActionButton(
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
          ? FaIcon(icon as IconData, color: Colors.white, size: 16)
          : Icon(icon as IconData, color: Colors.white, size: 16),
      label: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 36),
        maximumSize: const Size(double.infinity, 36),
      ),
    );
  }

  // Grid layout optimized card for tablets and iPads
  Widget _buildGridVehicleCard(
      BuildContext context, Map<String, dynamic> vehicle, bool isDarkMode) {
    final String make = vehicle['make'] ?? 'Unknown';
    final String model = vehicle['model'] ?? '';
    final String? year = vehicle['year']?.toString();
    final String? contactNumber =
        vehicle['driverDetails']?['whatsappNumber'] ?? vehicle['contactNumber'];
    final String? imageUrl = vehicle['images']?['primaryImageUrl'];
    final String? city = vehicle['collectionPoint']?['city'];
    final String? district = vehicle['collectionPoint']?['district'];
    final String? price =
        vehicle['pricing']?['daily']?['vehicleOnly']?['price']?.toString();
    final String locationString = [city, district]
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailPage(vehicle: vehicle),
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDarkMode ? AppColors.neutralDark : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - Fixed height
            Container(
              height: 120,
              width: double.infinity,
              child: Stack(
                children: [
                  imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.car_rental,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.car_rental,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                  if ((price ?? '').isNotEmpty)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFC107).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Rs. ${price ?? ''}/Day',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content section - Fixed height and scrollable if needed
            Container(
              height: 100,
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Make/Model and Brand Logo
                  Row(
                    children: [
                      // Brand logo
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(2),
                        child: CarLogoHelper.getCarLogo(make),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$make $model',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.neutralDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (year != null && year.isNotEmpty)
                              Text(
                                year,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : AppColors.neutralMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6),

                  // Location
                  if (locationString.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: AppColors.primary, size: 12),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationString,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : AppColors.neutralMedium,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (contactNumber != null &&
                                contactNumber.isNotEmpty) {
                              final uri =
                                  Uri(scheme: 'tel', path: contactNumber);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 10),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Call',
                                  style: TextStyle(fontSize: 8),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            minimumSize: Size(0, 26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        flex: 4,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (contactNumber != null &&
                                contactNumber.isNotEmpty) {
                              final cleanedNumber =
                                  cleanPhoneNumber(contactNumber);
                              final whatsappUrl =
                                  Uri.parse('https://wa.me/$cleanedNumber');
                              if (await canLaunchUrl(whatsappUrl)) {
                                await launchUrl(whatsappUrl,
                                    mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.whatsapp, size: 10),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'WhatsApp',
                                  style: TextStyle(fontSize: 8),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tertiary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            minimumSize: Size(0, 26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLargeTablet = ResponsiveHelper.isLargeTablet(context);
    final isIPad = ResponsiveHelper.isIPad(context);
    final isIPadPro = ResponsiveHelper.isIPadPro(context);

    // Use grid layout for tablets and iPads
    if (isTablet || isLargeTablet || isIPad || isIPadPro) {
      return GridView.builder(
        padding: ResponsiveHelper.getResponsivePaddingIPad(
          context,
          mobile: 16,
          tablet: 24,
          ipad: 32,
          ipadPro: 40,
          desktop: 48,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.getResponsiveGridColumns(
            context,
            mobile: 1,
            tablet: 2,
            ipad: 2,
            ipadPro: 2,
            desktop: 3,
          ),
          childAspectRatio: ResponsiveHelper.getResponsiveAspectRatio(
            context,
            mobile: 1.2,
            tablet: 0.75,
            ipad: 0.75,
            ipadPro: 0.75,
            desktop: 0.8,
          ),
          crossAxisSpacing: ResponsiveHelper.getResponsiveSpacingIPad(
            context,
            mobile: 16,
            tablet: 16,
            ipad: 20,
            ipadPro: 24,
            desktop: 28,
          ),
          mainAxisSpacing: ResponsiveHelper.getResponsiveSpacingIPad(
            context,
            mobile: 16,
            tablet: 16,
            ipad: 20,
            ipadPro: 24,
            desktop: 28,
          ),
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return _buildGridVehicleCard(
              context, _searchResults[index], isDarkMode);
        },
      );
    }

    // Use list layout for mobile
    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePaddingIPad(
        context,
        mobile: 16,
        tablet: 24,
        ipad: 32,
        ipadPro: 40,
        desktop: 48,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard(context, _searchResults[index], isDarkMode);
      },
    );
  }
}
