import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/onesignal_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/favorites_screen.dart';
import 'screens/vehicle_detail_page.dart';
import 'screens/notifications_screen.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'controllers/vehicle_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/theme_controller.dart';
import 'screens/welcome_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize OneSignal
    await OneSignalService().initialize();
    print("OneSignal initialized successfully");

    // Initialize GetX controllers
    Get.put(AuthController());
    Get.put(VehicleController());
    Get.put(NavigationController());
    Get.put(FavoritesController());
    Get.put(ThemeController());

    runApp(const MyApp());
  } catch (e) {
    print('Error during initialization: $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeController themeController;

  @override
  void initState() {
    super.initState();
    themeController = Get.find<ThemeController>();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        return GetMaterialApp(
          title: 'Wayz.lk',
          debugShowCheckedModeBanner: false,
          theme: controller.lightTheme,
          darkTheme: controller.darkTheme,
          themeMode: controller.themeMode,
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const SplashScreen()),
            GetPage(name: '/welcome', page: () => const WelcomeScreen()),
            GetPage(name: '/auth', page: () => const AuthWrapper()),
            GetPage(name: '/favorites', page: () => const FavoritesScreen()),
            GetPage(
                name: '/vehicle-detail',
                page: () {
                  final args = Get.arguments as Map<String, dynamic>?;
                  return VehicleDetailPage(vehicle: args ?? {});
                }),
            GetPage(
                name: '/notifications',
                page: () => const NotificationsScreen()),
            
          ],
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Color(0xFFFFC107),
                statusBarIconBrightness: Brightness.dark,
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
