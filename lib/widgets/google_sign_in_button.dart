import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final Function? onSuccess;
  final bool isLogin;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.isLogin = true,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  // Google logo URL instead of asset
  final String googleLogoUrl =
      'https://developers.google.com/identity/images/g-logo.png';

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Google
      await _authService.signInWithGoogle();

      // Call the success callback if provided
      if (widget.onSuccess != null && mounted) {
        widget.onSuccess!();
      }
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signInWithGoogle,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use network image for Google logo
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  child: Image.network(
                    googleLogoUrl,
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.add_circle,
                        color: Colors.red,
                        size: 24,
                      );
                    },
                  ),
                ),
                // The button text changes based on whether it's used for login or signup
                Text(
                  widget.isLogin
                      ? 'Sign in with Google'
                      : 'Sign up with Google',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
