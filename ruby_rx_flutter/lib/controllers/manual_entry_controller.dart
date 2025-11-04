import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import '../models/prescription_models.dart';
import '../models/prescription_ocr_model.dart';
import '../extensions/manual_entry_ocr_extension.dart';
import '../services/prescription_api_service.dart';
import '../services/medicine_data_service.dart';
import '../common/components/notification_card.dart';
import '../common/dialogs/medicine_search_dialog.dart';

class MedicationModel {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final RxString selectedFrequency = ''.obs;
  final RxString selectedDuration = ''.obs;
  final TextEditingController instructionsController = TextEditingController();

  // Store the selected medicine ID from the database
  final RxnInt selectedMedicineId = RxnInt(null);
  final RxString medicineSalt = ''.obs;

  // Track the original medicine name to detect manual changes
  String _originalMedicineName = '';

  MedicationModel() {
    // Listen for changes in medicine name to reset ID if manually changed
    nameController.addListener(() {
      final currentName = nameController.text.trim();
      if (_originalMedicineName.isNotEmpty &&
          currentName != _originalMedicineName &&
          selectedMedicineId.value != null) {
        // User manually changed the medicine name, clear the selected ID
        selectedMedicineId.value = null;
        medicineSalt.value = '';
        _originalMedicineName = '';
      }
    });
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    instructionsController.dispose();
  }

  // Set medicine from search selection
  void setFromSearchSelection(MedicineSearchModel medicine) {
    selectedMedicineId.value = medicine.medId;
    nameController.text =
        medicine.medBrandName ?? medicine.medGenericName ?? '';
    _originalMedicineName = nameController.text;

    // Build composition info from all available compositions
    final compositions = <String>[];

    if (medicine.medCompositionName1 != null &&
        medicine.medCompositionName1!.isNotEmpty) {
      String comp = medicine.medCompositionName1!;
      if (medicine.medCompositionStrength1 != null &&
          medicine.medCompositionStrength1!.isNotEmpty) {
        comp += ' ${medicine.medCompositionStrength1!}';
      }
      if (medicine.medCompositionUnit1 != null &&
          medicine.medCompositionUnit1!.isNotEmpty) {
        comp += '${medicine.medCompositionUnit1!}';
      }
      compositions.add(comp);
    }

    if (medicine.medCompositionName2 != null &&
        medicine.medCompositionName2!.isNotEmpty) {
      String comp = medicine.medCompositionName2!;
      if (medicine.medCompositionStrength2 != null &&
          medicine.medCompositionStrength2!.isNotEmpty) {
        comp += ' ${medicine.medCompositionStrength2!}';
      }
      if (medicine.medCompositionUnit2 != null &&
          medicine.medCompositionUnit2!.isNotEmpty) {
        comp += '${medicine.medCompositionUnit2!}';
      }
      compositions.add(comp);
    }

    if (medicine.medCompositionName3 != null &&
        medicine.medCompositionName3!.isNotEmpty) {
      String comp = medicine.medCompositionName3!;
      if (medicine.medCompositionStrength3 != null &&
          medicine.medCompositionStrength3!.isNotEmpty) {
        comp += ' ${medicine.medCompositionStrength3!}';
      }
      if (medicine.medCompositionUnit3 != null &&
          medicine.medCompositionUnit3!.isNotEmpty) {
        comp += '${medicine.medCompositionUnit3!}';
      }
      compositions.add(comp);
    }

    if (medicine.medCompositionName4 != null &&
        medicine.medCompositionName4!.isNotEmpty) {
      String comp = medicine.medCompositionName4!;
      if (medicine.medCompositionStrength4 != null &&
          medicine.medCompositionStrength4!.isNotEmpty) {
        comp += ' ${medicine.medCompositionStrength4!}';
      }
      if (medicine.medCompositionUnit4 != null &&
          medicine.medCompositionUnit4!.isNotEmpty) {
        comp += '${medicine.medCompositionUnit4!}';
      }
      compositions.add(comp);
    }

    if (medicine.medCompositionName5 != null &&
        medicine.medCompositionName5!.isNotEmpty) {
      String comp = medicine.medCompositionName5!;
      if (medicine.medCompositionStrength5 != null &&
          medicine.medCompositionStrength5!.isNotEmpty) {
        comp += ' ${medicine.medCompositionStrength5!}';
      }
      if (medicine.medCompositionUnit5 != null &&
          medicine.medCompositionUnit5!.isNotEmpty) {
        comp += '${medicine.medCompositionUnit5!}';
      }
      compositions.add(comp);
    }

    // Set composition as medicine salt
    if (compositions.isNotEmpty) {
      medicineSalt.value = compositions.join(' + ');
    }
  }

  // Clear medicine selection
  void clearSelection() {
    selectedMedicineId.value = null;
    medicineSalt.value = '';
    _originalMedicineName = '';
  }

  // Check if medication has a valid medicine ID (selected from database)
  bool get hasValidMedicineId =>
      selectedMedicineId.value != null && selectedMedicineId.value! > 0;

  // Check if medication was manually entered (no ID)
  bool get isManualEntry => !hasValidMedicineId;

  Map<String, dynamic> toJson() {
    return {
      'id': selectedMedicineId.value,
      'name': nameController.text,
      'dosage': dosageController.text,
      'frequency': selectedFrequency.value,
      'duration': selectedDuration.value,
      'instructions': instructionsController.text,
      'salt': medicineSalt.value,
    };
  }

  // Convert to name-based medicine request
  CreateMedicineByNameRequest toCreateMedicineByNameRequest() {
    return CreateMedicineByNameRequest(
      id:
          selectedMedicineId.value ??
          0, // Use selected medicine ID or 0 if manually entered
      medicineName: nameController.text.trim(),
      medicineFrequency: selectedFrequency.value.trim().isEmpty
          ? null
          : selectedFrequency.value.trim(),
      medicineDuration: selectedDuration.value.trim().isEmpty
          ? null
          : selectedDuration.value.trim(),
      medicineInstructions: instructionsController.text.trim().isEmpty
          ? null
          : instructionsController.text.trim(),
      medicineSalt: medicineSalt.value.trim().isEmpty
          ? null
          : medicineSalt.value.trim(),
    );
  }
}

class ManualEntryController extends GetxController {
  // Dependencies
  late final PrescriptionApiService _apiService;
  late final NotificationController notificationController;

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  // Doctor Information Controllers
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController doctorNumberController = TextEditingController();
  final TextEditingController appointmentDateController =
      TextEditingController();
  final TextEditingController clinicAddressController = TextEditingController();

  // Selected appointment date
  final Rx<DateTime?> selectedAppointmentDate = Rx<DateTime?>(null);

  // Medications
  final RxList<MedicationModel> medications = <MedicationModel>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isMedicineSearching = false.obs;

  // Medicine search functionality
  final RxList<MedicineSearchModel> medicineSearchResults =
      <MedicineSearchModel>[].obs;
  final RxList<MedicineSearchModel> popularMedicines =
      <MedicineSearchModel>[].obs;
  final RxString currentSearchQuery = ''.obs;

  // OCR data handling
  PrescriptionOcrData? _ocrData;
  final RxBool isOcrPrefilled = false.obs;
  final RxString ocrSource = ''.obs;

  @override
  void onInit() {
    super.onInit();

    print('\n========================================');
    print('🎬 [MANUAL_ENTRY] onInit() called');
    print('========================================\n');

    // Initialize API service and notification controller
    _apiService = Get.find<PrescriptionApiService>();
    notificationController = NotificationController();

    // Initialize with one empty medication entry
    addMedication();
    print('✅ [MANUAL_ENTRY] Initial medication added');

    // Check if OCR data was passed for pre-population
    final arguments = Get.arguments;
    print('📦 [MANUAL_ENTRY] Arguments received: ${arguments != null}');

    if (arguments != null && arguments is Map<String, dynamic>) {
      print('📋 [MANUAL_ENTRY] Arguments type is Map<String, dynamic>');
      print('📋 [MANUAL_ENTRY] Arguments keys: ${arguments.keys.toList()}');

      final ocrData = arguments['ocr_data'];
      final isOcrPrefill = arguments['is_ocr_prefill'] ?? false;

      print('📊 [MANUAL_ENTRY] OCR data present: ${ocrData != null}');
      print('📊 [MANUAL_ENTRY] OCR data type: ${ocrData.runtimeType}');
      print('📊 [MANUAL_ENTRY] Is OCR prefill: $isOcrPrefill');

      if (ocrData != null && ocrData is PrescriptionOcrData && isOcrPrefill) {
        _ocrData = ocrData;
        isOcrPrefilled.value = true;
        ocrSource.value = 'AI Prescription Scanner';

        print('✅ [MANUAL_ENTRY] OCR data stored successfully');
        print('👨‍⚕️ [MANUAL_ENTRY] Doctor: ${ocrData.doctorName}');
        print('👤 [MANUAL_ENTRY] Patient: ${ocrData.patientName}');
        print(
          '💊 [MANUAL_ENTRY] Medications to prefill: ${ocrData.medications.length}',
        );

        // Pre-populate form with OCR data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print(
            '\n🔄 [MANUAL_ENTRY] Post-frame callback - starting prefill...',
          );

          try {
            prePopulateFromOcr(ocrData);
            update();
            print('✅ [MANUAL_ENTRY] Form pre-populated successfully\n');
          } catch (e, stackTrace) {
            print('\n❌❌❌ [MANUAL_ENTRY] PREFILL ERROR ❌❌❌');
            print('💥 [MANUAL_ENTRY] Error type: ${e.runtimeType}');
            print('💥 [MANUAL_ENTRY] Error: $e');
            print('📚 [MANUAL_ENTRY] Stack trace:\n$stackTrace');
            print('========================================\n');

            notificationController.showError(
              'OCR Error',
              'Failed to pre-populate form with AI data: $e',
            );
          }
        });
      } else {
        print(
          '⚠️ [MANUAL_ENTRY] OCR data validation failed or prefill disabled',
        );
      }
    } else {
      print('ℹ️ [MANUAL_ENTRY] No arguments received - manual entry mode\n');
    }
  }

  @override
  void onClose() {
    // Dispose all controllers
    doctorNameController.dispose();
    doctorNumberController.dispose();
    appointmentDateController.dispose();
    clinicAddressController.dispose();

    // Dispose medication controllers
    for (var medication in medications) {
      medication.dispose();
    }

    super.onClose();
  }

  // Getters
  PrescriptionOcrData? get ocrData => _ocrData;
  bool get hasOcrData => _ocrData != null;

  // Add new medication
  void addMedication() {
    medications.add(MedicationModel());
  }

  // Remove medication
  void removeMedication(int index) {
    if (index >= 0 && index < medications.length) {
      medications[index].dispose();
      medications.removeAt(index);
    }
  }

  // Validate required fields
  bool _validateRequiredFields() {
    final errors = <String>[];

    // Check doctor name
    if (doctorNameController.text.trim().isEmpty) {
      errors.add('Doctor name is required');
    }

    // Check doctor number
    if (doctorNumberController.text.trim().isEmpty) {
      errors.add('Doctor number is required');
    }

    // Check appointment date
    if (appointmentDateController.text.trim().isEmpty) {
      errors.add('Appointment date is required');
    }

    // Check at least one medication
    if (medications.isEmpty) {
      errors.add('At least one medication is required');
    } else {
      // Check medication names
      for (int i = 0; i < medications.length; i++) {
        if (medications[i].nameController.text.trim().isEmpty) {
          errors.add('Medication ${i + 1} name is required');
        }
      }
    }

    if (errors.isNotEmpty) {
      notificationController.showError('Validation Error', errors.join('\\n'));
      return false;
    }

    return true;
  }

  /// Load initial medicines for search dialog
  Future<void> loadInitialMedicines() async {
    try {
      isMedicineSearching.value = true;
      currentSearchQuery.value = '';

      List<MedicineSearchModel> medicines = [];

      // Try to load popular medicines first, fallback to common search
      try {
        medicines = await MedicineDataService.getPopularMedicines(limit: 10);
      } catch (e) {
        medicines = await MedicineDataService.searchMedicines(
          query: 'paracetamol',
          limit: 10,
        );
      }

      medicineSearchResults.value = medicines;
    } catch (e) {
      medicineSearchResults.clear();
    } finally {
      isMedicineSearching.value = false;
    }
  }

  /// Search medicines from the database
  Future<void> searchMedicines(String query) async {
    if (query.trim().length < 2) {
      medicineSearchResults.clear();
      currentSearchQuery.value = '';
      return;
    }

    try {
      isMedicineSearching.value = true;
      currentSearchQuery.value = query;

      final results = await MedicineDataService.searchMedicines(
        query: query,
        limit: 20,
      );

      medicineSearchResults.value = results;
    } catch (e) {
      notificationController.showError(
        'Search Error',
        'Failed to search medicines: $e',
      );
    } finally {
      isMedicineSearching.value = false;
    }
  }

  /// Get medicine suggestions for autocomplete
  Future<List<MedicineSearchModel>> getMedicineSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final suggestions = await MedicineDataService.getMedicineSuggestions(
        query: query,
        limit: 10,
      );

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  /// Prefill medication data from selected medicine
  void prefillMedicationFromSearch(
    MedicineSearchModel medicine,
    int medicationIndex,
  ) {
    try {
      if (medicationIndex >= 0 && medicationIndex < medications.length) {
        final medication = medications[medicationIndex];

        // Set medicine data from search selection
        medication.setFromSearchSelection(medicine);

        // Build dosage info from compositions
        final dosageComponents = <String>[];

        if (medicine.medCompositionName1 != null &&
            medicine.medCompositionName1!.isNotEmpty) {
          String comp = medicine.medCompositionName1!;
          if (medicine.medCompositionStrength1 != null &&
              medicine.medCompositionStrength1!.isNotEmpty) {
            comp += ' ${medicine.medCompositionStrength1!}';
          }
          if (medicine.medCompositionUnit1 != null &&
              medicine.medCompositionUnit1!.isNotEmpty) {
            comp += '${medicine.medCompositionUnit1!}';
          }
          dosageComponents.add(comp);
        }

        if (medicine.medCompositionName2 != null &&
            medicine.medCompositionName2!.isNotEmpty) {
          String comp = medicine.medCompositionName2!;
          if (medicine.medCompositionStrength2 != null &&
              medicine.medCompositionStrength2!.isNotEmpty) {
            comp += ' ${medicine.medCompositionStrength2!}';
          }
          if (medicine.medCompositionUnit2 != null &&
              medicine.medCompositionUnit2!.isNotEmpty) {
            comp += '${medicine.medCompositionUnit2!}';
          }
          dosageComponents.add(comp);
        }

        if (medicine.medCompositionName3 != null &&
            medicine.medCompositionName3!.isNotEmpty) {
          String comp = medicine.medCompositionName3!;
          if (medicine.medCompositionStrength3 != null &&
              medicine.medCompositionStrength3!.isNotEmpty) {
            comp += ' ${medicine.medCompositionStrength3!}';
          }
          if (medicine.medCompositionUnit3 != null &&
              medicine.medCompositionUnit3!.isNotEmpty) {
            comp += '${medicine.medCompositionUnit3!}';
          }
          dosageComponents.add(comp);
        }

        if (dosageComponents.isNotEmpty) {
          medication.dosageController.text = dosageComponents.join(' + ');
        }

        // Set pack size as additional info if available
        if (medicine.medPackSize != null && medicine.medPackSize!.isNotEmpty) {
          String currentInstructions = medication.instructionsController.text;
          String packInfo = 'Pack: ${medicine.medPackSize!}';

          if (currentInstructions.isEmpty) {
            medication.instructionsController.text = packInfo;
          } else if (!currentInstructions.contains(packInfo)) {
            medication.instructionsController.text =
                '$currentInstructions\n$packInfo';
          }
        }

        // Build display name for notification
        String medicineName =
            medicine.medBrandName ?? medicine.medGenericName ?? 'Unknown';
        String manufacturerInfo =
            medicine.medManufacturerName != null &&
                medicine.medManufacturerName!.isNotEmpty
            ? ' by ${medicine.medManufacturerName}'
            : '';

        notificationController.showSuccess(
          'Medicine Selected',
          'Selected $medicineName$manufacturerInfo (ID: ${medicine.medId})',
        );

        // Clear search results
        medicineSearchResults.clear();
        currentSearchQuery.value = '';
      } else {
        notificationController.showError(
          'Error',
          'Invalid medication selection',
        );
      }
    } catch (e) {
      notificationController.showError(
        'Error',
        'Failed to prefill medication data: $e',
      );
    }
  }

  /// Select popular medicine for quick filling
  void selectPopularMedicine(MedicineSearchModel medicine) {
    try {
      // Find the first empty medication or add a new one
      int targetIndex = -1;

      for (int i = 0; i < medications.length; i++) {
        if (medications[i].nameController.text.trim().isEmpty) {
          targetIndex = i;
          break;
        }
      }

      if (targetIndex == -1) {
        // All medications are filled, add a new one
        addMedication();
        targetIndex = medications.length - 1;
      }

      prefillMedicationFromSearch(medicine, targetIndex);
    } catch (e) {
      notificationController.showError(
        'Error',
        'Failed to select medicine: $e',
      );
    }
  }

  /// Clear medicine search results
  void clearMedicineSearch() {
    medicineSearchResults.clear();
    currentSearchQuery.value = '';
  }

  /// Show medicine search dialog for a specific medication
  Future<void> showMedicineSearchDialog(int medicationIndex) async {
    if (medicationIndex < 0 || medicationIndex >= medications.length) {
      return;
    }

    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return MedicineSearchDialog(
          medicationIndex: medicationIndex,
          onMedicineSelected: prefillMedicationFromSearch,
        );
      },
    );
  }

  /// Manually trigger medicine search dialog (for search button)
  void triggerMedicineSearch(int medicationIndex) {
    showMedicineSearchDialog(medicationIndex);
  }

  /// Validate all prescription data before saving
  /// Returns true if all validations pass, false otherwise
  Future<bool> _validatePrescriptionData() async {
    // Step 1: Basic required fields validation
    if (!_validateRequiredFields()) {
      return false;
    }

    // Step 2: Advanced validation using PrescriptionValidation
    final validationErrors = <String>[];
    final manualEntries = <String>[];
    final databaseMedicines = <String>[];

    // Validate medications and categorize them
    for (int i = 0; i < medications.length; i++) {
      final medication = medications[i];

      final nameError = PrescriptionValidation.validateMedicineName(
        medication.nameController.text,
      );
      if (nameError != null) {
        validationErrors.add('Medication ${i + 1}: $nameError');
      }

      final frequencyError = PrescriptionValidation.validateFrequency(
        medication.selectedFrequency.value,
      );
      if (frequencyError != null) {
        validationErrors.add('Medication ${i + 1}: $frequencyError');
      }

      // Categorize medicines by entry type
      if (medication.hasValidMedicineId) {
        databaseMedicines.add(
          '${medication.nameController.text} (ID: ${medication.selectedMedicineId.value})',
        );
      } else {
        manualEntries.add(medication.nameController.text);
      }
    }

    // Check if any validation errors occurred
    if (validationErrors.isNotEmpty) {
      notificationController.showError(
        'Validation Error',
        validationErrors.first,
      );
      return false;
    }

    // Log medication categorization for debugging
    if (databaseMedicines.isNotEmpty) {
      print('✅ Database medicines: ${databaseMedicines.join(', ')}');
    }
    if (manualEntries.isNotEmpty) {
      print('✏️ Manual entries: ${manualEntries.join(', ')}');
    }

    return true;
  }

  /// Create prescription request object from form data
  CreatePrescriptionByNameRequest _createPrescriptionRequest() {
    final prescriptionRequest = CreatePrescriptionByNameRequest(
      // Doctor information
      doctorName: doctorNameController.text.trim(),
      doctorPhoneNumber: doctorNumberController.text.trim(),
      appointmentName: appointmentDateController.text.trim(),
      appointmentDate: appointmentDateController.text
          .trim(), // Send the formatted date
      clinicAddress: clinicAddressController.text.trim().isEmpty
          ? null
          : clinicAddressController.text.trim(),

      // Medications
      medicines: medications
          .map((med) => med.toCreateMedicineByNameRequest())
          .toList(),
    );

    return prescriptionRequest;
  }

  /// Execute the API call to save prescription
  Future<bool> _executePrescriptionSave(
    CreatePrescriptionByNameRequest request,
  ) async {
    try {
      final response = await _apiService.createPrescriptionByNameWithPatientId(
        prescriptionData: request,
        currentPatientId: null,
      );

      if (response.success) {
        await _handleSaveSuccess(response.data);
        return true;
      } else {
        _handleSaveFailure(response.message ?? 'Unknown error');
        return false;
      }
    } catch (e) {
      _handleSaveException(e);
      return false;
    }
  }

  /// Handle successful prescription save
  Future<void> _handleSaveSuccess(dynamic prescriptionData) async {
    notificationController.showSuccess(
      'Success',
      'Prescription saved successfully!',
    );

    // Navigate to prescription manager
    Future.delayed(const Duration(seconds: 1), () {
      Get.offNamed(
        '/prescription-manager',
        arguments: {
          'success': true,
          'prescription_data': prescriptionData,
          'show_success_message': true,
        },
      );
    });
  }

  /// Handle prescription save failure
  void _handleSaveFailure(String errorMessage) {
    notificationController.showError(
      'Save Failed',
      errorMessage.isNotEmpty
          ? errorMessage
          : 'Failed to save prescription. Please check your data and try again.',
    );
  }

  /// Handle prescription save exception
  void _handleSaveException(dynamic exception) {
    notificationController.showError(
      'Save Error',
      'Failed to save prescription: ${exception.toString()}. Please check your internet connection and try again.',
    );
  }

  /// Main method to save prescription - orchestrates the entire process
  Future<void> savePrescription() async {
    try {
      // Step 1: Set loading state
      isSaving.value = true;

      // Step 2: Validate prescription data
      final isValid = await _validatePrescriptionData();
      if (!isValid) {
        return;
      }

      // Step 3: Create prescription request object
      final prescriptionRequest = _createPrescriptionRequest();

      // Step 4: Execute the save operation
      await _executePrescriptionSave(prescriptionRequest);
    } catch (e) {
      _handleSaveException(e);
    } finally {
      // Step 5: Clean up loading state
      isSaving.value = false;
    }
  }

  // Clear all data
  void clearAllData() {
    Get.dialog(
      AlertDialog(
        title: AppText.heading6(
          'Clear All Data',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: AppText.bodyMedium(
          'Are you sure you want to clear all entered data? This action cannot be undone.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: AppText.bodyMedium(
              'Cancel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _clearAllFields();
              Get.back();
              notificationController.showInfo(
                'Cleared',
                'All data has been cleared',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: AppText.bodyMedium(
              'Clear',
              color: Colors.white,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFields() {
    // Clear doctor information
    doctorNameController.clear();
    doctorNumberController.clear();
    appointmentDateController.clear();
    clinicAddressController.clear();
    selectedAppointmentDate.value = null;

    // Clear medications
    for (var medication in medications) {
      medication.dispose();
    }
    medications.clear();

    // Clear OCR data
    _ocrData = null;
    isOcrPrefilled.value = false;
    ocrSource.value = '';

    // Add one empty medication
    addMedication();
  }

  /// Select appointment date using date picker
  Future<void> selectAppointmentDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedAppointmentDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Appointment Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null && picked != selectedAppointmentDate.value) {
      selectedAppointmentDate.value = picked;

      // Format the date as DD/MM/YYYY for display
      final formattedDate =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';

      appointmentDateController.text = formattedDate;
    }
  }

  // OCR-related methods
  void showOcrComparisonView() {
    if (_ocrData != null) {
      showImageComparisonView(_ocrData!);
    }
  }

  void resetToOcrData() {
    if (_ocrData != null) {
      try {
        prePopulateFromOcr(_ocrData!);
        notificationController.showInfo(
          'Reset to OCR Data',
          'Form has been reset to original AI-extracted data',
        );
      } catch (e) {
        notificationController.showError(
          'Reset Error',
          'Failed to reset form to OCR data: $e',
        );
      }
    } else {
      notificationController.showWarning(
        'No OCR Data',
        'No original AI data available to reset to',
      );
    }
  }

  // Auto-save functionality (optional)
  void autoSave() {
    // Implementation for auto-save to local storage
    // This can be useful for preventing data loss
  }

  void navigateBack() {
    Get.back();
  }
}
