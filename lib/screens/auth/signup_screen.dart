import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../welcome_screen.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/google_sign_in_button.dart'; // Add this import if it's not already there
import '../../utils/responsive_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
        const AssetImage('assets/images/signup_background.jpg'), context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Register with Firebase Auth
        await _authService.registerWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        // Navigate to home screen after successful registration
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
          (route) => false,
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
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please agree to the Terms of Service and Privacy Policy'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                  image: AssetImage('assets/images/signup_background.jpg'),
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
              size: Size(MediaQuery.of(context).size.width, ResponsiveHelper.getResponsiveSpacingIPad(context, mobile: 80, tablet: 100, ipad: 120, ipadPro: 140, desktop: 160)),
              painter: WavePainter(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
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
                      // Back button
                      Padding(
                        padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveSpacingIPad(context, mobile: 16, tablet: 20, ipad: 24, ipadPro: 32, desktop: 40)),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: ResponsiveHelper.getResponsiveIconSize(context,
                                mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacingIPad(context, mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 36)),

                      // Title text
                      Padding(
                        padding: EdgeInsets.only(left: ResponsiveHelper.getResponsiveSpacingIPad(context, mobile: 16, tablet: 20, ipad: 24, ipadPro: 32, desktop: 40)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context, mobile: 32, tablet: 36, ipad: 40, ipadPro: 44, desktop: 48),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacingIPad(context, mobile: 8, tablet: 12, ipad: 16, ipadPro: 20, desktop: 24)),
                            Text(
                              'Join Wayz.lk for amazing adventures',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: ResponsiveHelper.getResponsiveFontSizeIPad(context, mobile: 16, tablet: 18, ipad: 20, ipadPro: 22, desktop: 24),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.getResponsiveSpacingIPad(context, mobile: 30, tablet: 40, ipad: 50, ipadPro: 60, desktop: 70)),

                      // Signup Form Card
                      Card(
                        elevation: ResponsiveHelper.isTablet(context) ? 12 : 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: ResponsiveHelper.getResponsivePaddingIPad(context, mobile: 24, tablet: 32, ipad: 40, ipadPro: 48, desktop: 56),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full name field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'John Doe',
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: ResponsiveHelper.getResponsiveIconSize(context,
                                          mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
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
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'your.email@example.com',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: ResponsiveHelper.getResponsiveIconSize(context,
                                          mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
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
                                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),

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
                                      size: ResponsiveHelper.getResponsiveIconSize(context,
                                          mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                        size: ResponsiveHelper.getResponsiveIconSize(context,
                                            mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 36),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
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
                                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),

                                // Confirm password field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    hintText: '********',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: ResponsiveHelper.getResponsiveIconSize(context,
                                          mobile: 24, tablet: 28, ipad: 32, ipadPro: 36, desktop: 40),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                        size: ResponsiveHelper.getResponsiveIconSize(context,
                                            mobile: 20, tablet: 24, ipad: 28, ipadPro: 32, desktop: 36),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
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
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),

                                // Terms and conditions
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                                      height: ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                                      child: Checkbox(
                                        value: _agreeToTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _agreeToTerms = value!;
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
                                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'I agree to the ',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Terms of Service',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  // Navigate to Terms of Service
                                                },
                                            ),
                                            TextSpan(
                                              text: ' and ',
                                            ),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  // Navigate to Privacy Policy
                                                },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 30, tablet: 40, desktop: 50)),

                                // Sign Up button
                                SizedBox(
                                  width: double.infinity,
                                  height: ResponsiveHelper.isTablet(context) ? 65 : 55,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, mobile: 12, tablet: 16, desktop: 20)),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          )
                                        : Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 30, tablet: 40, desktop: 50)),

                      // Add the divider and Google sign-in button
                      Card(
                        elevation: ResponsiveHelper.isTablet(context) ? 12 : 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28), 
                              horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
                          child: Column(
                            children: [
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
                                        horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                                    child: Text(
                                      'Or sign up with',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
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

                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),

                              // Google sign-in button
                              Center(
                                child: GoogleSignInButton(
                                  isLogin: false,
                                  onSuccess: () {
                                    Navigator.of(context).pushAndRemoveUntil(
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
                                      (route) => false,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 30, tablet: 40, desktop: 50)),

                      // Already have an account text
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 30, tablet: 40, desktop: 50)),
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
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 20);

    // Create a smooth wave pattern
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      40,
      size.width,
      20,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
