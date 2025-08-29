import 'dart:async';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../utils/responsive_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Precache the logo image
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/logo.png'), context);
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.1,
            colors: [
              Color(0xFF033754), // dark blue
              Color(0xFF11518C), // lighter blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing effect behind logo
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: ResponsiveHelper.getResponsiveProfileSize(context, mobile: 180, tablet: 220, desktop: 260),
                        height: ResponsiveHelper.getResponsiveProfileSize(context, mobile: 180, tablet: 220, desktop: 260),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withOpacity(
                                  0.25 + 0.15 * _scaleAnimation.value),
                              blurRadius: 48 * _scaleAnimation.value,
                              spreadRadius: 8 * _scaleAnimation.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    width: ResponsiveHelper.getResponsiveProfileSize(context, mobile: 120, tablet: 150, desktop: 180),
                    height: ResponsiveHelper.getResponsiveProfileSize(context, mobile: 120, tablet: 150, desktop: 180),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 60, tablet: 80, desktop: 100),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 40, tablet: 60, desktop: 80)),
              // App name with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Wayz.lk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 36, tablet: 42, desktop: 48),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              // Tagline with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Where Paradise Meets Adventure',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
