import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/auth_wrapper.dart';
import '../../widgets/side_menu.dart';
import '../profile_screen.dart';
import 'add_vehicle_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isMenuOpen = false;
  String _currentTab = 'Dashboard';
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  // Add this line to define isDarkMode
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  // Sample data - in a real app, fetch from a data service
  List<Map<String, dynamic>> _recentBookings = [
    {
      'vehicleName': 'Toyota Corolla',
      'renterName': 'John Doe',
      'startDate': DateTime.now().add(const Duration(days: 1)),
      'endDate': DateTime.now().add(const Duration(days: 4)),
      'amount': 12000.0,
      'status': 'Upcoming',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'vehicleName': 'Honda Civic',
      'renterName': 'Jane Smith',
      'startDate': DateTime.now().subtract(const Duration(days: 2)),
      'endDate': DateTime.now().add(const Duration(days: 1)),
      'amount': 9000.0,
      'status': 'Active',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
    }
  ];

  // Store fetched statistics
  Map<String, dynamic> _vehicleStats = {
    'vehiclesListed': '0',
    'activeRentals': '0',
    'totalEarnings': 'LKR 0',
    'avgRating': '0',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    
    // Add this line to fetch statistics when the screen loads
    _fetchVehicleStatistics();
    _fetchRecentBookings();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          user: FirebaseAuth.instance.currentUser,
        ),
      ),
    );
  }

  void _switchToRenterMode() {
    // TODO: Implement switching to renter mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switching to renter mode - Coming soon!')),
    );
  }

  void _addNewVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
    );

    if (result == true) {
      // Refresh the dashboard data if needed
      setState(() {});
    }
  }

  String _getUserFirstName() {
    final fullName = FirebaseAuth.instance.currentUser?.displayName ?? 'Owner';
    return fullName.split(' ').first;
  }

  // Fetch statistics from Firestore
  Future<void> _fetchVehicleStatistics() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    try {
      // Get vehicles count
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: userId)
          .get();
      
      final vehicleCount = vehiclesSnapshot.docs.length.toString();
      
      // Get active rentals (this depends on your rental data structure)
      final activeRentalsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: 'Active')
          .get();
      
      final activeRentals = activeRentalsSnapshot.docs.length.toString();
      
      // Calculate earnings (simplified - you'll need to adjust based on your data model)
      double totalEarnings = 0;
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: userId)
          .where('status', whereIn: ['Completed', 'Active'])
          .get();
      
      for (var doc in bookingsSnapshot.docs) {
        final booking = doc.data();
        totalEarnings += booking['amount'] ?? 0;
      }
      
      // Calculate average rating (simplified)
      double totalRating = 0;
      int ratingCount = 0;
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('ownerId', isEqualTo: userId)
          .get();
      
      for (var doc in ratingsSnapshot.docs) {
        final rating = doc.data();
        totalRating += rating['rating'] ?? 0;
        ratingCount++;
      }
      
      final avgRating = ratingCount > 0 
          ? (totalRating / ratingCount).toStringAsFixed(1) + '/5'
          : 'No ratings';
      
      if (mounted) {
        setState(() {
          _vehicleStats = {
            'vehiclesListed': vehicleCount,
            'activeRentals': activeRentals,
            'totalEarnings': 'LKR ${totalEarnings.toStringAsFixed(0)}',
            'avgRating': avgRating,
          };
        });
      }
    } catch (e) {
      print('Error fetching statistics: $e');
    }
  }

  // Add this method to fetch bookings
  Future<void> _fetchRecentBookings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .limit(5)
          .get();
      
      final bookings = await Future.wait(
        bookingsSnapshot.docs.map((doc) async {
          final bookingData = doc.data();
          
          // Get renter information (adjust according to your data structure)
          String renterName = 'Unknown Renter';
          String renterAvatar = 'https://ui-avatars.com/api/?name=Unknown&background=random';
          
          if (bookingData['renterId'] != null) {
            final renterSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(bookingData['renterId'])
                .get();
            
            if (renterSnapshot.exists) {
              final renterData = renterSnapshot.data()!;
              renterName = renterData['name'] ?? renterName;
              renterAvatar = renterData['profilePic'] ?? renterAvatar;
            }
          }
          
          return {
            'vehicleName': '${bookingData['vehicleMake'] ?? 'Vehicle'} ${bookingData['vehicleModel'] ?? ''}',
            'renterName': renterName,
            'startDate': bookingData['startDate'].toDate(),
            'endDate': bookingData['endDate'].toDate(),
            'amount': bookingData['amount'] ?? 0.0,
            'status': bookingData['status'] ?? 'Unknown',
            'avatar': renterAvatar,
          };
        }),
      );
      
      if (mounted) {
        setState(() {
          _recentBookings = bookings;
        });
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _fetchVehicleStatistics(),
      _fetchRecentBookings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  theme.colorScheme.primary,
                ],
              ),
            ),
            height: screenHeight * 0.25,
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: _toggleMenu,
                      ),
                      const Text(
                        'OWNER DASHBOARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.swap_horiz,
                                color: Colors.white),
                            onPressed: _switchToRenterMode,
                            tooltip: 'Switch to Renter Mode',
                          ),
                          GestureDetector(
                            onTap: _navigateToProfile,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: FirebaseAuth
                                            .instance.currentUser?.photoURL !=
                                        null
                                    ? NetworkImage(FirebaseAuth
                                        .instance.currentUser!.photoURL!)
                                    : null,
                                child: FirebaseAuth
                                            .instance.currentUser?.photoURL ==
                                        null
                                    ? Text(
                                        _getUserFirstName()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main scrollable content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
                    child: RefreshIndicator(
                      onRefresh: _refreshDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header and welcome text
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 24.0, right: 24.0, top: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getUserFirstName(),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, d MMM')
                                            .format(DateTime.now()),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.greenAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Online',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Main white card area
                            Container(
                              margin: const EdgeInsets.only(top: 24.0),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[900]
                                    : Colors.grey[50],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, -3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20.0,
                                  right: 20.0,
                                  top: 30.0,
                                  bottom: 20.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Stats cards
                                    SizedBox(
                                      height: 140,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        children: [
                                          _buildStatCard(
                                            icon: Icons.directions_car,
                                            title: 'Vehicles Listed',
                                            value: _vehicleStats['vehiclesListed'] ?? '0',
                                            color: const Color(0xFF6C63FF),
                                            change: 'Total vehicles',
                                          ),
                                          _buildStatCard(
                                            icon: Icons.access_time,
                                            title: 'Active Rentals',
                                            value: _vehicleStats['activeRentals'] ?? '0',
                                            color: const Color(0xFF4CAF50),
                                            change: 'Currently rented',
                                          ),
                                          _buildStatCard(
                                            icon: Icons.attach_money,
                                            title: 'Total Earnings',
                                            value: _vehicleStats['totalEarnings'] ?? 'LKR 0',
                                            color: const Color(0xFFF9A825),
                                            change: 'All time earnings',
                                          ),
                                          _buildStatCard(
                                            icon: Icons.star,
                                            title: 'Avg Rating',
                                            value: _vehicleStats['avgRating'] ?? 'No ratings',
                                            color: const Color(0xFFE53935),
                                            change: 'From customer reviews',
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Earnings chart section
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.grey[850]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Earnings Overview',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.grey[800]
                                                      : Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'This Month',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            height: 180,
                                            child:
                                                _buildEarningsChart(isDarkMode),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Upcoming bookings section
                                    Text(
                                      'Recent Bookings',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    ..._recentBookings.map((booking) =>
                                        _buildBookingCard(booking, isDarkMode)),

                                    const SizedBox(height: 30),

                                    // Add Vehicle Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _addNewVehicle,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              theme.colorScheme.secondary,
                                          foregroundColor: Colors.white,
                                          elevation: 1,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white24,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.add_circle_outline,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'ADD A NEW VEHICLE',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // My Vehicles section
                                    Text(
                                      'My Vehicles',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Fetch and display vehicles from Firestore
                                    _buildVehiclesList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                onSignOut: _signOut,
                onTabChange: _updateCurrentTab,
                onProfileTap: _navigateToProfile,
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String change,
  }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart(bool isDarkMode) {
    // Sample data
    final spots = [
      const FlSpot(0, 3000),
      const FlSpot(1, 2000),
      const FlSpot(2, 5000),
      const FlSpot(3, 3500),
      const FlSpot(4, 4200),
      const FlSpot(5, 5800),
      const FlSpot(6, 4900),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: 2000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                );
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = 'Mon';
                    break;
                  case 1:
                    text = 'Tue';
                    break;
                  case 2:
                    text = 'Wed';
                    break;
                  case 3:
                    text = 'Thu';
                    break;
                  case 4:
                    text = 'Fri';
                    break;
                  case 5:
                    text = 'Sat';
                    break;
                  case 6:
                    text = 'Sun';
                    break;
                  default:
                    text = '';
                }
                return Text(text, style: style);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2000,
              getTitlesWidget: (value, meta) {
                final style = TextStyle(
                  color: isDarkMode ? Colors.grey : Colors.grey[600]!,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                );
                return Text('${value.toInt()}', style: style);
              },
              reservedSize: 35,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 6000,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDarkMode) {
    Color statusColor;

    switch (booking['status']) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Upcoming':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    String formattedDateRange =
        '${DateFormat('d MMM').format(booking['startDate'])} - ${DateFormat('d MMM').format(booking['endDate'])}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(booking['avatar']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking['vehicleName'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        booking['status'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Rented by ${booking['renterName']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedDateRange,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDarkMode ? Colors.white60 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'LKR ${booking['amount'].toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Vehicle image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              vehicle['images']?['primaryImageUrl'] ?? 'https://via.placeholder.com/400x200?text=No+Image',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.car_rental, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          
          // Vehicle details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${vehicle['make'] ?? 'Unknown'} ${vehicle['model'] ?? 'Model'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(vehicle['status'] as String?).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vehicle['status'] as String? ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(vehicle['status'] as String?),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Year ${vehicle['year'] ?? 'N/A'} · ${vehicle['vehicleNo'] ?? 'No Reg Number'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle['collectionPoint']?['district'] ?? 'Location not set',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    // Show pricing if available
                    if (vehicle['pricing']?['daily']?['baseRate'] != null)
                      Text(
                        'LKR ${vehicle['pricing']['daily']['baseRate'].toString()}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildVehiclesList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final vehicles = snapshot.data?.docs ?? [];

        if (vehicles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No vehicles added yet. Add your first vehicle!'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index].data() as Map<String, dynamic>;
            return _buildVehicleCard(vehicle);
          },
        );
      },
    );
  }
}
