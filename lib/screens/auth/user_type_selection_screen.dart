import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/auth_wrapper.dart';
import '../../widgets/side_menu.dart';
import '../profile_screen.dart';
import '../owner/owner_dashboard_screen.dart' show OwnerDashboardScreen;

class RenterDashboardScreen extends StatefulWidget {
  const RenterDashboardScreen({super.key});

  @override
  State<RenterDashboardScreen> createState() => _RenterDashboardScreenState();
}

class _RenterDashboardScreenState extends State<RenterDashboardScreen> {
  final AuthService _authService = AuthService();
  bool _isMenuOpen = false;
  String _currentTab = 'Dashboard';
  bool _isLoading = false;

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
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
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

  Future<void> _switchToOwnerMode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserType('owner');

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/owner-dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching modes: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renter Dashboard'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleMenu,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _switchToOwnerMode,
            tooltip: 'Switch to Owner Mode',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Renter'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary cards
                  Row(
                    children: [
                      _buildStatCard(
                          'Vehicles Available', '0', Icons.directions_car),
                      const SizedBox(width: 16),
                      _buildStatCard(
                          'Active Rentals', '0', Icons.event_available),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildStatCard('Total Spent', '\$0', Icons.attach_money),
                      const SizedBox(width: 16),
                      _buildStatCard('Reviews', '0', Icons.star),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Coming soon: Rent Vehicle feature')),
                      );
                    },
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Rent a Vehicle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
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
                onSignOut: _signOut,
                onTabChange: _updateCurrentTab,
                onProfileTap: _navigateToProfile,
                width: 0.7,
                user: FirebaseAuth.instance.currentUser,
                currentTab: _currentTab,
              ),
            ),
          ],

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _selectUserType(String userType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserType(userType);

      if (!mounted) return;

      // Navigate to appropriate screen based on user type
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => userType == 'owner'
              ? const OwnerDashboardScreen()
              : const RenterDashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting user type: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Wave pattern at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(size.width, 100),
                    painter: WavePainter(
                      color: theme.colorScheme.tertiary.withOpacity(0.3),
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // Title
                        const Text(
                          'How will you use WayZ?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          'Choose your primary role. You can change this later.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Renter option
                        _buildRoleCard(
                          title: 'Rent Vehicles',
                          description:
                              'Browse and rent vehicles from local owners',
                          iconData: Icons.directions_car,
                          color: theme.colorScheme.secondary,
                          onTap: () => _selectUserType('renter'),
                        ),

                        const SizedBox(height: 24),

                        // Owner option
                        _buildRoleCard(
                          title: 'List My Vehicles',
                          description:
                              'Earn money by renting out your vehicles',
                          iconData: Icons.monetization_on,
                          color: theme.colorScheme.tertiary,
                          onTap: () => _selectUserType('owner'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: color,
                size: 32,
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Wave painter for bottom decoration
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 20);
    path.quadraticBezierTo(size.width * 0.75, 40, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
