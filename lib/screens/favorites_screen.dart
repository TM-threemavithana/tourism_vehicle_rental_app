import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/favorite_model.dart';
import '../services/favorites_service.dart';
import '../widgets/side_menu.dart';
import '../widgets/custom_app_bar.dart';
import 'vehicle_detail_page.dart';
import '../utils/responsive_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isMenuOpen = false;
  String _currentTab = 'Favorites';
  final _currencyFormat = NumberFormat("#,##0", "en_US");
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
    });
  }

  void _updateCurrentTab(String tabName) {
    setState(() {
      _currentTab = tabName;
    });
    _closeMenu();
  }

  void _navigateToVehicleDetail(Map<String, dynamic> vehicleData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(
          vehicle: vehicleData,
        ),
      ),
    );
  }

  Future<void> _removeFavorite(String vehicleId) async {
    await _favoritesService.removeFromFavorites(vehicleId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Favorite Vehicles',
        showBackButton: false,
        backgroundColor: theme.colorScheme.primary,
        iconColor: Colors.white,
        leadingWidget: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: _toggleMenu,
        ),
      ),
      body: Stack(
        children: [
          // Yellow status bar overlay
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color(0xFFFFC107),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<List<Favorite>>(
                stream: _favoritesService.getFavorites(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final favorites = snapshot.data ?? [];

                  if (favorites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 80,
                                tablet: 100,
                                desktop: 120),
                            color: isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  desktop: 24)),
                          Text(
                            'No favorite vehicles yet',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 18,
                                  tablet: 20,
                                  desktop: 22),
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16)),
                          Text(
                            'Your favorite vehicles will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18),
                            ),
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 24,
                                  tablet: 32,
                                  desktop: 40)),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  ResponsiveHelper.getResponsiveButtonPadding(
                                      context),
                            ),
                            child: Text('Browse Vehicles'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {}); // Refresh the UI
                    },
                    child: ListView.builder(
                      padding: ResponsiveHelper.getResponsivePadding(context),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = favorites[index];

                        return _buildFavoriteCard(
                          context,
                          favorite,
                          isDarkMode,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Side menu and overlay
          if (_isMenuOpen) ...[
            // Semi-transparent overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

            // Side menu
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.7,
              child: SideMenu(
                onClose: _closeMenu,
                onSignOut: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/auth');
                  }
                },
                onTabChange: (tab) {
                  _updateCurrentTab(tab);

                  // Handle navigation based on the selected tab
                  switch (tab) {
                    case 'Search Vehicles':
                      Navigator.pushReplacementNamed(context, '/home');
                      break;
                    case 'My Rentals':
                      // Navigate to My Rentals screen when implemented
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Rentals feature coming soon')),
                      );
                      break;
                    case 'Favorites':
                      // Already on Favorites screen
                      break;
                    default:
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$tab feature coming soon')),
                      );
                  }
                },
                onProfileTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                width: 0.7,
                user: FirebaseAuth.instance.currentUser,
                currentTab: _currentTab,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(
      BuildContext context, Favorite favorite, bool isDarkMode) {
    final vehicleData = favorite.vehicleData;
    final theme = Theme.of(context);

    // Get main image URL or placeholder
    final String mainImageUrl = _getMainImageUrl(vehicleData);

    // Format price
    final price = vehicleData['pricing']?['daily']?['baseRate'] ?? 0;
    final formattedPrice = 'LKR ${_currencyFormat.format(price)}';

    return Card(
      margin: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveSpacing(context,
              mobile: 16, tablet: 20, desktop: 24)),
      elevation: ResponsiveHelper.isTablet(context) ? 4 : 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context,
                  mobile: 12, tablet: 16, desktop: 20))),
      child: InkWell(
        onTap: () => _navigateToVehicleDetail(vehicleData),
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay and actions
            Stack(
              children: [
                // Vehicle image
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context,
                            mobile: 12, tablet: 16, desktop: 20)),
                    topRight: Radius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context,
                            mobile: 12, tablet: 16, desktop: 20)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveImageSize(context,
                        mobile: 160, tablet: 200, desktop: 240),
                    child: CachedNetworkImage(
                      imageUrl: mainImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, size: 30),
                      ),
                    ),
                  ),
                ),

                // Price badge
                Positioned(
                  bottom: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20),
                  right: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getResponsiveSpacing(
                            context,
                            mobile: 12,
                            tablet: 16,
                            desktop: 20),
                        vertical: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 6, tablet: 8, desktop: 10)),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$formattedPrice/day',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16),
                      ),
                    ),
                  ),
                ),

                // Favorite icon button
                Positioned(
                  top: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16),
                  right: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16),
                  child: CircleAvatar(
                    radius: ResponsiveHelper.getResponsiveIconSize(context,
                        mobile: 18, tablet: 22, desktop: 26),
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: ResponsiveHelper.getResponsiveIconSize(context,
                              mobile: 18, tablet: 22, desktop: 26)),
                      color: Colors.red,
                      onPressed: () => _removeFavorite(vehicleData['id']),
                      tooltip: 'Remove from favorites',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),

                // Vehicle type badge
                Positioned(
                  top: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 10, tablet: 12, desktop: 16),
                  left: ResponsiveHelper.getResponsiveSpacing(context,
                      mobile: 10, tablet: 12, desktop: 16),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getResponsiveSpacing(
                            context,
                            mobile: 10,
                            tablet: 12,
                            desktop: 16),
                        vertical: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 6, tablet: 8, desktop: 10)),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vehicleData['type'] ?? 'Vehicle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Vehicle details
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context,
                  mobile: 12, tablet: 16, desktop: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle title
                  Text(
                    '${vehicleData['make'] ?? 'Unknown'} ${vehicleData['model'] ?? ''}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 18, tablet: 20, desktop: 22),
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 6, tablet: 8, desktop: 10)),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: ResponsiveHelper.getResponsiveIconSize(context,
                            mobile: 16, tablet: 18, desktop: 20),
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      SizedBox(
                          width: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 4, tablet: 6, desktop: 8)),
                      Expanded(
                        child: Text(
                          vehicleData['collectionPoint']?['district'] ??
                              'Location not specified',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18),
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 8, tablet: 10, desktop: 12)),

                  // Vehicle specs row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSpecChip(
                        Icons.calendar_today_outlined,
                        vehicleData['year']?.toString() ?? 'N/A',
                        isDarkMode,
                      ),
                      _buildSpecChip(
                        Icons.settings,
                        vehicleData['transmission'] ?? 'N/A',
                        isDarkMode,
                      ),
                      _buildSpecChip(
                        Icons.local_gas_station,
                        vehicleData['fuelType'] ?? 'N/A',
                        isDarkMode,
                      ),
                      _buildSpecChip(
                        Icons.airline_seat_recline_normal,
                        '${vehicleData['seatingCapacity'] ?? '?'} seats',
                        isDarkMode,
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

  String _getMainImageUrl(Map<String, dynamic> vehicleData) {
    // Check for images in different possible structures
    if (vehicleData['images'] is List) {
      final List<dynamic> images = vehicleData['images'] as List;
      if (images.isNotEmpty) {
        return images.first.toString();
      }
    } else if (vehicleData['images'] is Map) {
      final imagesMap = vehicleData['images'] as Map<String, dynamic>;
      if (imagesMap['primaryImageUrl'] != null) {
        return imagesMap['primaryImageUrl'].toString();
      }
      if (imagesMap['additionalImages'] is List &&
          (imagesMap['additionalImages'] as List).isNotEmpty) {
        return (imagesMap['additionalImages'] as List).first.toString();
      }
    }

    return 'https://via.placeholder.com/400x250?text=No+Image+Available';
  }

  Widget _buildSpecChip(IconData icon, String text, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context,
              mobile: 8, tablet: 10, desktop: 12),
          vertical: ResponsiveHelper.getResponsiveSpacing(context,
              mobile: 4, tablet: 6, desktop: 8)),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.getResponsiveIconSize(context,
                mobile: 14, tablet: 16, desktop: 18),
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
          SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 4, tablet: 6, desktop: 8)),
          Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                  mobile: 12, tablet: 14, desktop: 16),
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
