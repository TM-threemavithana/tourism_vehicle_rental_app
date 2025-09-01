import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/onesignal_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/favorites_screen.dart';
import 'screens/vehicle_detail_page.dart';
import 'screens/notifications_screen.dart';
import 'package:flutter/services.dart';
import 'utils/responsive_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI for iPad full screen support
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set preferred orientations for iPad support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    // Initialize Firebase first with detailed error logging
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // Test Firestore connection
    try {
      await FirebaseFirestore.instance.collection('test').doc('test').get();
      print("Firestore connection verified");
    } catch (firestoreError) {
      print('Firestore connection error: $firestoreError');
    }

    // Initialize OneSignal
    await OneSignalService().initialize();
    print("OneSignal initialized successfully");

    runApp(const MyApp());
  } catch (e) {
    print('Error during Firebase initialization: $e');
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
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black,
          secondary: const Color(0xFFFFC107),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
        // iPad-specific responsive adjustments
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Ensure proper text scaling for iPad
            textScaler: TextScaler.linear(
              ResponsiveHelper.isIPadPro12_9(context)
                  ? 1.1
                  : ResponsiveHelper.isIPadPro11(context)
                      ? 1.05
                      : ResponsiveHelper.isIPad(context)
                          ? 1.0
                          : 1.0,
            ),
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: ResponsiveHelper.isIPad(context)
                  ? Brightness.dark
                  : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
