import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import '../models/user_model.dart';
import '../models/prescription_ocr_model.dart';
import '../routes/app_routes.dart';
import '../data/api/rxnorm_api_service.dart';
import '../data/api/prescription_api_service.dart';
import '../common/components/notification_card.dart';
import '../common/color_pallet/color_pallet.dart';
import 'auth_controller.dart';

class HomeController extends GetxController {
  // Get auth controller instance
  final AuthController authController = Get.find<AuthController>();
  final RxNormApiService _rxNormService = RxNormApiService();
  final PrescriptionApiService _prescriptionService = PrescriptionApiService();

  // Notification controller for card-based notifications
  final NotificationController notificationController =
      NotificationController();

  // Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  // Observable variables
  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  final canNavigateBack = false.obs;
  final canNavigateForward = true.obs;

  // Medicine converter state
  final searchController = TextEditingController();
  final RxList<String> suggestions = <String>[].obs;
  final RxString selectedMedicine = ''.obs;
  final RxList<Map<String, dynamic>> conversionResults =
      <Map<String, dynamic>>[].obs;

  // Drug suggestions state
  final RxList<String> popularDrugs = <String>[
    'Acetaminophen',
    'Ibuprofen',
    'Aspirin',
    'Lisinopril',
    'Metformin',
    'Atorvastatin',
    'Levothyroxine',
    'Amlodipine',
  ].obs;

  // Disease categories state
  final RxList<Map<String, String>> diseaseCategories = <Map<String, String>>[
    {'name': 'Sugar', 'icon': '🩺', 'color': '0xFF4CAF50'},
    {'name': 'Hypertension', 'icon': '❤️', 'color': '0xFFE91E63'},
    {'name': 'Fever', 'icon': '🌡️', 'color': '0xFF9C27B0'},
    {'name': 'Joint Pain', 'icon': '🦴', 'color': '0xFF2196F3'},
  ].obs;

  final RxList<Map<String, dynamic>> diseaseDrugs =
      <Map<String, dynamic>>[].obs;
  final RxString selectedDisease = ''.obs;
  final RxBool showDiseaseModal = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPopularDrugs();
  }

  void _loadPopularDrugs() {
    // This could be enhanced to load from a local database or API
    popularDrugs.refresh();
  }

  // Medicine converter methods
  Future<void> onSearchChanged(String value) async {
    if (value.length < 2) {
      suggestions.clear();
      return;
    }

    isLoading.value = true;
    try {
      final spellingSuggestions = await _rxNormService.getSpellingSuggestions(
        value,
      );
      suggestions.value = spellingSuggestions.take(5).toList();
    } catch (e) {
      print('Error getting suggestions: $e');
      suggestions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> convertMedicine(String medicineName) async {
    if (medicineName.isEmpty) return;

    isLoading.value = true;
    selectedMedicine.value = medicineName;

    try {
      // Search for the drug first
      final drugs = await _rxNormService.searchDrugs(medicineName);

      if (drugs.isNotEmpty) {
        List<Map<String, dynamic>> results = [];

        for (var drug in drugs.take(3)) {
          // Limit to 3 results
          final rxcui = drug['rxcui'];
          final drugName = drug['name'];
          final termType = drug['tty'];

          Map<String, dynamic> result = {
            'original': drugName,
            'rxcui': rxcui,
            'type': termType,
            'brands': <String>[],
            'generics': <String>[],
          };

          // Get brand names if it's a generic
          if (termType == 'IN' || termType == 'MIN') {
            final brands = await _rxNormService.getBrandNames(rxcui);
            result['brands'] = brands;
          }

          // Get generic names if it's a brand
          if (termType == 'BN') {
            final generics = await _rxNormService.getGenericNames(rxcui);
            result['generics'] = generics;
          }

          results.add(result);
        }

        conversionResults.value = results;
      } else {
        conversionResults.clear();
      }
    } catch (e) {
      print('Error converting medicine: $e');
      conversionResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void selectSuggestion(String suggestion) {
    searchController.text = suggestion;
    suggestions.clear();
    convertMedicine(suggestion);
  }

  void selectPopularDrug(String drug) {
    searchController.text = drug;
    convertMedicine(drug);
  }

  // Disease category methods
  Future<void> selectDiseaseCategory(String diseaseName) async {
    selectedDisease.value = diseaseName;
    showDiseaseModal.value = true;

    isLoading.value = true;
    try {
      final drugs = await _rxNormService.getDrugsForCondition(
        diseaseName.toLowerCase(),
      );
      diseaseDrugs.value = drugs;
    } catch (e) {
      print('Error getting drugs for disease: $e');
      diseaseDrugs.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void closeDiseaseModal() {
    showDiseaseModal.value = false;
    selectedDisease.value = '';
    diseaseDrugs.clear();
  }

  void selectDiseaseDrug(String drugName) {
    closeDiseaseModal();
    searchController.text = drugName;
    convertMedicine(drugName);
  }

  // Getters for user data
  UserModel get currentUser => authController.currentUser.value;

  String get userName => currentUser.name ?? 'User';

  String get userEmail => currentUser.email ?? '';

  String get userPhone => currentUser.phone ?? '';

  // Navigation methods
  void navigateToProfile() {
    Get.toNamed(AppRoutes.profile);
  }

  // Camera and image picker methods
  Future<void> scanPrescriptionWithCamera() async {
    try {
      // Check camera permission
      final cameraPermission = await Permission.camera.status;
      if (cameraPermission.isDenied) {
        final status = await Permission.camera.request();
        if (status.isDenied) {
          notificationController.showError(
            'Permission Denied',
            'Camera permission is required to scan prescriptions',
          );
          return;
        }
      }

      // Capture image with camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        await _handlePrescriptionImage(image);
      }
    } catch (e) {
      notificationController.showError(
        'Camera Error',
        'Failed to capture photo: $e',
      );
    }
  }

  Future<void> uploadPrescriptionFromGallery() async {
    try {
      // Pick single image from gallery (changed from pickMultiImage)
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _handlePrescriptionImage(image);
      }
    } catch (e) {
      notificationController.showError(
        'Gallery Error',
        'Failed to pick image from gallery: $e',
      );
    }
  }

  /// Show simple alert dialog with loading indicator
  void _showScanningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    RubyColors.primary1,
                  ),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                AppText.bodyLarge(
                  'Scanning the prescription',
                  color: RubyColors.getTextColor(context, primary: true),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                AppText.bodyMedium(
                  'Please wait...',
                  color: RubyColors.getTextColor(context).withOpacity(0.7),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hide scanning dialog
  void _hideScanningDialog() {
    if (Get.context != null && Get.isDialogOpen == true) {
      Get.back(); // Close the dialog
    }
  }

  Future<void> _handlePrescriptionImage(XFile image) async {
    try {
      print('\n========================================');
      print('🚀 [HOME_CTRL] Starting AI-powered prescription analysis...');
      print('📸 [HOME_CTRL] Image path: ${image.path}');
      print('📸 [HOME_CTRL] Image name: ${image.name}');
      print('📸 [HOME_CTRL] Image mimeType: ${image.mimeType}');
      print('========================================\n');

      // Set loading state to true at the start
      isLoading.value = true;
      print('🔄 [HOME_CTRL] Loading state set to TRUE');

      // Show simple scanning dialog
      final context = Get.context;
      if (context != null && context.mounted) {
        print('🎨 [HOME_CTRL] Context is available and mounted');
        _showScanningDialog(context);
        print('✨ [HOME_CTRL] Scanning dialog displayed');
      } else {
        print(
          '⚠️ [HOME_CTRL] Context is null or not mounted - dialog not shown',
        );
      }

      print('\n📡 [HOME_CTRL] Connecting to AI service...');

      // Upload single image to prescription service with OCR processing
      // Now using XFile directly for cross-platform compatibility
      final response = await _prescriptionService.uploadPrescriptionImage(
        image,
        additionalNotes: 'AI-powered prescription analysis from home screen',
      );

      print('\n📥 [HOME_CTRL] AI response received');
      print('✅ [HOME_CTRL] Response status: ${response.status}');
      print('✅ [HOME_CTRL] Response isSuccess: ${response.isSuccess}');
      print('📝 [HOME_CTRL] Response message: ${response.message}');

      // Hide scanning dialog
      print('🔄 [HOME_CTRL] Hiding scanning dialog...');
      _hideScanningDialog();
      print('✅ [HOME_CTRL] Dialog hidden successfully');

      if (response.isSuccess) {
        print('\n✅ [HOME_CTRL] AI analysis successful, processing results');
        print('📦 [HOME_CTRL] Response data is null: ${response.data == null}');

        // Check if OCR data is available in the response
        if (response.data != null) {
          print('✅ [HOME_CTRL] AI extracted data found, parsing results...');
          print(
            '🔑 [HOME_CTRL] Response data keys: ${response.data!.keys.toList()}',
          );
          print(
            '📊 [HOME_CTRL] Response data values count: ${response.data!.length}',
          );

          try {
            print('🔄 [HOME_CTRL] Attempting to parse PrescriptionOcrData...');

            // Parse the AI-extracted OCR data
            final ocrData = PrescriptionOcrData.fromJson(response.data!);

            print('✅ [HOME_CTRL] AI data parsed successfully');
            print(
              '👨‍⚕️ [HOME_CTRL] Doctor detected: ${ocrData.doctorName ?? 'Not found'}',
            );
            print(
              '👤 [HOME_CTRL] Patient detected: ${ocrData.patientName ?? 'Not found'}',
            );
            print(
              '💊 [HOME_CTRL] Medications found: ${ocrData.medications.length}',
            );
            print(
              '🎯 [HOME_CTRL] Confidence score: ${(ocrData.confidenceScore * 100).toStringAsFixed(1)}%',
            );
            print(
              '📸 [HOME_CTRL] Original image path: ${ocrData.originalImagePath}',
            );

            // Show enhanced success notification with medical AI theme
            print('🔔 [HOME_CTRL] Showing success notification...');
            notificationController.showSuccess(
              '🎉 Medical AI Analysis Complete!',
              'Successfully extracted ${ocrData.medications.length} medications with ${(ocrData.confidenceScore * 100).toStringAsFixed(0)}% medical accuracy',
              duration: const Duration(seconds: 5),
            );

            // Process the AI results
            print('🚀 [HOME_CTRL] Calling _handleOcrResults...');
            await _handleOcrResults(ocrData);
            print('✅ [HOME_CTRL] _handleOcrResults completed successfully');
          } catch (e, stackTrace) {
            print('\n❌❌❌ [HOME_CTRL] CRITICAL ERROR parsing AI data ❌❌❌');
            print('💥 [HOME_CTRL] Error type: ${e.runtimeType}');
            print('💥 [HOME_CTRL] Error: $e');
            print('📚 [HOME_CTRL] Stack trace:\n$stackTrace');
            print('📋 [HOME_CTRL] Raw response data: ${response.data}');
            print('========================================\n');

            // Show detailed error with recovery options
            notificationController.showError(
              '🤖 Medical AI Processing Error',
              'Medical AI analysis completed but data extraction failed. You can still enter prescription details manually.',
              duration: const Duration(seconds: 6),
            );

            // Provide fallback - navigate to manual entry
            Future.delayed(const Duration(seconds: 1), () {
              Get.toNamed(AppRoutes.manualEntry);
            });
          }
        } else {
          print('⚠️ AI response missing data, providing fallback');

          // Show informative message about partial success
          notificationController.showWarning(
            '⚠️ Partial Medical Analysis',
            'Image uploaded successfully, but medical AI couldn\'t extract all prescription data. Please enter details manually.',
            duration: const Duration(seconds: 5),
          );

          // Navigate to manual entry form for user input
          Future.delayed(const Duration(seconds: 1), () {
            Get.toNamed(AppRoutes.manualEntry);
          });
        }
      } else {
        print('❌ AI analysis failed: ${response.message}');

        // Enhanced error handling with medical-specific messages
        String errorTitle = '🚫 Medical AI Analysis Failed';
        String errorMessage = response.message ?? 'Unknown error occurred';

        // Customize error messages based on common medical AI scenarios
        if (errorMessage.toLowerCase().contains('network')) {
          errorTitle = '📡 Medical AI Connection Error';
          errorMessage =
              'Unable to connect to medical AI service. Please check your internet connection and try again.';
        } else if (errorMessage.toLowerCase().contains('timeout')) {
          errorTitle = '⏱️ Medical AI Processing Timeout';
          errorMessage =
              'Medical AI analysis took too long. Please try again with a clearer prescription image.';
        } else if (errorMessage.toLowerCase().contains('format')) {
          errorTitle = '📷 Prescription Image Format Error';
          errorMessage =
              'Please use a clear, high-quality image of your prescription for optimal medical AI analysis.';
        } else if (errorMessage.toLowerCase().contains('size')) {
          errorTitle = '📏 Prescription Image Size Error';
          errorMessage =
              'Image size is not optimal for medical AI. Please try a different prescription image.';
        }

        notificationController.showError(
          errorTitle,
          errorMessage,
          duration: const Duration(seconds: 6),
        );

        // Offer manual entry as alternative after error
        Future.delayed(const Duration(seconds: 3), () {
          notificationController.showInfo(
            '✍️ Manual Entry Available',
            'No worries - you can still enter prescription details manually for full functionality.',
            duration: const Duration(seconds: 4),
          );

          Future.delayed(const Duration(seconds: 2), () {
            Get.toNamed(AppRoutes.manualEntry);
          });
        });
      }
    } catch (e) {
      print('💥 Critical error in AI processing: $e');
      _hideScanningDialog(); // Ensure dialog is hidden

      // Show comprehensive error with helpful medical context
      notificationController.showError(
        '💥 Medical AI System Error',
        'Medical AI processing encountered an unexpected error. Please try again or enter prescription data manually.',
        duration: const Duration(seconds: 6),
      );

      // Provide manual entry fallback with medical context
      Future.delayed(const Duration(seconds: 3), () {
        notificationController.showInfo(
          '✍️ Manual Prescription Entry',
          'Don\'t worry - you can still create and manage prescriptions manually with full medical support.',
          duration: const Duration(seconds: 4),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Get.toNamed(AppRoutes.manualEntry);
        });
      });
    } finally {
      // Always reset loading state
      isLoading.value = false;
      print('🏁 AI processing completed');
    }
  }

  /// Handle OCR processing results and navigate to manual entry form
  Future<void> _handleOcrResults(PrescriptionOcrData ocrData) async {
    print('\n========================================');
    print('✅ [HOME_CTRL] _handleOcrResults called');
    print(
      '📊 [HOME_CTRL] Confidence: ${(ocrData.confidenceScore * 100).toStringAsFixed(1)}%',
    );
    print('👨‍⚕️ [HOME_CTRL] Doctor: ${ocrData.doctorName ?? 'Not detected'}');
    print('👤 [HOME_CTRL] Patient: ${ocrData.patientName ?? 'Not detected'}');
    print('💊 [HOME_CTRL] Medications: ${ocrData.medications.length}');
    print('========================================\n');

    // Show enhanced success notification with AI branding
    String confidenceText = (ocrData.confidenceScore * 100).toStringAsFixed(0);
    String successMessage =
        'AI extracted ${ocrData.medications.length} medications ';

    if (ocrData.doctorName?.isNotEmpty == true) {
      successMessage += 'from Dr. ${ocrData.doctorName}';
    }
    if (ocrData.patientName?.isNotEmpty == true) {
      successMessage += ' for ${ocrData.patientName}';
    }
    successMessage += ' with $confidenceText% confidence.';

    print('🔔 [HOME_CTRL] Showing success notification...');
    notificationController.showSuccess(
      '🤖 AI Analysis Complete!',
      successMessage,
      duration: const Duration(seconds: 4),
    );

    // Add small delay for better UX flow
    print('⏱️ [HOME_CTRL] Waiting 500ms before navigation...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate directly to manual entry form with OCR data
    print('🚀 [HOME_CTRL] Calling _navigateToManualEntryWithOcr...');
    _navigateToManualEntryWithOcr(ocrData);
    print('✅ [HOME_CTRL] Navigation initiated\n');
  }

  /// Navigate to manual entry form with pre-populated OCR data
  void _navigateToManualEntryWithOcr(PrescriptionOcrData ocrData) {
    print('\n========================================');
    print('🚀 [NAV] _navigateToManualEntryWithOcr called');
    print('📋 [NAV] OCR data summary:');
    print('  - Doctor: ${ocrData.doctorName}');
    print('  - Patient: ${ocrData.patientName}');
    print('  - Medications: ${ocrData.medications.length}');
    print('  - Original image: ${ocrData.originalImagePath}');
    print(
      '  - Confidence: ${(ocrData.confidenceScore * 100).toStringAsFixed(1)}%',
    );
    print('========================================\n');

    print('🎯 [NAV] Navigating to: ${AppRoutes.manualEntry}');
    print('📦 [NAV] Arguments: ocr_data + is_ocr_prefill=true');

    try {
      Get.toNamed(
        AppRoutes.manualEntry,
        arguments: {'ocr_data': ocrData, 'is_ocr_prefill': true},
      )?.then((result) {
        print('\n✅ [NAV] Returned from manual entry');
        print('📊 [NAV] Result: $result');

        // Handle result when returning from manual entry form
        if (result != null && result['success'] == true) {
          notificationController.showSuccess(
            'Success',
            'Prescription saved successfully with OCR assistance!',
            duration: const Duration(seconds: 3),
          );
        }
      });

      print('✅ [NAV] Navigation call completed\n');
    } catch (navError, stackTrace) {
      print('\n❌❌❌ [NAV] NAVIGATION ERROR ❌❌❌');
      print('💥 [NAV] Error type: ${navError.runtimeType}');
      print('💥 [NAV] Error: $navError');
      print('📚 [NAV] Stack trace:\n$stackTrace');
      print('========================================\n');
      rethrow;
    }
  }

  // Logout functionality
  void logout() {
    authController.logout();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
