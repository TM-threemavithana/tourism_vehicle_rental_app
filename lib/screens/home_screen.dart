import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _vehicleTypes = [
    'Motorcycles',
    'Cars',
    'Vans',
    'Tuk-tuks'
  ];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // Navigation will be handled by the AuthWrapper
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'WayZ',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    animation: _controller,
                    color1: const Color(0xFF1B7BC8),
                    color2: const Color(0xFF2CDCAD),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Welcome card
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.waves,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Welcome to WayZ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Discover the coastal beauty of Sri Lanka at your own pace. Rent the perfect vehicle for your adventure today!',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(
                      'Choose Your Ride',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Vehicle category cards
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _vehicleTypes.length,
                      itemBuilder: (context, index) {
                        return _buildVehicleCard(_vehicleTypes[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildVehicleCard(String vehicleType) {
    IconData iconData;
    switch (vehicleType) {
      case 'Motorcycles':
        iconData = Icons.motorcycle;
        break;
      case 'Cars':
        iconData = Icons.directions_car;
        break;
      case 'Vans':
        iconData = Icons.airport_shuttle;
        break;
      case 'Tuk-tuks':
        iconData = Icons.electric_rickshaw;
        break;
      default:
        iconData = Icons.directions_car;
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconData,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                vehicleType,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Background painter for animated gradient
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color1;
  final Color color2;

  BackgroundPainter({
    required this.animation,
    required this.color1,
    required this.color2,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create gradient with moving pattern
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color1.withOpacity(0.8),
        color2.withOpacity(0.6),
        color1.withOpacity(0.4),
      ],
      stops: [
        0.0,
        animation.value % 1.0,
        1.0,
      ],
      transform: GradientRotation(animation.value * 2 * math.pi),
    );

    paint.shader = gradient.createShader(rect);

    // Draw water-inspired pattern
    for (int i = 0; i < 5; i++) {
      double offset = i * 60;
      Path path = Path();
      path.moveTo(0, size.height - offset);

      for (double x = 0; x < size.width; x += 40) {
        double normalizedX = x / size.width;
        double phase = animation.value * 2 * math.pi + (i * math.pi / 3);
        double y = size.height -
            offset +
            math.sin(normalizedX * 4 * math.pi + phase) * 15;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.05 + (i * 0.02))
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value ||
      oldDelegate.color1 != color1 ||
      oldDelegate.color2 != color2;
}
