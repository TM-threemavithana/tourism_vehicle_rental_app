import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/user_type_selection_screen.dart'
    show UserTypeSelectionScreen;
import 'screens/owner/owner_dashboard_screen.dart' show OwnerDashboardScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Replace or update the _precacheImages function
Future<void> _precacheImages(BuildContext context) async {
  final assets = [
    'assets/images/logo.png',
    'assets/images/image1.jpg',
    'assets/images/image2.jpg',
    'assets/images/image3.jpg',
    'assets/images/splash_background.png',
    'assets/images/road_background.jpg',
    // Add other frequently used images
  ];

  for (final asset in assets) {
    try {
      await precacheImage(AssetImage(asset), context);
      print('Precached: $asset');
    } catch (e) {
      print('Failed to precache $asset: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Precache images when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages(context);
    });

    return MaterialApp(
      title: 'WayZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7BC8),
          primary: const Color(0xFF1B7BC8),
          secondary: const Color(0xFFFFAA33),
          tertiary: const Color(0xFF2CDCAD),
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/user-type': (context) => const UserTypeSelectionScreen(),
        '/owner-dashboard': (context) => const OwnerDashboardScreen(),
      },
    );
  }
}
