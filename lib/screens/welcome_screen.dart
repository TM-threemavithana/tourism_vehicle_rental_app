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

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLargeTablet = ResponsiveHelper.isLargeTablet(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7FBEF),
      drawer: SideMenu(
        onClose: () => Navigator.of(context).pop(),
        onSignOut: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/auth');
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
            child: Padding(
              padding: ResponsiveHelper.getResponsiveHorizontalPadding(context),
              child: Column(
                children: [
                  // Responsive spacing
                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 12, tablet: 20, desktop: 24)),

                  // Side menu button and centered title in a row
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Colors.black,
                          size: ResponsiveHelper.getResponsiveIconSize(context),
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Wayz',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 20,
                                  tablet: 28,
                                  desktop: 32),
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          width:
                              ResponsiveHelper.getResponsiveIconSize(context) +
                                  20), // Responsive spacer
                    ],
                  ),

                  SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(context,
                          mobile: 12, tablet: 20, desktop: 24)),

                  // Responsive layout for tablets
                  if (isTablet || isLargeTablet) ...[
                    // Tablet layout - side by side cards
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
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
                              width: ResponsiveHelper.getResponsiveSpacing(
                                  context,
                                  mobile: 12,
                                  tablet: 20,
                                  desktop: 24)),
                          Expanded(
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
                        height: ResponsiveHelper.getResponsiveSpacing(context,
                            mobile: 12, tablet: 20, desktop: 24)),
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
                ],
              ),
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
  final Color? buttonColor;
  final bool isLoading;

  const _FeatureCard({
    required this.image,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
    this.buttonColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLargeTablet = ResponsiveHelper.isLargeTablet(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context)),
        boxShadow: ResponsiveHelper.getResponsiveShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context)),
            ),
            child: AspectRatio(
              aspectRatio: ResponsiveHelper.getResponsiveAspectRatio(context),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.directions_car,
                    size: ResponsiveHelper.getResponsiveIconSize(context,
                        mobile: 48, tablet: 64, desktop: 80),
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                        mobile: 16, tablet: 20, desktop: 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 4, tablet: 8, desktop: 12)),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                        mobile: 13, tablet: 15, desktop: 17),
                    color: Colors.grey[700],
                  ),
                  maxLines: isTablet || isLargeTablet
                      ? 3
                      : 2, // More lines for tablets
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 8, tablet: 12, desktop: 16)),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor ?? const Color(0xFFB6E23A),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 20, tablet: 25, desktop: 30)),
                      ),
                      padding:
                          ResponsiveHelper.getResponsiveButtonPadding(context),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18),
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
