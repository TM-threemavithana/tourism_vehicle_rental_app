# GetX Implementation Guide

This document explains how GetX has been implemented in the Tourism Vehicle Rental App for state management, navigation, and dependency injection.

## Overview

GetX has been integrated throughout the application to provide:
- **State Management**: Reactive state management with observable variables
- **Navigation**: Simplified navigation with named routes
- **Dependency Injection**: Automatic dependency injection and lifecycle management
- **Theme Management**: Dynamic theme switching with persistence

## Controllers

### 1. AuthController (`lib/controllers/auth_controller.dart`)

Manages authentication state and user information.

**Key Features:**
- User authentication state
- Login/logout functionality
- Google Sign-In integration
- User profile management
- Reactive user state updates

**Usage:**
```dart
final authController = Get.find<AuthController>();

// Check authentication status
if (authController.isAuthenticated) {
  // User is logged in
}

// Sign in
await authController.signInWithEmailPassword(email, password);

// Sign out
await authController.signOut();
```

### 2. VehicleController (`lib/controllers/vehicle_controller.dart`)

Manages vehicle data, search, and filtering.

**Key Features:**
- Vehicle listing and search
- Filter management
- Vehicle statistics
- Reactive vehicle state

**Usage:**
```dart
final vehicleController = Get.find<VehicleController>();

// Search vehicles
vehicleController.searchVehicles('car');

// Apply filters
vehicleController.updateFilters({
  'minPrice': 100,
  'maxPrice': 500,
  'location': 'Colombo'
});

// Get filtered vehicles
final vehicles = vehicleController.filteredVehicles;
```

### 3. NavigationController (`lib/controllers/navigation_controller.dart`)

Manages navigation state and provides navigation utilities.

**Key Features:**
- Current route tracking
- Navigation state management
- Simplified navigation methods

**Usage:**
```dart
final navigationController = Get.find<NavigationController>();

// Navigate to route
navigationController.navigateTo('/favorites');

// Navigate and replace
navigationController.navigateAndReplace('/auth');

// Go back
navigationController.goBack();
```

### 4. FavoritesController (`lib/controllers/favorites_controller.dart`)

Manages user favorites functionality.

**Key Features:**
- Add/remove favorites
- Favorites list management
- Reactive favorites state

**Usage:**
```dart
final favoritesController = Get.find<FavoritesController>();

// Add to favorites
await favoritesController.addToFavorites(vehicleData);

// Check if in favorites
bool isFavorite = favoritesController.isInFavorites(vehicleId);

// Get favorites count
int count = favoritesController.favoritesCount;
```

### 5. ThemeController (`lib/controllers/theme_controller.dart`)

Manages app theme and appearance.

**Key Features:**
- Light/dark theme switching
- System theme support
- Theme persistence
- Reactive theme updates

**Usage:**
```dart
final themeController = Get.find<ThemeController>();

// Toggle dark mode
themeController.toggleDarkMode();

// Set specific theme
themeController.setLightTheme();
themeController.setDarkTheme();
themeController.setSystemTheme();
```

## Navigation

### Named Routes

The app uses GetX named routes for navigation:

```dart
// In main.dart
getPages: [
  GetPage(name: '/', page: () => const SplashScreen()),
  GetPage(name: '/welcome', page: () => const WelcomeScreen()),
  GetPage(name: '/auth', page: () => const AuthWrapper()),
  GetPage(name: '/favorites', page: () => const FavoritesScreen()),
  GetPage(name: '/vehicle-detail', page: () {
    final args = Get.arguments as Map<String, dynamic>?;
    return VehicleDetailPage(vehicle: args ?? {});
  }),
  GetPage(name: '/notifications', page: () => const NotificationsScreen()),
  GetPage(name: '/example-getx', page: () => const ExampleGetXScreen()),
],
```

### Navigation Methods

```dart
// Navigate to route
Get.toNamed('/favorites');

// Navigate with arguments
Get.toNamed('/vehicle-detail', arguments: {'vehicle': vehicleData});

// Navigate and replace
Get.offNamed('/auth');

// Navigate and clear stack
Get.offAllNamed('/');

// Go back
Get.back();
```

## Reactive UI

### Obx Widget

Use `Obx` to create reactive UI that automatically updates when observable variables change:

```dart
Obx(() => Text(
  'User: ${authController.user?.displayName ?? 'Guest'}',
)),
```

### GetBuilder

Use `GetBuilder` for more complex reactive widgets:

```dart
GetBuilder<ThemeController>(
  builder: (controller) {
    return Container(
      color: controller.isDarkMode ? Colors.black : Colors.white,
      child: Text('Theme: ${controller.isDarkMode ? 'Dark' : 'Light'}'),
    );
  },
),
```

## Dependency Injection

### Controller Initialization

Controllers are initialized in `main.dart`:

```dart
void main() async {
  // ... other initialization code ...
  
  // Initialize GetX controllers
  Get.put(AuthController());
  Get.put(VehicleController());
  Get.put(NavigationController());
  Get.put(FavoritesController());
  Get.put(ThemeController());
  
  runApp(const MyApp());
}
```

### Accessing Controllers

```dart
// In any widget
final authController = Get.find<AuthController>();
final vehicleController = Get.find<VehicleController>();
```

## Example Implementation

See `lib/screens/example_getx_screen.dart` for a complete example of GetX usage including:

- Controller access and usage
- Reactive UI with Obx
- Navigation
- Theme management
- Authentication state

## Best Practices

1. **Use Obx for simple reactive UI**: When you need to react to simple variable changes
2. **Use GetBuilder for complex widgets**: When you need more control over rebuilds
3. **Initialize controllers early**: Put controller initialization in main.dart
4. **Use named routes**: Prefer named routes over direct navigation
5. **Handle errors gracefully**: Use try-catch blocks in controller methods
6. **Keep controllers focused**: Each controller should handle one specific domain

## Migration from Traditional State Management

If you're migrating from traditional Flutter state management:

1. Replace `StatefulWidget` with `StatelessWidget` where possible
2. Move state logic to controllers
3. Replace `Navigator` calls with `Get` navigation
4. Use `Obx` instead of `setState`
5. Replace `Provider` or `Bloc` with GetX controllers

## Testing

Controllers can be easily tested:

```dart
void main() {
  group('AuthController Tests', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController();
    });

    test('should initialize with unauthenticated state', () {
      expect(controller.isAuthenticated, false);
    });
  });
}
```

## Performance Benefits

- **Automatic disposal**: Controllers are automatically disposed when not in use
- **Memory efficient**: Only rebuilds widgets that actually need updates
- **Lazy loading**: Controllers are only created when needed
- **Minimal boilerplate**: Less code compared to other state management solutions

This implementation provides a solid foundation for scalable state management in your Flutter app. 