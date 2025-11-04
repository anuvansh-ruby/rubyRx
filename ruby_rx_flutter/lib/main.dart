import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'bindings/auth_binding.dart';
import 'bindings/services_binding.dart';
import 'controllers/theme_controller.dart';
import 'data/services/hive_storage_service.dart';
import 'utils/app_theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage service
  await HiveStorageService.init();

  // Initialize global services
  ServicesBinding().dependencies();

  // Initialize ThemeController globally
  Get.put(ThemeController());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: 'Ruby AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      initialBinding: AuthBinding(),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
