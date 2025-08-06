import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  final RxString _currentRoute = '/'.obs;

  // Getters
  int get currentIndex => _currentIndex.value;
  String get currentRoute => _currentRoute.value;

  // Update current index
  void updateIndex(int index) {
    _currentIndex.value = index;
  }

  // Navigate to route
  void navigateTo(String route, {dynamic arguments}) {
    _currentRoute.value = route;
    Get.toNamed(route, arguments: arguments);
  }

  // Navigate and replace
  void navigateAndReplace(String route, {dynamic arguments}) {
    _currentRoute.value = route;
    Get.offNamed(route, arguments: arguments);
  }

  // Navigate and clear stack
  void navigateAndClear(String route, {dynamic arguments}) {
    _currentRoute.value = route;
    Get.offAllNamed(route, arguments: arguments);
  }

  // Go back
  void goBack() {
    Get.back();
  }
}
