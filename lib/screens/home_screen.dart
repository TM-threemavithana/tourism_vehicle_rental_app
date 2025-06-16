import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import 'auth/auth_wrapper.dart';
import '../widgets/side_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _vehicleTypes = ['Bike', 'Three-wheel', 'Car'];
  final AuthService _authService = AuthService();
  final Set<String> _selectedVehicles = <String>{};
  final TextEditingController _locationController = TextEditingController();
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = const TimeOfDay(hour: 5, minute: 0);
  DateTime _returnDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _returnTime = const TimeOfDay(hour: 5, minute: 0);
  bool _flexibleDates = false;
  bool _showNearbyVehicles = true;
  bool _isMenuOpen = false;
  String _currentTab = 'Search'; // Changed from 'Home' to 'Search'

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    _locationController.text = 'Location';
  }

  @override
  void dispose() {
    _controller.dispose();
    _locationController.dispose();
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup ? _pickupDate : _returnDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isPickup ? _pickupTime : _returnTime,
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _returnTime = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _toggleVehicleSelection(String type) {
    setState(() {
      if (_selectedVehicles.contains(type)) {
        _selectedVehicles.remove(type);
      } else {
        _selectedVehicles.add(type);
      }
    });
  }

  void _updateCurrentTab(String tabName) {
    setState(() {
      _currentTab = tabName;
    });
    _closeMenu(); // Close the menu after selecting a tab
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to help with responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _isMenuOpen ? Icons.menu : Icons.menu,
            color: _isMenuOpen
                ? Colors.black
                : Colors.white, // Black when menu is open
            size: 24,
          ),
          onPressed: _toggleMenu,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image with increased brightness
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/road_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section with logo and title - reduced spacing
                  Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02), // Reduced space
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: screenHeight * 0.06,
                          width: screenHeight * 0.06,
                          fit: BoxFit.contain,
                          // Add loading builder if needed
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return Container(
                              height: screenHeight * 0.06,
                              width: screenHeight * 0.06,
                              padding: const EdgeInsets.all(8.0),
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2.0),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01), // Reduced space
                      const Text(
                        'Your next adventure starts here',
                        style: TextStyle(
                          fontSize: 18, // Smaller font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Vehicle selection section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle type selection header
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          'Select one or more vehicles:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Vehicle type selection grid - more compact
                      SizedBox(
                        height: screenHeight * 0.12, // Fixed height
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _vehicleTypes.map((type) {
                            final isSelected = _selectedVehicles.contains(type);
                            return GestureDetector(
                              onTap: () => _toggleVehicleSelection(type),
                              child: Container(
                                width:
                                    screenWidth * 0.28, // Width based on screen
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFA500)
                                      : Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white38,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getVehicleIcon(type),
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      size: 20, // Smaller icon
                                    ),
                                    const SizedBox(height: 4), // Less space
                                    Text(
                                      type,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12, // Smaller text
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  // Location field
                  SizedBox(
                    height: screenHeight * 0.06, // Fixed height
                    child: _buildInputField(
                      controller: _locationController,
                      hintText: 'Location',
                    ),
                  ),

                  // Date and time section - more compact
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pick up section
                      Row(
                        children: [
                          const Text(
                            'Pick up: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context, true),
                                    child: _buildDateTimeField(
                                        _formatDate(_pickupDate)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectTime(context, true),
                                    child: _buildDateTimeField(
                                        _formatTime(_pickupTime)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.01), // Minimal space

                      // Return section
                      Row(
                        children: [
                          const Text(
                            'Return:  ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context, false),
                                    child: _buildDateTimeField(
                                        _formatDate(_returnDate)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectTime(context, false),
                                    child: _buildDateTimeField(
                                        _formatTime(_returnTime)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Options section
                  Row(
                    children: [
                      // Flexible dates option
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _flexibleDates = !_flexibleDates;
                                });
                              },
                              child: Container(
                                width: 18, // Smaller checkbox
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _flexibleDates
                                      ? const Color(0xFFFFA500)
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _flexibleDates
                                    ? const Icon(Icons.check,
                                        color: Colors.black, size: 12)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Flexible',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // Nearby vehicles option
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showNearbyVehicles = !_showNearbyVehicles;
                                });
                              },
                              child: Container(
                                width: 18, // Smaller checkbox
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _showNearbyVehicles
                                      ? const Color(0xFFA0522D)
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _showNearbyVehicles
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 12)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Show Nearby',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Search button
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.065,
                    child: ElevatedButton(
                      onPressed: _selectedVehicles.isNotEmpty
                          ? () {
                              // Handle search with selected vehicles
                              print('Selected vehicles: $_selectedVehicles');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'SEARCH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // Bottom padding
                ],
              ),
            ),
          ),

          // Side Menu and Overlay
          if (_isMenuOpen) ...[
            // Semi-transparent overlay that covers the remaining screen
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

            // Side Menu on the left
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.translationValues(
                  _isMenuOpen ? 0 : -MediaQuery.of(context).size.width * 0.7,
                  0,
                  0,
                ),
                child: SideMenu(
                  onClose: _closeMenu,
                  onSignOut: _signOut,
                  onTabChange: _updateCurrentTab, // Pass the callback
                  width: 0.7,
                  user: FirebaseAuth.instance.currentUser,
                  currentTab: _currentTab,
                ),
              ),
            ),

            // Menu icon overlay to show black icon when menu is open
            Positioned(
              top: MediaQuery.of(context).padding.top, // Account for status bar
              left: 4, // Align with the original menu icon
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.black,
                  size: 24,
                ),
                onPressed: _toggleMenu,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String text) {
    return Container(
      height: 40, // Reduced height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14, // Smaller font
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'Bike':
        return Icons.directions_bike;
      case 'Three-wheel':
        return Icons.directions_railway_filled_outlined;
      case 'Car':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }
}
