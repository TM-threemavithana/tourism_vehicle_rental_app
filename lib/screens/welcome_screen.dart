import 'package:flutter/material.dart';
import 'request_vehicle_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'renter/my_booking_requests_screen.dart';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vehicle_search_results_screen.dart';
import '../widgets/side_menu.dart';
import '../utils/responsive_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache HomeScreen images
    precacheImage(const AssetImage('assets/images/logo.png'), context);
    precacheImage(
        const AssetImage('assets/images/road_background.jpg'), context);
  }

  Future<void> _navigateToBrowse(BuildContext context) async {
    setState(() => _isLoading = true);
    await precacheImage(const AssetImage('assets/images/logo.png'), context);
    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => VehicleSearchResultsScreen(
          selectedVehicleTypes: {},
          location: '',
          pickupDate: DateTime.now(),
          pickupTime: const TimeOfDay(hour: 10, minute: 0),
          returnDate: DateTime.now().add(const Duration(days: 1)),
          returnTime: const TimeOfDay(hour: 10, minute: 0),
          flexibleDates: false,
          make: null,
          model: null,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // Add iPad Pro specific helper method for optimized spacing
  double _getOptimizedSpacing(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double ipad,
    required double ipadPro,
    required double desktop,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Enhanced detection for iPad Pro landscape mode where overflow typically occurs
    if (ResponsiveHelper.isIPadPro(context)) {
      // In landscape mode (width > height), reduce spacing more aggressively
      if (screenWidth > screenHeight) {
        return ResponsiveHelper.getResponsiveSpacingIPad(context,
            mobile: mobile,
            tablet: tablet,
            ipad: ipad,
            ipadPro: ipadPro * 0.5, // Reduce by 50% in landscape
            desktop: desktop);
      }
      // In portrait mode, moderate reduction
      else {
        return ResponsiveHelper.getResponsiveSpacingIPad(context,
            mobile: mobile,
            tablet: tablet,
            ipad: ipad,
            ipadPro: ipadPro * 0.7, // Reduce by 30% in portrait
            desktop: desktop);
      }
    }

    return ResponsiveHelper.getResponsiveSpacingIPad(context,
        mobile: mobile,
        tablet: tablet,
        ipad: ipad,
        ipadPro: ipadPro,
        desktop: desktop);
  }

  // Helper method to get dynamic card height based on available screen space
  double _getCardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isIPadPro = ResponsiveHelper.isIPadPro(context);

    if (isIPadPro) {
      // Calculate available height after headers and navigation
      final availableHeight = screenHeight -
          MediaQuery.of(context).padding.top - // Status bar
          kBottomNavigationBarHeight - // Bottom nav
          100; // Header space

      // Return appropriate height for cards (accounting for 2 cards + spacing)
      return (availableHeight - 60) / 2; // 60 for spacing between cards
    }

    return double.infinity; // Default behavior for other devices
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLargeTablet = ResponsiveHelper.isLargeTablet(context);
    final isIPad = ResponsiveHelper.isIPad(context);
    final isIPadPro = ResponsiveHelper.isIPadPro(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7FBEF),
      drawer: SideMenu(
        onClose: () => Navigator.of(context).pop(),
        onSignOut: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/auth');
        },
        onProfileTap: () {
          Navigator.pushNamed(context, '/profile');
        },
        user: FirebaseAuth.instance.currentUser,
        currentTab: '',
      ),
      body: Stack(
        children: [
          // Yellow status bar overlay
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color(0xFFFFC107),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight * 0.95,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding:
                            ResponsiveHelper.getResponsiveHorizontalPadding(
                          context,
                          mobile: 16,
                          tablet: 24,
                          ipad: 40,
                          ipadPro: 60,
                          desktop: 80,
                        ),
                        child: Column(
                          children: [
                            // Responsive spacing
                            SizedBox(
                                height: _getOptimizedSpacing(context,
                                    mobile: 12,
                                    tablet: 20,
                                    ipad: 24,
                                    ipadPro: 8,
                                    desktop: 40)),

                            // Side menu button and centered title in a row
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.menu,
                                    color: Colors.black,
                                    size:
                                        ResponsiveHelper.getResponsiveIconSize(
                                            context,
                                            mobile: 24,
                                            tablet: 28,
                                            ipad: 32,
                                            ipadPro: 32,
                                            desktop: 40),
                                  ),
                                  onPressed: () =>
                                      _scaffoldKey.currentState?.openDrawer(),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Wayz',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSizeIPad(context,
                                                mobile: 20,
                                                tablet: 28,
                                                ipad: 32,
                                                ipadPro: 32,
                                                desktop: 40),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width:
                                        ResponsiveHelper.getResponsiveIconSize(
                                                context,
                                                mobile: 24,
                                                tablet: 28,
                                                ipad: 32,
                                                ipadPro: 32,
                                                desktop: 40) +
                                            20),
                              ],
                            ),

                            SizedBox(
                                height: _getOptimizedSpacing(context,
                                    mobile: 12,
                                    tablet: 20,
                                    ipad: 24,
                                    ipadPro: 8,
                                    desktop: 40)),

                            // Responsive layout for tablets and iPads
                            if (isTablet ||
                                isLargeTablet ||
                                isIPad ||
                                isIPadPro) ...[
                              // Tablet/iPad layout - side by side cards with better spacing
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: isIPadPro
                                              ? _getCardHeight(context)
                                              : double.infinity,
                                        ),
                                        child: _FeatureCard(
                                          image:
                                              'assets/images/browse_vehicle.png',
                                          title: 'Browse Vehicles',
                                          description:
                                              "Explore our diverse fleet of vehicles, from scooters to luxury cars, perfect for your Sri Lankan adventure.",
                                          buttonText: 'Browse',
                                          onPressed: _isLoading
                                              ? null
                                              : () =>
                                                  _navigateToBrowse(context),
                                          isLoading: _isLoading,
                                          isCompact: isIPadPro,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        width: ResponsiveHelper
                                            .getResponsiveSpacingIPad(context,
                                                mobile: 12,
                                                tablet: 20,
                                                ipad: 24,
                                                ipadPro: 16,
                                                desktop: 32)),
                                    Expanded(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: isIPadPro
                                              ? _getCardHeight(context)
                                              : double.infinity,
                                        ),
                                        child: _FeatureCard(
                                          image:
                                              'assets/images/request_vehicle.png',
                                          title: 'Request a Vehicle',
                                          description:
                                              "Can't find what you're looking for? Post a request and let our network of providers find the perfect vehicle for you.",
                                          buttonText: 'Request',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const RequestVehicleScreen(),
                                              ),
                                            );
                                          },
                                          isCompact: isIPadPro,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Mobile layout - stacked cards
                              Expanded(
                                flex: 1,
                                child: _FeatureCard(
                                  image: 'assets/images/browse_vehicle.png',
                                  title: 'Browse Vehicles',
                                  description:
                                      "Explore our diverse fleet of vehicles, from scooters to luxury cars, perfect for your Sri Lankan adventure.",
                                  buttonText: 'Browse',
                                  onPressed: _isLoading
                                      ? null
                                      : () => _navigateToBrowse(context),
                                  isLoading: _isLoading,
                                ),
                              ),
                              SizedBox(
                                  height:
                                      ResponsiveHelper.getResponsiveSpacingIPad(
                                          context,
                                          mobile: 12,
                                          tablet: 16,
                                          ipad: 20,
                                          ipadPro: 16,
                                          desktop: 28)),
                              Expanded(
                                flex: 1,
                                child: _FeatureCard(
                                  image: 'assets/images/request_vehicle.png',
                                  title: 'Request a Vehicle',
                                  description:
                                      "Can't find what you're looking for? Post a request and let our network of providers find the perfect vehicle for you.",
                                  buttonText: 'Request',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RequestVehicleScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            // Add bottom spacing for overflow prevention
                            SizedBox(
                                height: _getOptimizedSpacing(context,
                                    mobile: 16,
                                    tablet: 20,
                                    ipad: 24,
                                    ipadPro: 8,
                                    desktop: 32)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const MyBookingRequestsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(user: FirebaseAuth.instance.currentUser)),
            );
          }
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isCompact; // Add compact mode for better space utilization

  const _FeatureCard({
    required this.image,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
    this.isLoading = false,
    this.isCompact = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLargeTablet = ResponsiveHelper.isLargeTablet(context);
    final isIPad = ResponsiveHelper.isIPad(context);
    final isIPadPro = ResponsiveHelper.isIPadPro(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context,
                mobile: 12, tablet: 16, ipad: 20, ipadPro: 24, desktop: 28)),
        boxShadow: ResponsiveHelper.getResponsiveShadow(context,
            mobile: 2, tablet: 4, ipad: 6, ipadPro: 8, desktop: 10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(
                  context,
                  mobile: 12,
                  tablet: 16,
                  ipad: 20,
                  ipadPro: 24,
                  desktop: 28)),
            ),
            child: AspectRatio(
              aspectRatio: isCompact
                  ? 2.5 // More compact ratio for iPad Pro
                  : ResponsiveHelper.getResponsiveAspectRatio(
                      context,
                      mobile: 2.0,
                      tablet: 2.2,
                      ipad: 2.0,
                      ipadPro: 2.2,
                      desktop: 2.5,
                    ),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(image),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.15),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: isCompact
                ? EdgeInsets.all(12) // Compact padding for iPad Pro
                : ResponsiveHelper.getResponsivePaddingIPad(
                    context,
                    mobile: 16,
                    tablet: 20,
                    ipad: 24,
                    ipadPro: 20,
                    desktop: 32,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact
                        ? 22 // Fixed size for compact mode
                        : ResponsiveHelper.getResponsiveFontSizeIPad(
                            context,
                            mobile: 16,
                            tablet: 20,
                            ipad: 24,
                            ipadPro: 28,
                            desktop: 32,
                          ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                    height: isCompact
                        ? 4 // Compact spacing
                        : ResponsiveHelper.getResponsiveSpacingIPad(context,
                            mobile: 4,
                            tablet: 6,
                            ipad: 8,
                            ipadPro: 6,
                            desktop: 12)),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isCompact
                        ? 14 // Fixed size for compact mode
                        : ResponsiveHelper.getResponsiveFontSizeIPad(
                            context,
                            mobile: 13,
                            tablet: 15,
                            ipad: 17,
                            ipadPro: 19,
                            desktop: 21,
                          ),
                    color: Colors.grey[700],
                  ),
                  maxLines: isCompact
                      ? 2 // Fewer lines for compact mode
                      : (isTablet || isLargeTablet || isIPad || isIPadPro)
                          ? 4
                          : 2, // More lines for tablets and iPads
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                    height: isCompact
                        ? 6 // Compact spacing
                        : ResponsiveHelper.getResponsiveSpacingIPad(context,
                            mobile: 8,
                            tablet: 10,
                            ipad: 12,
                            ipadPro: 10,
                            desktop: 16)),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB6E23A),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 20,
                                tablet: 25,
                                ipad: 30,
                                ipadPro: 35,
                                desktop: 30)),
                      ),
                      padding: ResponsiveHelper.getResponsiveButtonPadding(
                        context,
                        mobile: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        tablet: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        ipad: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        ipadPro: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        desktop: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(
                            context,
                            mobile: 14,
                            tablet: 16,
                            ipad: 18,
                            ipadPro: 20,
                            desktop: 22),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onPressed,
                    child: isLoading
                        ? SizedBox(
                            width: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28),
                            height: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
