import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive_helper.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _resetEmailSent = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Send password reset email
        await _authService.resetPassword(_emailController.text.trim());

        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _resetEmailSent = true;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: ResponsiveHelper.getResponsiveIconSize(context,
                mobile: 20, tablet: 24, desktop: 28),
          ),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 24, tablet: 32, desktop: 40)),
          child: _resetEmailSent ? _buildSuccessState() : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 20, tablet: 24, desktop: 28)),
        Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                mobile: 28, tablet: 32, desktop: 36),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 12, tablet: 14, desktop: 16)),
        Text(
          'Enter your email and we\'ll send you a link to reset your password.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                mobile: 16, tablet: 17, desktop: 18),
            color: Colors.grey[700],
          ),
        ),
        SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 40, tablet: 48, desktop: 56)),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'your.email@example.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                size: ResponsiveHelper.getResponsiveIconSize(context,
                    mobile: 20, tablet: 24, desktop: 28),
                color: Theme.of(context).colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context,
                        mobile: 12, tablet: 14, desktop: 16)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context,
                        mobile: 12, tablet: 14, desktop: 16)),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context,
                        mobile: 12, tablet: 14, desktop: 16)),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
        SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 30, tablet: 36, desktop: 42)),
        SizedBox(
          width: double.infinity,
          height: ResponsiveHelper.getResponsiveSpacing(context,
              mobile: 55, tablet: 60, desktop: 65),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.6),
              elevation: ResponsiveHelper.isTablet(context) ? 4 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context,
                        mobile: 12, tablet: 14, desktop: 16)),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 24, tablet: 28, desktop: 32),
                    width: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 24, tablet: 28, desktop: 32),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 2,
                          tablet: 3,
                          desktop: 4),
                    ),
                  )
                : Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 18, tablet: 20, desktop: 22),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 100, tablet: 120, desktop: 140),
            height: ResponsiveHelper.getResponsiveSpacing(context,
                mobile: 100, tablet: 120, desktop: 140),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              size: ResponsiveHelper.getResponsiveIconSize(context,
                  mobile: 50, tablet: 56, desktop: 62),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 24, tablet: 28, desktop: 32)),
          Text(
            'Check Your Email',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                  mobile: 24, tablet: 26, desktop: 28),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 16, tablet: 18, desktop: 20)),
          Text(
            'We\'ve sent a password reset link to:\n${_emailController.text}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                  mobile: 16, tablet: 17, desktop: 18),
              color: Colors.grey[700],
            ),
          ),
          SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 16, tablet: 18, desktop: 20)),
          Text(
            'Check your spam folder if you don\'t see the email.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                  mobile: 14, tablet: 15, desktop: 16),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context,
                  mobile: 40, tablet: 48, desktop: 56)),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 24, tablet: 28, desktop: 32),
                vertical: ResponsiveHelper.getResponsiveSpacing(context,
                    mobile: 14, tablet: 16, desktop: 18),
              ),
              textStyle: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                    mobile: 16, tablet: 17, desktop: 18),
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text('Return to Login'),
          ),
        ],
      ),
    );
  }
}
