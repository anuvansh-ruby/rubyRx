import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../models/tutorial_item.dart';
import '../routes/app_routes.dart';
import '../data/services/hive_storage_service.dart';

class TutorialController extends GetxController {
  // Observable variables
  final RxInt currentIndex = 0.obs;
  final RxBool isAutoAdvancing = true.obs;

  // Timer for auto-advance
  Timer? _autoAdvanceTimer;

  // Tutorial data
  List<TutorialItem> get tutorialItems => TutorialData.tutorialItems;

  @override
  void onInit() {
    super.onInit();
    _checkTutorialStatus();
    _startAutoAdvance();
  }

  @override
  void onClose() {
    _autoAdvanceTimer?.cancel();
    super.onClose();
  }

  void _checkTutorialStatus() {
    // If tutorial is already completed and this is not first launch, navigate to appropriate screen
    if (!HiveStorageService.isFirstAppLaunch() &&
        HiveStorageService.getTutorialCompleted()) {
      // Use post frame callback to ensure navigation happens after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToAppropriateScreen();
      });
    }
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (isAutoAdvancing.value) {
        nextSlide();
      }
    });
  }

  void nextSlide() {
    if (currentIndex.value < tutorialItems.length - 1) {
      currentIndex.value++;
    } else {
      // Reset to first slide for continuous loop
      currentIndex.value = 0;
    }
  }

  void goToSlide(int index) {
    if (index >= 0 && index < tutorialItems.length) {
      currentIndex.value = index;
      // Pause auto-advance for a moment when user interacts
      _pauseAutoAdvance();
    }
  }

  void _pauseAutoAdvance() {
    isAutoAdvancing.value = false;
    _autoAdvanceTimer?.cancel();

    // Resume auto-advance after 3 seconds of inactivity
    Timer(const Duration(seconds: 3), () {
      isAutoAdvancing.value = true;
      _startAutoAdvance();
    });
  }

  void skipTutorial() async {
    _autoAdvanceTimer?.cancel();

    // Mark tutorial as completed and app as launched
    await HiveStorageService.setTutorialCompleted(true);
    await HiveStorageService.setFirstAppLaunch(false);

    _navigateToAppropriateScreen();
  }

  void _navigateToAppropriateScreen() {
    print('=== TutorialController Navigation Debug ===');

    // Check if user has a PIN stored
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

    print('=== End TutorialController Navigation Debug ===');
  }

  void onDotTapped(int index) {
    goToSlide(index);
  }
}
