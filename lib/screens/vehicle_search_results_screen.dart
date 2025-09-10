import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      extendBodyBehindAppBar: false,
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
        elevation: 4,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFFFC107),
          statusBarIconBrightness: Brightness.dark,
        ),
        toolbarHeight: ResponsiveHelper.getResponsiveIconSize(context,
            mobile: 56, tablet: 64, ipad: 72, ipadPro: 80, desktop: 88),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: ResponsiveHelper.getResponsiveIconSize(context,
                mobile: 22, tablet: 26, ipad: 30, ipadPro: 34, desktop: 38),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Flexible(
          child: Text(
            _buildSearchTitle(),
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                  mobile: 16, tablet: 20, ipad: 24, ipadPro: 28, desktop: 32),
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Results count indicator
          if (_searchResults.isNotEmpty && !_isLoading)
            Container(
              margin: EdgeInsets.only(
                right: ResponsiveHelper.getResponsiveSpacingIPad(
                  context,
                  mobile: 8,
                  tablet: 12,
                  ipad: 16,
                  ipadPro: 20,
                  desktop: 24,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacingIPad(
                  context,
                  mobile: 8,
                  tablet: 10,
                  ipad: 12,
                  ipadPro: 14,
                  desktop: 16,
                ),
                vertical: ResponsiveHelper.getResponsiveSpacingIPad(
                  context,
                  mobile: 4,
                  tablet: 6,
                  ipad: 8,
                  ipadPro: 10,
                  desktop: 12,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_searchResults.length} found',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(
                    context,
                    mobile: 12,
                    tablet: 14,
                    ipad: 16,
                    ipadPro: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Enhanced Filter Button
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
                Icons.tune,
                color: const Color(0xFFFFC107),
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  ipad: 22,
                  ipadPro: 24,
                  desktop: 26,
                ),
              ),
              label: Text(
                'Filter',
                style: TextStyle(
                  color: const Color(0xFFFFC107),
                  fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(
                    context,
                    mobile: 12,
                    tablet: 14,
                    ipad: 16,
                    ipadPro: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: const Color(0xFFFFC107),
                elevation: 3,
                padding: ResponsiveHelper.getResponsiveButtonPadding(
                  context,
                  mobile:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  tablet:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  desktop:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(
                      context,
                      mobile: 24,
                      tablet: 26,
                      ipad: 28,
                      ipadPro: 30,
                      desktop: 32,
                    ),
                  ),
                ),
                minimumSize: Size(
                  ResponsiveHelper.getResponsiveSpacingIPad(
                    context,
                    mobile: 70,
                    tablet: 80,
                    ipad: 90,
                    ipadPro: 100,
                    desktop: 110,
                  ),
                  ResponsiveHelper.getResponsiveSpacingIPad(
                    context,
                    mobile: 32,
                    tablet: 36,
                    ipad: 40,
                    ipadPro: 44,
                    desktop: 48,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search summary bar
            if (!_isLoading && _searchResults.isNotEmpty)
              Container(
                width: double.infinity,
                padding: ResponsiveHelper.getResponsivePaddingIPad(
                  context,
                  mobile: 12,
                  tablet: 16,
                  ipad: 20,
                  ipadPro: 24,
                  desktop: 28,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.neutralDark.withOpacity(0.8)
                      : Colors.white.withOpacity(0.9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Found ${_searchResults.length} vehicle${_searchResults.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(
                            context,
                            mobile: 14,
                            tablet: 16,
                            ipad: 18,
                            ipadPro: 20,
                            desktop: 22,
                          ),
                          fontWeight: FontWeight.w600,
                          color:
                              isDarkMode ? Colors.white : AppColors.neutralDark,
                        ),
                      ),
                    ),
                    // Optional: Add sort button here if needed
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _searchResults.isEmpty
                          ? _buildNoResultsView()
                          : _buildResultsListView(),
            ),
          ],
        ),
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 16, tablet: 20, desktop: 24)),
          Text(
            'Searching for vehicles...',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                  mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : AppColors.neutralMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePaddingIPad(
          context,
          mobile: 24,
          tablet: 32,
          ipad: 40,
          ipadPro: 48,
          desktop: 56,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveHelper.getResponsiveIconSize(context,
                  mobile: 64, tablet: 72, ipad: 80, ipadPro: 88, desktop: 96),
              color: AppColors.error,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 16, tablet: 20, desktop: 24)),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                    mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 36),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.neutralDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 8, tablet: 12, desktop: 16)),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                    mobile: 14, tablet: 16, ipad: 18, ipadPro: 20, desktop: 22),
                color: isDarkMode ? Colors.white70 : AppColors.neutralMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 24, tablet: 32, desktop: 40)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: ResponsiveHelper.getResponsiveButtonPadding(
                      context,
                      mobile: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      tablet: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      desktop: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                    ),
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 12, tablet: 16, desktop: 20)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePaddingIPad(
          context,
          mobile: 24,
          tablet: 32,
          ipad: 40,
          ipadPro: 48,
          desktop: 56,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: ResponsiveHelper.getResponsiveIconSize(context,
                  mobile: 80,
                  tablet: 96,
                  ipad: 112,
                  ipadPro: 128,
                  desktop: 144),
              color:
                  isDarkMode ? AppColors.neutralMedium : AppColors.neutralLight,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 20, tablet: 24, desktop: 28)),
            Text(
              'No vehicles found',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                    mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.neutralDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 8, tablet: 12, desktop: 16)),
            Text(
              'Try adjusting your search criteria\nor explore different locations',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context,
                    mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
                color: isDarkMode
                    ? AppColors.neutralLight
                    : AppColors.neutralMedium,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 32, tablet: 40, desktop: 48)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showMergedFilterDrawer,
                  icon: const Icon(Icons.tune),
                  label: const Text('Adjust Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: ResponsiveHelper.getResponsiveButtonPadding(
                      context,
                      mobile: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      tablet: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      desktop: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 12, tablet: 16, desktop: 20)),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Search'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
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

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getResponsiveSpacing(context,
            mobile: 8, tablet: 10, desktop: 12),
        horizontal: 0,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context,
              mobile: 16, tablet: 18, desktop: 20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 16, tablet: 18, desktop: 20),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailPage(vehicle: vehicle),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.neutralDark : Colors.white,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context,
                    mobile: 16, tablet: 18, desktop: 20),
              ),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context,
                  mobile: 12, tablet: 14, ipad: 16, ipadPro: 18, desktop: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Image Section
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context,
                            mobile: 12, tablet: 14, desktop: 16),
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 12, tablet: 14, desktop: 16),
                          ),
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width:
                                      ResponsiveHelper.getResponsiveImageSize(
                                          context,
                                          mobile: 120,
                                          tablet: 140,
                                          ipad: 160,
                                          ipadPro: 180,
                                          desktop: 200),
                                  height:
                                      ResponsiveHelper.getResponsiveImageSize(
                                          context,
                                          mobile: 100,
                                          tablet: 120,
                                          ipad: 140,
                                          ipadPro: 160,
                                          desktop: 180),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width:
                                        ResponsiveHelper.getResponsiveImageSize(
                                            context,
                                            mobile: 120,
                                            tablet: 140,
                                            ipad: 160,
                                            ipadPro: 180,
                                            desktop: 200),
                                    height:
                                        ResponsiveHelper.getResponsiveImageSize(
                                            context,
                                            mobile: 100,
                                            tablet: 120,
                                            ipad: 140,
                                            ipadPro: 160,
                                            desktop: 180),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper
                                            .getResponsiveBorderRadius(context,
                                                mobile: 12,
                                                tablet: 14,
                                                desktop: 16),
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width:
                                        ResponsiveHelper.getResponsiveImageSize(
                                            context,
                                            mobile: 120,
                                            tablet: 140,
                                            ipad: 160,
                                            ipadPro: 180,
                                            desktop: 200),
                                    height:
                                        ResponsiveHelper.getResponsiveImageSize(
                                            context,
                                            mobile: 100,
                                            tablet: 120,
                                            ipad: 140,
                                            ipadPro: 160,
                                            desktop: 180),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper
                                            .getResponsiveBorderRadius(context,
                                                mobile: 12,
                                                tablet: 14,
                                                desktop: 16),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.directions_car_rounded,
                                      size: ResponsiveHelper
                                          .getResponsiveIconSize(context,
                                              mobile: 32,
                                              tablet: 40,
                                              desktop: 48),
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              : Container(
                                  width:
                                      ResponsiveHelper.getResponsiveImageSize(
                                          context,
                                          mobile: 120,
                                          tablet: 140,
                                          ipad: 160,
                                          ipadPro: 180,
                                          desktop: 200),
                                  height:
                                      ResponsiveHelper.getResponsiveImageSize(
                                          context,
                                          mobile: 100,
                                          tablet: 120,
                                          ipad: 140,
                                          ipadPro: 160,
                                          desktop: 180),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveHelper
                                          .getResponsiveBorderRadius(context,
                                              mobile: 12,
                                              tablet: 14,
                                              desktop: 16),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.directions_car_rounded,
                                    size:
                                        ResponsiveHelper.getResponsiveIconSize(
                                            context,
                                            mobile: 32,
                                            tablet: 40,
                                            desktop: 48),
                                    color: Colors.grey[400],
                                  ),
                                ),
                        ),
                        if ((price ?? '').isNotEmpty)
                          Positioned(
                            bottom: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 10,
                                desktop: 12),
                            left: ResponsiveHelper.getResponsiveSpacing(context,
                                mobile: 8, tablet: 10, desktop: 12),
                            right: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 10,
                                desktop: 12),
                            child: Container(
                              padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  mobile: 8,
                                  tablet: 10,
                                  desktop: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFC107),
                                    Color(0xFFFFB300)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(
                                      context,
                                      mobile: 8,
                                      tablet: 10,
                                      desktop: 12),
                                ),
                              ),
                              child: Text(
                                'Rs. ${price ?? ''} / Day',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobile: 11,
                                          tablet: 12,
                                          desktop: 13),
                                  letterSpacing: 0.5,
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
                  SizedBox(
                      width: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 16, tablet: 18, desktop: 20)),
                  // Enhanced Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Make/model/brand logo section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Enhanced Brand logo
                            Container(
                              margin: EdgeInsets.only(
                                  right: ResponsiveHelper.getResponsiveSpacing(
                                      context,
                                      mobile: 10,
                                      tablet: 12,
                                      desktop: 14)),
                              width: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 36,
                                  tablet: 40,
                                  desktop: 44),
                              height: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 36,
                                  tablet: 40,
                                  desktop: 44),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(
                                      context,
                                      mobile: 8,
                                      tablet: 10,
                                      desktop: 12),
                                ),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  desktop: 10),
                              child: CarLogoHelper.getCarLogo(make),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$make $model',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper
                                          .getResponsiveFontSize(context,
                                              mobile: 16,
                                              tablet: 18,
                                              desktop: 20),
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode
                                          ? Colors.white
                                          : AppColors.neutralDark,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                      height:
                                          ResponsiveHelper.getResponsiveSpacing(
                                              context,
                                              mobile: 4,
                                              tablet: 6,
                                              desktop: 8)),
                                  Row(
                                    children: [
                                      if (year != null && year.isNotEmpty) ...[
                                        Container(
                                          padding: ResponsiveHelper
                                              .getResponsivePadding(context,
                                                  mobile: 4,
                                                  tablet: 6,
                                                  desktop: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              ResponsiveHelper
                                                  .getResponsiveBorderRadius(
                                                      context,
                                                      mobile: 6,
                                                      tablet: 8,
                                                      desktop: 10),
                                            ),
                                          ),
                                          child: Text(
                                            year,
                                            style: TextStyle(
                                              fontSize: ResponsiveHelper
                                                  .getResponsiveFontSize(
                                                      context,
                                                      mobile: 11,
                                                      tablet: 12,
                                                      desktop: 13),
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            width: ResponsiveHelper
                                                .getResponsiveSpacing(context,
                                                    mobile: 8,
                                                    tablet: 10,
                                                    desktop: 12)),
                                      ],
                                      if (category != null &&
                                          category.isNotEmpty)
                                        Container(
                                          padding: ResponsiveHelper
                                              .getResponsivePadding(context,
                                                  mobile: 4,
                                                  tablet: 6,
                                                  desktop: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                                ResponsiveHelper
                                                    .getResponsiveBorderRadius(
                                                        context,
                                                        mobile: 6,
                                                        tablet: 8,
                                                        desktop: 10)),
                                          ),
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: ResponsiveHelper
                                                  .getResponsiveFontSize(
                                                      context,
                                                      mobile: 11,
                                                      tablet: 12,
                                                      desktop: 13),
                                              color: AppColors.secondary,
                                              fontWeight: FontWeight.w600,
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
                        SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16)),
                        // Location and rent mode info
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20),
                            ),
                            SizedBox(
                                width: ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 4,
                                    tablet: 6,
                                    desktop: 8)),
                            Expanded(
                              child: Text(
                                locationString.isNotEmpty
                                    ? locationString
                                    : 'Location not specified',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : AppColors.neutralMedium,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobile: 13,
                                          tablet: 14,
                                          desktop: 15),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 10,
                                desktop: 12)),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20),
                              color: AppColors.tertiary,
                            ),
                            SizedBox(
                                width: ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 4,
                                    tablet: 6,
                                    desktop: 8)),
                            Text(
                              rentMode ?? 'Vehicle Only',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                        context,
                                        mobile: 13,
                                        tablet: 14,
                                        desktop: 15),
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20)),
                        // Enhanced Action buttons
                        Row(
                          children: [
                            if (contactNumber != null &&
                                contactNumber.isNotEmpty) ...[
                              Expanded(
                                flex: 3,
                                child: _buildEnhancedActionButton(
                                  context,
                                  icon: Icons.phone_rounded,
                                  label: 'Call',
                                  color: AppColors.success,
                                  onTap: () async {
                                    final uri =
                                        Uri(scheme: 'tel', path: contactNumber);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Cannot make a call from this device.')),
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                  width: ResponsiveHelper.getResponsiveSpacing(
                                      context,
                                      mobile: 8,
                                      tablet: 10,
                                      desktop: 12)),
                              Expanded(
                                flex: 4,
                                child: _buildEnhancedActionButton(
                                  context,
                                  icon: FontAwesomeIcons.whatsapp,
                                  label: 'WhatsApp',
                                  color: AppColors.primary,
                                  isFaIcon: true,
                                  onTap: () async {
                                    final cleanedNumber =
                                        cleanPhoneNumber(contactNumber);
                                    final whatsappUrl = Uri.parse(
                                        'https://wa.me/$cleanedNumber');
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButton(BuildContext context,
      {required dynamic icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
      bool isFaIcon = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: isFaIcon
          ? FaIcon(
              icon as IconData,
              color: Colors.white,
              size: ResponsiveHelper.getResponsiveIconSize(context,
                  mobile: 14, tablet: 16, desktop: 18),
            )
          : Icon(
              icon as IconData,
              color: Colors.white,
              size: ResponsiveHelper.getResponsiveIconSize(context,
                  mobile: 14, tablet: 16, desktop: 18),
            ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context,
              mobile: 12, tablet: 13, desktop: 14),
          color: Colors.white,
          letterSpacing: 0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 20, tablet: 22, desktop: 24),
          ),
        ),
        elevation: 3,
        padding: ResponsiveHelper.getResponsiveButtonPadding(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tablet: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          desktop: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        minimumSize: Size(
          0,
          ResponsiveHelper.getResponsiveSpacing(context,
              mobile: 36, tablet: 40, desktop: 44),
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

  // Enhanced grid layout card for tablets and iPads
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

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveBorderRadius(context,
            mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context,
              mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailPage(vehicle: vehicle),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.neutralDark : Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context,
                  mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
            ),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Image section
              SizedBox(
                height: ResponsiveHelper.getResponsiveImageSize(
                  context,
                  mobile: 120,
                  tablet: 140,
                  ipad: 160,
                  ipadPro: 180,
                  desktop: 200,
                ),
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
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Icon(
                                Icons.directions_car_rounded,
                                size: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 40,
                                  tablet: 45,
                                  ipad: 50,
                                  ipadPro: 55,
                                  desktop: 60,
                                ),
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Icon(
                              Icons.directions_car_rounded,
                              size: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 40,
                                tablet: 45,
                                ipad: 50,
                                ipadPro: 55,
                                desktop: 60,
                              ),
                              color: Colors.grey[400],
                            ),
                          ),
                    // Enhanced price overlay
                    if ((price ?? '').isNotEmpty)
                      Positioned(
                        top: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 10,
                          ipad: 12,
                          ipadPro: 14,
                          desktop: 16,
                        ),
                        right: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 10,
                          ipad: 12,
                          ipadPro: 14,
                          desktop: 16,
                        ),
                        child: Container(
                          padding: ResponsiveHelper.getResponsivePadding(
                            context,
                            mobile: 6,
                            tablet: 8,
                            ipad: 10,
                            ipadPro: 12,
                            desktop: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(
                                context,
                                mobile: 8,
                                tablet: 10,
                                ipad: 12,
                                ipadPro: 14,
                                desktop: 16,
                              ),
                            ),
                          ),
                          child: Text(
                            'Rs. ${price ?? ''}/Day',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 10,
                                tablet: 11,
                                ipad: 12,
                                ipadPro: 13,
                                desktop: 14,
                              ),
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Enhanced Content section
              Expanded(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    mobile: 12,
                    tablet: 14,
                    ipad: 16,
                    ipadPro: 18,
                    desktop: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Make/Model and Brand Logo
                      Row(
                        children: [
                          // Enhanced brand logo
                          Container(
                            margin: EdgeInsets.only(
                              right: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 10,
                                ipad: 12,
                                ipadPro: 14,
                                desktop: 16,
                              ),
                            ),
                            width: ResponsiveHelper.getResponsiveIconSize(
                              context,
                              mobile: 24,
                              tablet: 28,
                              ipad: 32,
                              ipadPro: 36,
                              desktop: 40,
                            ),
                            height: ResponsiveHelper.getResponsiveIconSize(
                              context,
                              mobile: 24,
                              tablet: 28,
                              ipad: 32,
                              ipadPro: 36,
                              desktop: 40,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveBorderRadius(
                                  context,
                                  mobile: 6,
                                  tablet: 7,
                                  ipad: 8,
                                  ipadPro: 9,
                                  desktop: 10,
                                ),
                              ),
                            ),
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              mobile: 4,
                              tablet: 5,
                              ipad: 6,
                              ipadPro: 7,
                              desktop: 8,
                            ),
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
                                      mobile: 13,
                                      tablet: 14,
                                      ipad: 15,
                                      ipadPro: 16,
                                      desktop: 17,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode
                                        ? Colors.white
                                        : AppColors.neutralDark,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (year != null && year.isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.only(
                                      top:
                                          ResponsiveHelper.getResponsiveSpacing(
                                        context,
                                        mobile: 2,
                                        tablet: 3,
                                        ipad: 4,
                                        ipadPro: 5,
                                        desktop: 6,
                                      ),
                                    ),
                                    padding:
                                        ResponsiveHelper.getResponsivePadding(
                                      context,
                                      mobile: 3,
                                      tablet: 4,
                                      ipad: 5,
                                      ipadPro: 6,
                                      desktop: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper
                                            .getResponsiveBorderRadius(
                                          context,
                                          mobile: 4,
                                          tablet: 5,
                                          ipad: 6,
                                          ipadPro: 7,
                                          desktop: 8,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      year,
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 9,
                                          tablet: 10,
                                          ipad: 11,
                                          ipadPro: 12,
                                          desktop: 13,
                                        ),
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 10,
                          ipad: 12,
                          ipadPro: 14,
                          desktop: 16,
                        ),
                      ),

                      // Location
                      if (locationString.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                ipad: 14,
                                ipadPro: 15,
                                desktop: 16,
                              ),
                            ),
                            SizedBox(
                              width: ResponsiveHelper.getResponsiveSpacing(
                                context,
                                mobile: 4,
                                tablet: 5,
                                ipad: 6,
                                ipadPro: 7,
                                desktop: 8,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                locationString,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : AppColors.neutralMedium,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    mobile: 10,
                                    tablet: 11,
                                    ipad: 12,
                                    ipadPro: 13,
                                    desktop: 14,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      // Enhanced action buttons (no shadow/elevation)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextButton(
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
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  mobile: 6,
                                  tablet: 7,
                                  ipad: 8,
                                  ipadPro: 9,
                                  desktop: 10,
                                ),
                                minimumSize: Size(
                                  0,
                                  ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 28,
                                    tablet: 30,
                                    ipad: 32,
                                    ipadPro: 34,
                                    desktop: 36,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveBorderRadius(
                                      context,
                                      mobile: 12,
                                      tablet: 13,
                                      ipad: 14,
                                      ipadPro: 15,
                                      desktop: 16,
                                    ),
                                  ),
                                ),
                                elevation: 0, // No shadow
                                shadowColor: Colors.transparent,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size:
                                        ResponsiveHelper.getResponsiveIconSize(
                                      context,
                                      mobile: 12,
                                      tablet: 13,
                                      ipad: 14,
                                      ipadPro: 15,
                                      desktop: 16,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        ResponsiveHelper.getResponsiveSpacing(
                                      context,
                                      mobile: 4,
                                      tablet: 5,
                                      ipad: 6,
                                      ipadPro: 7,
                                      desktop: 8,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      'Call',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 9,
                                          tablet: 10,
                                          ipad: 11,
                                          ipadPro: 12,
                                          desktop: 13,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveSpacing(
                              context,
                              mobile: 6,
                              tablet: 7,
                              ipad: 8,
                              ipadPro: 9,
                              desktop: 10,
                            ),
                          ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  mobile: 6,
                                  tablet: 7,
                                  ipad: 8,
                                  ipadPro: 9,
                                  desktop: 10,
                                ),
                                minimumSize: Size(
                                  0,
                                  ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 28,
                                    tablet: 30,
                                    ipad: 32,
                                    ipadPro: 34,
                                    desktop: 36,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveBorderRadius(
                                      context,
                                      mobile: 12,
                                      tablet: 13,
                                      ipad: 14,
                                      ipadPro: 15,
                                      desktop: 16,
                                    ),
                                  ),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    size:
                                        ResponsiveHelper.getResponsiveIconSize(
                                      context,
                                      mobile: 12,
                                      tablet: 13,
                                      ipad: 14,
                                      ipadPro: 15,
                                      desktop: 16,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        ResponsiveHelper.getResponsiveSpacing(
                                      context,
                                      mobile: 4,
                                      tablet: 5,
                                      ipad: 6,
                                      ipadPro: 7,
                                      desktop: 8,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      'WhatsApp',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 9,
                                          tablet: 10,
                                          ipad: 11,
                                          ipadPro: 12,
                                          desktop: 13,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSearchTitle() {
    if (widget.selectedVehicleTypes.isEmpty) {
      return 'All Vehicles ${widget.location.isEmpty ? "" : "in  ${widget.location}"}';
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
      return Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.neutralDark.withOpacity(0.95)
              : AppColors.neutralBackground,
        ),
        child: GridView.builder(
          padding: ResponsiveHelper.getResponsivePaddingIPad(
            context,
            mobile: 16,
            tablet: 20,
            ipad: 24,
            ipadPro: 28,
            desktop: 32,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.getResponsiveGridColumns(
              context,
              mobile: 1,
              tablet: 2,
              ipad: 2,
              ipadPro: 3,
              desktop: 3,
            ),
            childAspectRatio: ResponsiveHelper.getResponsiveAspectRatio(
              context,
              mobile: 1.2,
              tablet: 0.85,
              ipad: 0.9,
              ipadPro: 0.8,
              desktop: 0.85,
            ),
            crossAxisSpacing: ResponsiveHelper.getResponsiveSpacingIPad(
              context,
              mobile: 16,
              tablet: 18,
              ipad: 20,
              ipadPro: 22,
              desktop: 24,
            ),
            mainAxisSpacing: ResponsiveHelper.getResponsiveSpacingIPad(
              context,
              mobile: 16,
              tablet: 18,
              ipad: 20,
              ipadPro: 22,
              desktop: 24,
            ),
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildGridVehicleCard(
                context, _searchResults[index], isDarkMode);
          },
        ),
      );
    }

    // Use enhanced list layout for mobile
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.neutralDark.withOpacity(0.95)
            : AppColors.neutralBackground,
      ),
      child: ListView.builder(
        padding: ResponsiveHelper.getResponsivePaddingIPad(
          context,
          mobile: 16,
          tablet: 20,
          ipad: 24,
          ipadPro: 28,
          desktop: 32,
        ),
        itemCount: _searchResults.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutCubic,
            child:
                _buildVehicleCard(context, _searchResults[index], isDarkMode),
          );
        },
      ),
    );
  }
}
