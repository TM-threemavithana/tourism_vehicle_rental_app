import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/onesignal_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/favorites_screen.dart';
import 'screens/vehicle_detail_page.dart'; // Add this import
import 'screens/notifications_screen.dart'; // Import the new screen
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove direct SystemChrome.setSystemUIOverlayStyle call

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize OneSignal
    await OneSignalService().initialize();
    print("OneSignal initialized successfully");

    runApp(const MyApp());
  } catch (e) {
    print('Error during initialization: $e');
    // Run app even if services fail to initialize
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Remove or comment out the dynamic links initialization
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wayz.lk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF033754),
          primary: const Color(0xFF033754), // #033754
          background: const Color(0xFFFFFFFF), // #ffffff
          secondary: const Color(0xFF10B6D7), // #10b6d7
          tertiary: const Color(0xFF89D900), // #89d900
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/favorites': (context) => const FavoritesScreen(),
        '/vehicle-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return VehicleDetailPage(vehicle: args ?? {});
        },
        '/notifications': (context) =>
            const NotificationsScreen(), // Add the new route
      },
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFFFFC107), // Yellow
            statusBarIconBrightness: Brightness.dark,
          ),
          child: child!,
        );
      },
    );
  }
}
