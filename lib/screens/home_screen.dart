import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/auth_wrapper.dart';
import '../widgets/side_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart'; // Import the ProfileScreen
import '../services/image_preloader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _vehicleTypes = ['Bike','Three-Wheeler' ,'Car']; // Updated to match image
  final AuthService _authService = AuthService();
  final Set<String> _selectedVehicles = <String>{};
  final TextEditingController _locationController = TextEditingController();
  DateTime _pickupDate = DateTime(2025, 6, 14); // Match image date
  TimeOfDay _pickupTime = const TimeOfDay(hour: 17, minute: 0); // 05:00 pm
  DateTime _returnDate = DateTime(2025, 6, 21); // Match image date
  TimeOfDay _returnTime = const TimeOfDay(hour: 17, minute: 0); // 05:00 pm
  bool _flexibleDates = false;
  bool _showNearbyVehicles = true;
  bool _isMenuOpen = false;
  String _currentTab = 'Search';

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
    return '$hour:$minute ${time.period == DayPeriod.pm ? 'pm' : 'am'}'; // Adjusted for am/pm
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
    _closeMenu();
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProfileScreen(user: FirebaseAuth.instance.currentUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _isMenuOpen ? Icons.close : Icons.menu,
            color: _isMenuOpen ? Colors.black : Colors.white,
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
          // Background image and gradient
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/road_background.jpg'),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section with logo and title
                  Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: screenHeight * 0.06,
                          width: screenHeight * 0.06,
                          fit: BoxFit.contain,
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
                      SizedBox(height: screenHeight * 0.01),
                      const Text(
                        'Your next adventure starts here',
                        style: TextStyle(
                          fontSize: 18,
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
                      SizedBox(
                        height: screenHeight * 0.12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _vehicleTypes.map((type) {
                            final isSelected = _selectedVehicles.contains(type);
                            return GestureDetector(
                              onTap: () => _toggleVehicleSelection(type),
                              child: Container(
                                width: screenWidth * 0.22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFA500)
                                      : Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color:
                                        isSelected ? Colors.white : Colors.white38,
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
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                    height: screenHeight * 0.06,
                    child: _buildInputField(
                      controller: _locationController,
                      hintText: 'Location',
                    ),
                  ),
                  // Date and time section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      SizedBox(height: screenHeight * 0.01),
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
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _flexibleDates
                                      ? const Color(0xFFFFA500)
                                      : Colors.transparent,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _flexibleDates
                                    ? const Icon(Icons.check, color: Colors.black, size: 12)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'My dates are flexible',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
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
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _showNearbyVehicles
                                      ? const Color(0xFFA0522D)
                                      : Colors.transparent,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _showNearbyVehicles
                                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Show Nearby Vehicles',
                              style: TextStyle(color: Colors.white, fontSize: 13),
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
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
          // Side menu and overlay
          if (_isMenuOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
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
                  onTabChange: _updateCurrentTab,
                  onProfileTap: _navigateToProfile,
                  width: 0.7,
                  user: FirebaseAuth.instance.currentUser,
                  currentTab: _currentTab,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 4,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String text) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'Bike':
        return Icons.directions_bike;
      case 'Three-Wheeler':
        return Icons.directions_car_filled;
      case 'Car':
        return Icons.directions_car;
      
      default:
        return Icons.directions_car;
    }
  }
}