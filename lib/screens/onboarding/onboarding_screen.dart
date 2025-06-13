import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:math' as math;
import 'slide_one.dart';
import 'slide_two.dart';
import 'slide_three.dart';
import '../auth/login_screen.dart';
import '../auth/auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController controller = PageController();
  bool isLastPage = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // For the explosion animation
  bool _isExploding = false;
  final double _explosionRadius = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startExplodingAnimation() {
    setState(() {
      _isExploding = true;
    });

    // Reduce the animation duration to make it faster
    Future.delayed(const Duration(milliseconds: 600), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            // Use a combined curve for smoother effect
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuint,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0)
                    .animate(curvedAnimation),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPatternPainter(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ),
                );
              },
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_animation),
              child: Container(
                padding: const EdgeInsets.only(bottom: 80),
                child: PageView(
                  controller: controller,
                  onPageChanged: (index) {
                    setState(() => isLastPage = index == 2);
                  },
                  // Add physics for smoother scrolling
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    SlideOne(),
                    SlideTwo(),
                    SlideThree(),
                  ],
                ),
              ),
            ),
          ),

          // Gradient overlay at bottom for smooth transition to bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Explosion animation overlay
          if (_isExploding)
            TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: 0,
                  end: math.max(screenSize.width, screenSize.height) * 1.5),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutExpo,
              builder: (context, value, child) {
                return Container(
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: ExplosionPainter(
                      center:
                          Offset(screenSize.width / 2, screenSize.height - 40),
                      radius: value,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    size: Size(screenSize.width, screenSize.height),
                  ),
                );
              },
            ),
        ],
      ),
      bottomSheet: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 80,
        decoration: BoxDecoration(
          color: isLastPage
              ? Theme.of(context).colorScheme.secondary
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: isLastPage
            ? InkWell(
                onTap: _isExploding ? null : _startExplodingAnimation,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withOpacity(_isExploding ? 0.5 : 0.2),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => controller.jumpToPage(2),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.skip_next,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          const Text('SKIP'),
                        ],
                      ),
                    ),

                    // Enhanced page indicator
                    SmoothPageIndicator(
                      controller: controller,
                      count: 3,
                      effect: WormEffect(
                        dotHeight: 10,
                        dotWidth: 10,
                        spacing: 16,
                        radius: 10,
                        strokeWidth: 1.5,
                        dotColor: Colors.grey[300]!,
                        activeDotColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    // Next button
                    TextButton(
                      onPressed: () => controller.nextPage(
                        duration: const Duration(
                            milliseconds: 400), // Reduced from 500
                        curve: Curves
                            .easeOutCubic, // Changed from easeInOut for smoother feel
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('NEXT'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Background pattern painter for subtle visual interest
class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    final dotSize = 3.0;
    final spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Create a slight wave pattern
        final offset = 5 * math.sin(x / 50) * math.cos(y / 50);
        canvas.drawCircle(
          Offset(x + offset, y),
          dotSize / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// New explosion painter for the button animation
class ExplosionPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  ExplosionPainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, radius, paint);

    // Add some smaller circles for a more dynamic effect
    if (radius > size.width * 0.1) {
      for (int i = 0; i < 8; i++) {
        final angle = i * (math.pi * 2 / 8);
        final smallRadius = radius * 0.08;
        final distance = radius * 0.7;

        final offsetX = center.dx + math.cos(angle) * distance;
        final offsetY = center.dy + math.sin(angle) * distance;

        canvas.drawCircle(
          Offset(offsetX, offsetY),
          smallRadius,
          Paint()
            ..color = color.withOpacity(0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ExplosionPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
