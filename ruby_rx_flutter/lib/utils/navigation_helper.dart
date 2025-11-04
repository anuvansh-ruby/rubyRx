import 'package:get/get.dart';
import '../routes/app_routes.dart';

class NavigationHelper {
  /// Safe back navigation that checks if there's a route to go back to
  static void goBack({String? fallbackRoute}) {
    if (Get.routing.previous.isNotEmpty) {
      Get.back();
    } else if (fallbackRoute != null) {
      Get.offAllNamed(fallbackRoute);
    } else {
      // Default fallback based on current route
      String currentRoute = Get.currentRoute;
      String defaultFallback = _getDefaultFallback(currentRoute);
      Get.offAllNamed(defaultFallback);
    }
  }

  /// Safe dialog close that checks if dialog is open
  static void closeDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  /// Safe bottom sheet close that checks if bottom sheet is open
  static void closeBottomSheet() {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  /// Safe overlay close (dialog or bottom sheet)
  static void closeOverlay() {
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  /// Navigate with proper stack management
  static void navigateTo(
    String route, {
    dynamic arguments,
    bool clearStack = false,
  }) {
    if (clearStack) {
      Get.offAllNamed(route, arguments: arguments);
    } else {
      Get.toNamed(route, arguments: arguments);
    }
  }

  /// Replace current route with new one
  static void replaceTo(String route, {dynamic arguments}) {
    Get.offNamed(route, arguments: arguments);
  }

  /// Get appropriate fallback route based on current route
  static String _getDefaultFallback(String currentRoute) {
    switch (currentRoute) {
      case AppRoutes.otpVerify:
      case AppRoutes.register:
      case AppRoutes.forgotPin:
        return AppRoutes.login;
      case AppRoutes.setupPin:
        return AppRoutes.login;
      case AppRoutes.profile:
        return AppRoutes.home;
      case AppRoutes.login:
        return AppRoutes.tutorial;
      default:
        return AppRoutes.home;
    }
  }

  /// Check if user can go back
  static bool canGoBack() {
    return Get.routing.previous.isNotEmpty;
  }

  /// Get previous route
  static String? getPreviousRoute() {
    return Get.routing.previous.isNotEmpty ? Get.routing.previous : null;
  }

  /// Navigate to home with proper authentication check
  static void navigateToHome() {
    Get.offAllNamed(AppRoutes.home);
  }

  /// Navigate to login and clear all routes
  static void navigateToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  /// Check if current route is one of the specified routes
  static bool isCurrentRoute(List<String> routes) {
    return routes.contains(Get.currentRoute);
  }
}
