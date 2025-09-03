import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/auth_service.dart';
import 'dart:io' show Platform;

class AppleSignInButton extends StatefulWidget {
  final Function? onSuccess;
  final bool isLogin;

  const AppleSignInButton({
    super.key,
    this.onSuccess,
    this.isLogin = true,
  });

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Apple
      await _authService.signInWithApple();

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
    // Only show Apple Sign In button on iOS/macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: SignInWithApple.isAvailable(),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return ElevatedButton(
          onPressed: _isLoading ? null : _signInWithApple,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Apple logo
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      child: const Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // The button text changes based on whether it's used for login or signup
                    Text(
                      widget.isLogin
                          ? 'Sign in with Apple'
                          : 'Sign up with Apple',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
