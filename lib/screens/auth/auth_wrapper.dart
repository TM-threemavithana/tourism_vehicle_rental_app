import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../welcome_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import '../../services/auth_service.dart';
import 'user_type_selection_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isFirstTime = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          if (user == null) {
            return const LoginScreen();
          } else {
            // Check if user is newly created (first time)
            if (user.metadata.creationTime != null &&
                user.metadata.lastSignInTime != null &&
                user.metadata.creationTime!
                    .isAtSameMomentAs(user.metadata.lastSignInTime!)) {
              _isFirstTime = true;
            }

            // For first-time users, show the user type selection screen
            if (_isFirstTime) {
              return const UserTypeSelectionScreen();
            }

            // For existing users, check their type and redirect accordingly
            return FutureBuilder<String>(
              future: _authService.getUserType(),
              builder: (context, userTypeSnapshot) {
                if (userTypeSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final userType = userTypeSnapshot.data ?? 'renter';

                if (userType == 'owner') {
                  return const OwnerDashboardScreen();
                } else {
                  return const WelcomeScreen();
                }
              },
            );
          }
        }

        // While waiting for the state to be determined, show a loading indicator
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
