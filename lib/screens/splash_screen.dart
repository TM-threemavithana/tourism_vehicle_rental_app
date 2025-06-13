import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:async';
import 'dart:math' as math;
import 'onboarding/onboarding_screen.dart';
import 'auth/auth_wrapper.dart'; // Import AuthWrapper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _logoController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations in sequence
    _logoController.forward();

    // Start fade animation after logo animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      _fadeController.forward();
    });

    // Navigate to onboarding screen or auth wrapper based on whether user has seen onboarding
    Timer(const Duration(seconds: 5), () {
      // Check if user has seen onboarding before
      final bool hasSeenOnboarding =
          false; // Replace with actual logic (using SharedPreferences)

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1200),
          pageBuilder: (_, __, ___) => hasSeenOnboarding
              ? const AuthWrapper()
              : const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _logoController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with overlay gradient
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.5, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.darken,
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Animated waves at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    // Multiple wave layers with different opacities
                    CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 70),
                      painter: WavePainter(
                        amplitude: _waveAnimation.value,
                        color: Colors.white.withOpacity(0.15),
                        frequency: 0.02,
                        phase: 0,
                      ),
                    ),
                    CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 50),
                      painter: WavePainter(
                        amplitude: _waveAnimation.value * 0.8,
                        color: Colors.white.withOpacity(0.25),
                        frequency: 0.025,
                        phase: math.pi / 2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Logo and content container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Animated logo
                SlideTransition(
                  position: _logoSlideAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Container(
                      width: 160, // Slightly increased for better proportion
                      height: 160, // Matching width for perfect circle
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        // Center widget ensures perfect centering
                        child: ClipOval(
                          // ClipOval ensures the image stays within circular bounds
                          child: Image.asset(
                            'assets/images/logo.png',
                            width:
                                120, // Slightly smaller than container for padding effect
                            height: 120,
                            fit: BoxFit.contain, // Maintains aspect ratio
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Bottom text container with glass effect
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // App name
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'WayZ.lk',
                                speed: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              ),
                            ],
                            totalRepeatCount: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tagline with shimmer effect
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                Colors.white70,
                                Colors.white,
                                Colors.white70
                              ],
                              stops: [0.0, 0.5, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              tileMode: TileMode.clamp,
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'Where Paradise Meets Adventure',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),

                      // Loading indicator
                      const SizedBox(height: 30),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: 60,
                          child: LinearProgressIndicator(
                            color: Theme.of(context).colorScheme.secondary,
                            backgroundColor: Colors.white24,
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Status line at bottom
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Center(
                child: Text(
                  '© 2025 WayZ.lk | Sri Lanka',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Wave painter for animated wave effect
class WavePainter extends CustomPainter {
  final double amplitude;
  final Color color;
  final double frequency;
  final double phase;

  WavePainter({
    required this.amplitude,
    required this.color,
    required this.frequency,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      double y =
          size.height / 2 + amplitude * math.sin((x * frequency) + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.color != color ||
        oldDelegate.frequency != frequency ||
        oldDelegate.phase != phase;
  }
}
