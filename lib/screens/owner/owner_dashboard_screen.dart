import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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

  // Sample data - in a real app, fetch from a data service
  final List<Map<String, dynamic>> _recentBookings = [
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
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

  void _addNewVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
    );
  }

  String _getUserFirstName() {
    final fullName = FirebaseAuth.instance.currentUser?.displayName ?? 'Owner';
    return fullName.split(' ').first;
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
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
                                          value: '3',
                                          color: const Color(0xFF6C63FF),
                                          change: '+1 this week',
                                        ),
                                        _buildStatCard(
                                          icon: Icons.access_time,
                                          title: 'Active Rentals',
                                          value: '2',
                                          color: const Color(0xFF4CAF50),
                                          change: '+1 from last week',
                                        ),
                                        _buildStatCard(
                                          icon: Icons.attach_money,
                                          title: 'Total Earnings',
                                          value: 'LKR 15,400',
                                          color: const Color(0xFFF9A825),
                                          change: '+2,300 this week',
                                        ),
                                        _buildStatCard(
                                          icon: Icons.star,
                                          title: 'Avg Rating',
                                          value: '4.8/5',
                                          color: const Color(0xFFE53935),
                                          change: 'From 12 reviews',
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
                                ],
                              ),
                            ),
                          ),
                        ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
          const SizedBox(height: 8),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white60 : Colors.grey,
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
}
