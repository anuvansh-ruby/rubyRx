import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/message_state.dart';
import '../routes/app_routes.dart';
import 'auth_controller.dart';
import '../utils/navigation_helper.dart';
import '../common/color_pallet/color_pallet.dart';
import '../data/services/biometric_service.dart';
import '../data/services/hive_storage_service.dart';
import '../common/widgets/app_text.dart';
import '../data/repositories/profile_repository.dart';
import '../data/models/api_models.dart';

class ProfileController extends GetxController {
  // Repository instance
  final ProfileRepository _profileRepository = ProfileRepository();
  // Get auth controller instance
  final AuthController authController = Get.find<AuthController>();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final isEditing = false.obs;
  final canNavigateBack = true.obs;
  final canNavigateForward = false.obs;
  final profileImagePath = ''.obs;
  final Rx<MessageState> messageState = MessageState.clear().obs;

  // Profile settings
  final notificationsEnabled = true.obs;
  final biometricEnabled = false.obs;
  final darkModeEnabled = false.obs;
  final autoBackupEnabled = true.obs;

  UserModel get currentUser => authController.currentUser.value;

  String get userName => currentUser.name ?? 'User';

  String get userEmail => currentUser.email ?? '';

  String get userPhone => currentUser.phone ?? '';

  String get userAddress => currentUser.address ?? '';

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    _loadBiometricPreference();
  }

  @override
  void onReady() {
    super.onReady();

    nameController.text = userName;
    emailController.text = userEmail;
    phoneController.text = userPhone;
    addressController.text = userAddress;
  }

  void _loadBiometricPreference() {
    try {
      // Load biometric preference from storage
      final saved = authController.biometricEnabled.value;
      biometricEnabled.value = saved;
    } catch (e) {
      print('Error loading biometric preference: $e');
      biometricEnabled.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  // Message helper methods
  void _setSuccessMessage(String message) {
    messageState.value = MessageState.success(message);
  }

  void _setErrorMessage(String message, {ErrorType? errorType}) {
    messageState.value = MessageState.error(message, errorType: errorType);
  }

  void _setInfoMessage(String message) {
    messageState.value = MessageState.info(message);
  }

  void clearMessage() {
    messageState.value = MessageState.clear();
  }

  // Load user profile data
  void loadUserProfile() {
    final user = authController.currentUser.value;
    nameController.text = user.name ?? '';
    emailController.text = user.email ?? '';
    phoneController.text = user.phone ?? '';
    profileImagePath.value = user.profileImage ?? '';
  }

  // Profile management methods
  void toggleEditMode() {
    if (isEditing.value) {
      saveProfile();
    } else {
      isEditing.value = true;
    }
  }

  Future<void> saveProfile() async {
    try {
      isLoading.value = true;
      clearMessage();

      // Parse name into first and last name
      final nameParts = nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Validate input
      if (firstName.isEmpty) {
        _setErrorMessage('First name cannot be empty');
        return;
      }

      if (!GetUtils.isEmail(emailController.text)) {
        _setErrorMessage('Please enter a valid email');
        return;
      }

      // Prepare date of birth (use existing or default)
      final dateOfBirth =
          currentUser.dateOfBirth ??
          DateTime.now()
              .subtract(const Duration(days: 365 * 25))
              .toIso8601String();

      // Call API to update profile
      final response = await _profileRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: emailController.text.trim(),
        dateOfBirth: dateOfBirth,
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
      );

      if (response.isSuccess && response.data != null) {
        // Update local user data through auth controller
        final token = await HiveStorageService.getAuthToken();
        final updatedUser = UserModel.fromPatientInfo(
          response.data!,
          token: token,
          hasPinSetup: authController.currentUser.value.hasPinSetup,
        );

        authController.currentUser.value = updatedUser;

        isEditing.value = false;
        _setSuccessMessage(response.message ?? 'Profile updated successfully');
      } else {
        _setErrorMessage(
          response.message ?? 'Failed to update profile',
          errorType: ErrorType.validation,
        );
      }
    } on ApiError catch (e) {
      print('ProfileController: API Error updating profile: ${e.message}');
      _setErrorMessage(e.message, errorType: ErrorType.network);
    } catch (e) {
      print('ProfileController: Error updating profile: $e');
      _setErrorMessage(
        'An unexpected error occurred. Please try again.',
        errorType: ErrorType.unknown,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void cancelEdit() {
    isEditing.value = false;
    loadUserProfile(); // Reset to original values
  }

  // Image selection methods
  void selectProfileImage() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigation Header for bottom sheet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: AppText.heading6(
                      'Select Profile Picture',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: RubyColors.getIconColor(Get.context!),
                    ),
                    onPressed: () => NavigationHelper.closeBottomSheet(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => pickImageFromCamera(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RubyColors.primary2.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: RubyColors.primary2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const AppText.bodyLarge('Camera'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => pickImageFromGallery(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: RubyColors.primary2.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            size: 40,
                            color: RubyColors.primary2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const AppText.bodyLarge('Gallery'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pickImageFromCamera() {
    // Simulate camera image selection
    profileImagePath.value = 'assets/images/profile_camera.jpg';
    NavigationHelper.closeOverlay();
    _setSuccessMessage('Profile picture updated from camera');
  }

  void pickImageFromGallery() {
    // Simulate gallery image selection
    profileImagePath.value = 'assets/images/profile_gallery.jpg';
    NavigationHelper.closeOverlay();
    _setSuccessMessage('Profile picture updated from gallery');
  }

  // Settings methods
  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    // Save to preferences
    _setInfoMessage('Notification settings updated');
  }

  Future<bool> _showBiometricEnableConfirmation() async {
    try {
      print('ProfileController: Showing biometric confirmation dialog...');

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const AppText.heading6('Enable Biometric Authentication'),
          content: const AppText.bodyMedium(
            'This will allow you to use your fingerprint or face recognition to access the app quickly and securely. You will be prompted to verify your biometric now.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('ProfileController: User clicked Cancel');
                Get.back(result: false);
              },
              child: const AppText.bodyMedium('Cancel'),
            ),
            TextButton(
              onPressed: () {
                print('ProfileController: User clicked Enable');
                Get.back(result: true);
              },
              child: const AppText.bodyMedium('Enable'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      print('ProfileController: Dialog result: $result');
      return result ?? false;
    } catch (e) {
      print('ProfileController: Error showing confirmation dialog: $e');
      return false;
    }
  }

  Future<void> toggleBiometric(bool value) async {
    print('ProfileController: toggleBiometric called with value: $value');

    try {
      isLoading.value = true;

      if (value) {
        // If enabling biometric, first check if it's available
        print('ProfileController: Checking biometric availability...');
        final isAvailable = await BiometricService.isBiometricAvailable();

        if (!isAvailable) {
          print('ProfileController: Biometric not available');
          _setErrorMessage(
            'Biometric authentication is not available on this device. Please set up fingerprint or face recognition in your device settings.',
            errorType: ErrorType.authentication,
          );
          return;
        }

        // Check if biometrics are enrolled
        print('ProfileController: Checking enrolled biometrics...');
        final availableBiometrics =
            await BiometricService.getAvailableBiometrics();
        if (availableBiometrics.isEmpty) {
          print('ProfileController: No biometrics enrolled');
          _setErrorMessage(
            'No biometric authentication methods are set up. Please configure fingerprint or face recognition in your device settings.',
            errorType: ErrorType.authentication,
          );
          return;
        }

        // Show confirmation dialog first
        print('ProfileController: About to show confirmation dialog...');
        final shouldProceed = await _showBiometricEnableConfirmation();
        print(
          'ProfileController: Dialog returned shouldProceed: $shouldProceed',
        );

        if (!shouldProceed) {
          print(
            'ProfileController: User cancelled or dialog failed, returning...',
          );
          return;
        }

        // Prompt for biometric verification
        print('ProfileController: Starting biometric authentication...');
        _setInfoMessage(
          'Please verify your biometric to enable this feature...',
        );

        final biometricTypeName = await BiometricService.getBiometricTypeName();
        final result = await BiometricService.authenticateWithBiometrics(
          reason:
              'Please verify your $biometricTypeName to enable biometric authentication for app access',
        );

        print('ProfileController: Biometric auth result: ${result.success}');

        if (result.success) {
          // Biometric verification successful
          print(
            'ProfileController: Biometric verification successful, updating preferences...',
          );
          biometricEnabled.value = true;
          authController.updateBiometricPreference(true);
          _setSuccessMessage(
            'Biometric authentication enabled successfully! You can now use $biometricTypeName to access the app.',
          );
        } else {
          // Biometric verification failed - ensure the switch stays off
          print(
            'ProfileController: Biometric verification failed: ${result.errorMessage}',
          );
          biometricEnabled.value = false;
          authController.updateBiometricPreference(false);

          if (result.errorType == BiometricErrorType.userCancel) {
            _setInfoMessage('Biometric setup cancelled by user');
          } else if (result.errorType == BiometricErrorType.notEnrolled) {
            _setErrorMessage(
              'No biometric data found. Please set up fingerprint or face recognition in your device settings first.',
              errorType: ErrorType.authentication,
            );
          } else if (result.errorMessage?.contains('FragmentActivity') ==
              true) {
            _setErrorMessage(
              'Biometric authentication setup issue detected. Try restarting the app or enabling biometric authentication through device settings first.',
              errorType: ErrorType.unknown,
            );
          } else {
            _setErrorMessage(
              result.errorMessage ??
                  'Failed to verify biometric. Please ensure biometric authentication is set up in your device settings and try again.',
              errorType: ErrorType.authentication,
            );

            // Show troubleshooting dialog after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              if (Get.isDialogOpen == false) {
                showBiometricTroubleshootingDialog();
              }
            });
          }
        }
      } else {
        // If disabling biometric, just update the preference
        print('ProfileController: Disabling biometric...');
        biometricEnabled.value = false;
        authController.updateBiometricPreference(false);
        _setInfoMessage('Biometric authentication disabled');
      }
    } catch (e) {
      print('ProfileController: Exception in toggleBiometric: $e');
      _setErrorMessage(
        'Failed to update biometric settings. Please try again.',
        errorType: ErrorType.unknown,
      );
    } finally {
      isLoading.value = false;
      print('ProfileController: toggleBiometric completed');
    }
  }

  void toggleDarkMode(bool value) {
    darkModeEnabled.value = value;
    // Update theme
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    _setInfoMessage('Theme updated');
  }

  void toggleAutoBackup(bool value) {
    autoBackupEnabled.value = value;
    // Save to preferences
    _setInfoMessage('Auto backup settings updated');
  }

  // Navigation methods
  void goBack() {
    if (isEditing.value) {
      showCancelDialog();
    } else {
      NavigationHelper.goBack(fallbackRoute: AppRoutes.home);
    }
  }

  void showCancelDialog() {
    Get.dialog(
      AlertDialog(
        title: const AppText.heading6('Discard Changes?'),
        content: const AppText.bodyMedium(
          'Are you sure you want to discard your changes?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
            },
            child: const AppText.bodyMedium('Continue Editing'),
          ),
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
              cancelEdit();
            },
            child: const AppText.bodyMedium('Discard'),
          ),
        ],
      ),
    );
  }

  void navigateToSecurity() {
    _setInfoMessage('Security settings coming soon!');
  }

  void navigateToPrivacy() {
    _setInfoMessage('Privacy settings coming soon!');
  }

  void navigateToHelp() {
    _setInfoMessage('Help center coming soon!');
  }

  void navigateToPersonalInfo() {
    Get.toNamed(AppRoutes.personalInfo);
  }

  void navigateToAbout() {
    _setInfoMessage('About page coming soon!');
  }

  // Biometric troubleshooting helper
  void showBiometricTroubleshootingDialog() {
    Get.dialog(
      AlertDialog(
        title: const AppText.heading6('Biometric Setup Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.heading6(
                'If biometric authentication is not working, try these steps:',
              ),
              SizedBox(height: 12),
              AppText.bodyMedium(
                '1. Ensure your device has biometric authentication (fingerprint/face recognition) set up in Settings',
              ),
              SizedBox(height: 8),
              AppText.bodyMedium(
                '2. Make sure you have at least one fingerprint or face enrolled',
              ),
              SizedBox(height: 8),
              AppText.bodyMedium('3. Try restarting the app completely'),
              SizedBox(height: 8),
              AppText.bodyMedium(
                '4. Check if other apps can use biometric authentication',
              ),
              SizedBox(height: 8),
              AppText.bodyMedium(
                '5. Restart your device if the issue persists',
              ),
              SizedBox(height: 12),
              AppText.caption(
                'If none of these steps work, you can still use the app with PIN authentication.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationHelper.closeDialog(),
            child: const AppText.bodyMedium('Got it'),
          ),
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
              // Retry biometric setup
              toggleBiometric(true);
            },
            child: const AppText.bodyMedium('Try Again'),
          ),
        ],
      ),
    );
  }

  // Account management
  void changePin() {
    Get.toNamed(AppRoutes.setupPin);
  }

  void forgotPin() {
    Get.toNamed(AppRoutes.forgotPin);
  }

  void deleteAccount() {
    Get.dialog(
      AlertDialog(
        title: const AppText.heading6('Delete Account'),
        content: const AppText.bodyMedium(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
            },
            child: const AppText.bodyMedium('Cancel'),
          ),
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
              performDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const AppText.bodyMedium('Delete', color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> performDeleteAccount() async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      _setSuccessMessage('Account deleted successfully');
      authController.logout();
    } catch (e) {
      _setErrorMessage('Failed to delete account: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: const AppText.heading6('Logout'),
        content: const AppText.bodyMedium('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
            },
            child: const AppText.bodyMedium('Cancel'),
          ),
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
              authController.logout();
            },
            child: const AppText.bodyMedium('Logout'),
          ),
        ],
      ),
    );
  }

  // Getters

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!GetUtils.isPhoneNumber(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
