import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/apple_sign_in_button.dart';
import '../welcome_screen.dart';
import '../../utils/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Reduced from 1200
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Changed from easeIn
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
        const AssetImage('assets/images/login_background.jpg'), context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Login with Firebase Auth
        await _authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Navigate to home screen on successful login
        if (!mounted) return;
        // Smooth navigation transitions
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration:
                const Duration(milliseconds: 500), // Reduced from 800
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuad, // Smoother curve
              );
              return FadeTransition(
                opacity: curvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
          ),
        );
      } catch (e) {
        if (!mounted) return;
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient overlay
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.4, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.darken,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Animated wave at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(
                  MediaQuery.of(context).size.width,
                  ResponsiveHelper.getResponsiveSpacingIPad(context,
                      mobile: 80,
                      tablet: 100,
                      ipad: 120,
                      ipadPro: 140,
                      desktop: 160)),
              painter: WavePainter(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: ResponsiveHelper.getResponsiveHorizontalPadding(
                  context,
                  mobile: 16,
                  tablet: 24,
                  ipad: 32,
                  ipadPro: 40,
                  desktop: 48,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacingIPad(
                              context,
                              mobile: 40,
                              tablet: 60,
                              ipad: 80,
                              ipadPro: 100,
                              desktop: 120)),

                      // Logo and name
                      Center(
                        child: Column(
                          children: [
                            Hero(
                              tag: 'appLogo',
                              child: Container(
                                width:
                                    ResponsiveHelper.getResponsiveProfileSize(
                                        context,
                                        mobile: 100,
                                        tablet: 120,
                                        ipad: 140,
                                        ipadPro: 160,
                                        desktop: 180),
                                height:
                                    ResponsiveHelper.getResponsiveProfileSize(
                                        context,
                                        mobile: 100,
                                        tablet: 120,
                                        ipad: 140,
                                        ipadPro: 160,
                                        desktop: 180),
                                padding:
                                    ResponsiveHelper.getResponsivePaddingIPad(
                                        context,
                                        mobile: 5,
                                        tablet: 8,
                                        ipad: 10,
                                        ipadPro: 12,
                                        desktop: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.image,
                                          size: ResponsiveHelper
                                              .getResponsiveIconSize(context,
                                                  mobile: 40,
                                                  tablet: 50,
                                                  ipad: 60,
                                                  ipadPro: 70,
                                                  desktop: 80)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    ResponsiveHelper.getResponsiveSpacingIPad(
                                        context,
                                        mobile: 16,
                                        tablet: 20,
                                        ipad: 24,
                                        ipadPro: 32,
                                        desktop: 40)),
                            Text(
                              'Wayz.lk', // Updated from 'WayZ.lk' to 'Wayz.lk'
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSizeIPad(
                                        context,
                                        mobile: 32,
                                        tablet: 36,
                                        ipad: 40,
                                        ipadPro: 44,
                                        desktop: 48),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(
                                height: ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 8,
                                    tablet: 12,
                                    ipad: 16,
                                    ipadPro: 20,
                                    desktop: 16)),
                            Text(
                              'Where Paradise Meets Adventure',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                        context,
                                        mobile: 16,
                                        tablet: 18,
                                        desktop: 20),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 50, tablet: 70, ipad: 90, ipadPro: 110, desktop: 90)),

                      // Login Form Card
                      Card(
                        elevation: ResponsiveHelper.isTablet(context) ? 12 : 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(
                                  context)),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              mobile: 24,
                              tablet: 32,
                              desktop: 40),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper
                                        .getResponsiveFontSizeIPad(context,
                                            mobile: 24,
                                            tablet: 28,
                                            ipad: 32,
                                            ipadPro: 36,
                                            desktop: 40),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(
                                    height: ResponsiveHelper
                                        .getResponsiveSpacingIPad(context,
                                            mobile: 8,
                                            tablet: 12,
                                            ipad: 16,
                                            ipadPro: 20,
                                            desktop: 24)),
                                Text(
                                  'Sign in to continue your adventure',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper
                                        .getResponsiveFontSizeIPad(context,
                                            mobile: 14,
                                            tablet: 16,
                                            ipad: 18,
                                            ipadPro: 20,
                                            desktop: 22),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(
                                    height: ResponsiveHelper
                                        .getResponsiveSpacingIPad(context,
                                            mobile: 24,
                                            tablet: 32,
                                            ipad: 40,
                                            ipadPro: 48,
                                            desktop: 56)),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'your.email@example.com',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: ResponsiveHelper
                                          .getResponsiveIconSize(context,
                                              mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          ResponsiveHelper
                                              .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 12,
                                                  tablet: 16,
                                                  desktop: 20)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          ResponsiveHelper
                                              .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 12,
                                                  tablet: 16,
                                                  desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          ResponsiveHelper
                                              .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 12,
                                                  tablet: 16,
                                                  desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(
                                    height: ResponsiveHelper
                                        .getResponsiveSpacingIPad(context,
                                            mobile: 20,
                                            tablet: 24,
                                            ipad: 28,
                                            ipadPro: 32,
                                            desktop: 36)),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '********',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: ResponsiveHelper
                                          .getResponsiveIconSize(context,
                                              mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                        size: ResponsiveHelper
                                            .getResponsiveIconSize(context,
                                                mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 36),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          ResponsiveHelper
                                              .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 12,
                                                  tablet: 16,
                                                  desktop: 20)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          ResponsiveHelper
                                              .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 12,
                                                  tablet: 16,
                                                  desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          ResponsiveHelper
                                              .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 12,
                                                  tablet: 16,
                                                  desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 16,
                                            tablet: 20,
                                            desktop: 24)),

                                // Remember me and Forgot password row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: ResponsiveHelper
                                              .getResponsiveIconSize(context,
                                                  mobile: 24,
                                                  tablet: 28,
                                                  desktop: 32),
                                          height: ResponsiveHelper
                                              .getResponsiveIconSize(context,
                                                  mobile: 24,
                                                  tablet: 28,
                                                  desktop: 32),
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value!;
                                              });
                                            },
                                            activeColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            width: ResponsiveHelper
                                                .getResponsiveSpacing(context,
                                                    mobile: 8,
                                                    tablet: 12,
                                                    desktop: 16)),
                                        Text(
                                          'Remember me',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: ResponsiveHelper
                                                .getResponsiveFontSize(context,
                                                    mobile: 14,
                                                    tablet: 16,
                                                    desktop: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        padding: EdgeInsets.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper
                                              .getResponsiveFontSize(context,
                                                  mobile: 14,
                                                  tablet: 16,
                                                  desktop: 18),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 30,
                                            tablet: 40,
                                            desktop: 50)),

                                // Sign In button
                                SizedBox(
                                  width: double.infinity,
                                  height: ResponsiveHelper.isTablet(context)
                                      ? 65
                                      : 55,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            ResponsiveHelper
                                                .getResponsiveBorderRadius(
                                                    context,
                                                    mobile: 12,
                                                    tablet: 16,
                                                    desktop: 20)),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          )
                                        : Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: ResponsiveHelper
                                                  .getResponsiveFontSize(
                                                      context,
                                                      mobile: 18,
                                                      tablet: 20,
                                                      desktop: 22),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 20,
                                            tablet: 24,
                                            desktop: 28)),

                                // Divider with "Or" text
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[400],
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveHelper
                                              .getResponsiveSpacing(context,
                                                  mobile: 16,
                                                  tablet: 20,
                                                  desktop: 24)),
                                      child: Text(
                                        'Or',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: ResponsiveHelper
                                              .getResponsiveFontSize(context,
                                                  mobile: 14,
                                                  tablet: 16,
                                                  desktop: 18),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[400],
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 20,
                                            tablet: 24,
                                            desktop: 28)),

                                // Center the Google sign-in button
                                Center(
                                  child: GoogleSignInButton(
                                    isLogin: true,
                                    onSuccess: () {
                                      Navigator.of(context).pushReplacement(
                                        PageRouteBuilder(
                                          transitionDuration:
                                              const Duration(milliseconds: 800),
                                          pageBuilder: (_, __, ___) =>
                                              const WelcomeScreen(),
                                          transitionsBuilder:
                                              (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(
                                    height:
                                        ResponsiveHelper.getResponsiveSpacing(
                                            context,
                                            mobile: 12,
                                            tablet: 16,
                                            desktop: 20)),

                                // Center the Apple sign-in button
                                Center(
                                  child: AppleSignInButton(
                                    isLogin: true,
                                    onSuccess: () {
                                      Navigator.of(context).pushReplacement(
                                        PageRouteBuilder(
                                          transitionDuration:
                                              const Duration(milliseconds: 800),
                                          pageBuilder: (_, __, ___) =>
                                              const WelcomeScreen(),
                                          transitionsBuilder:
                                              (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 30, tablet: 40, desktop: 50)),

                      // Sign up text
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20),
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context,
                              mobile: 30, tablet: 40, desktop: 50)),
                    ],
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
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 3); // Add subtle blur

    // Create a more detailed wave with Path.cubicTo for smoother curves
    final path = Path();
    path.moveTo(0, 30); // Start higher

    // First wave segment
    path.cubicTo(
      size.width * 0.1,
      10,
      size.width * 0.3,
      30,
      size.width * 0.5,
      20,
    );

    // Second wave segment
    path.cubicTo(
      size.width * 0.7,
      10,
      size.width * 0.9,
      25,
      size.width,
      15,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
