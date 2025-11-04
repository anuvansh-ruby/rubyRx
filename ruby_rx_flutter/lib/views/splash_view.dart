import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../common/components/gradient_background.dart';
import '../common/widgets/app_text.dart';
import '../data/services/hive_storage_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Start the fade-in animation
    _animationController.forward();

    // Wait for 3 seconds total (1.5s animation + 1.5s display)
    await Future.delayed(const Duration(milliseconds: 3000));

    // Check authentication state and navigate appropriately
    _navigateToAppropriateScreen();
  }

  void _navigateToAppropriateScreen() {
    print('=== SplashView Navigation Debug ===');

    // Check if user has completed tutorial
    final tutorialCompleted = HiveStorageService.getTutorialCompleted();
    print('Tutorial completed: $tutorialCompleted');

    final firstLaunch = HiveStorageService.isFirstAppLaunch();
    print('Is first app launch: $firstLaunch');

    if (!tutorialCompleted || firstLaunch) {
      // Show tutorial for new users
      print('Navigating to: TUTORIAL');
      Get.offAllNamed(AppRoutes.tutorial);
    } else {
      // Tutorial completed, check if user has PIN
      final hasPin = HiveStorageService.getAppPin() != null;
      final pinValue = HiveStorageService.getAppPin();
      print('Has PIN stored: $hasPin');
      print('PIN value: $pinValue');

      if (hasPin) {
        // User has PIN, navigate to PIN entry
        print('Navigating to: PIN ENTRY');
        Get.offAllNamed(AppRoutes.pinEntry);
      } else {
        // No PIN stored, navigate to login
        print('Navigating to: LOGIN');
        Get.offAllNamed(AppRoutes.login);
      }
    }

    print('=== End SplashView Navigation Debug ===');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main Ruby AI Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'lib/assets/ruby_rx_logo_real.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 150),

                    // Powered by text
                    AppText.subtitle2('Powered by', color: Colors.grey),

                    const SizedBox(height: 12),

                    // Anuvansh Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'lib/assets/anuvansh_logo.png',
                        width: 120,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
