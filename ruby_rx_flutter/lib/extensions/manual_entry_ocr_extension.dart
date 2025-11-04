import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manual_entry_controller.dart';
import '../models/prescription_ocr_model.dart';
import '../common/widgets/app_text.dart';

/// Extension for ManualEntryController to handle OCR data pre-population
extension ManualEntryOcrExtension on ManualEntryController {
  /// Pre-populate form fields with OCR extracted data
  void prePopulateFromOcr(PrescriptionOcrData ocrData) {
    print('\n🔄 ========================================');
    print('🔄 [OCR_PREFILL] Starting prePopulateFromOcr');
    print('🔄 ========================================');

    try {
      // Clear existing data first
      _clearAllFieldsForOcr();
      print('🔄 [OCR_PREFILL] Cleared existing fields');

      // Pre-populate Doctor Information (only doctor name - phone and appointment are manual)
      if (ocrData.doctorName != null && ocrData.doctorName!.trim().isNotEmpty) {
        // Sanitize and validate doctor name
        final sanitizedDoctorName = ocrData.doctorName!.trim();
        doctorNameController.text = sanitizedDoctorName;
        print('✅ [OCR_PREFILL] Set doctor name: "$sanitizedDoctorName"');
      } else {
        print('⚠️ [OCR_PREFILL] No doctor name in OCR data');
      }

      // Pre-populate Clinic Address (optional field)
      if (ocrData.clinicName != null && ocrData.clinicName!.trim().isNotEmpty) {
        // Sanitize and validate clinic address
        final sanitizedClinicAddress = ocrData.clinicName!.trim();
        clinicAddressController.text = sanitizedClinicAddress;
        print('✅ [OCR_PREFILL] Set clinic address: "$sanitizedClinicAddress"');
      } else {
        print(
          'ℹ️ [OCR_PREFILL] No clinic address in OCR data (optional field)',
        );
      }

      // Set default appointment date to today
      final today = DateTime.now();
      selectedAppointmentDate.value = today;
      final formattedDate =
          '${today.day.toString().padLeft(2, '0')}/'
          '${today.month.toString().padLeft(2, '0')}/'
          '${today.year}';
      appointmentDateController.text = formattedDate;
      print('✅ [OCR_PREFILL] Set appointment date to today: "$formattedDate"');

      // Pre-populate Medications
      medications.clear();
      print(
        '🔄 [OCR_PREFILL] Processing ${ocrData.medications.length} medications',
      );

      if (ocrData.medications.isNotEmpty) {
        for (int i = 0; i < ocrData.medications.length; i++) {
          try {
            final ocrMedication = ocrData.medications[i];

            // Validate medication has at least a name
            if (ocrMedication.name.trim().isEmpty) {
              print(
                '⚠️ [OCR_PREFILL] Skipping medication ${i + 1}: Empty name',
              );
              continue;
            }

            print(
              '✅ [OCR_PREFILL] Adding medication ${i + 1}: "${ocrMedication.name}"',
            );

            // Convert OCR medication to MedicationModel
            final medicationModel = ocrMedication.toMedicationModel();
            medications.add(medicationModel);
          } catch (medError) {
            print(
              '❌ [OCR_PREFILL] Error processing medication ${i + 1}: $medError',
            );
            // Continue with next medication instead of failing completely
          }
        }
      }

      // Ensure at least one medication entry exists
      if (medications.isEmpty) {
        print(
          '⚠️ [OCR_PREFILL] No valid medications found, adding empty entry',
        );
        addMedication();
      }

      print('✅ [OCR_PREFILL] Pre-population completed successfully');
      print(
        '   - Doctor name: ${doctorNameController.text.isEmpty ? "NOT SET" : "SET"}',
      );
      print(
        '   - Clinic address: ${clinicAddressController.text.isEmpty ? "NOT SET" : "SET"}',
      );
      print(
        '   - Appointment date: ${appointmentDateController.text.isEmpty ? "NOT SET" : "SET"}',
      );
      print('   - Medications: ${medications.length}');
      print('🔄 ========================================\n');

      // Show success notification
      notificationController.showSuccess(
        'Scanned Successfully',
        'Doctor name and ${medications.length} medicine(s) extracted. Please complete: Doctor Number and verify Appointment Date.',
      );
    } catch (e, stackTrace) {
      print('\n❌ ========================================');
      print('❌ [OCR_PREFILL] CRITICAL ERROR');
      print('❌ ========================================');
      print('� Error: $e');
      print('📚 Stack trace:\n$stackTrace');
      print('❌ ========================================\n');

      notificationController.showError(
        'Pre-population Error',
        'Failed to pre-populate form with AI data. Please enter manually.',
      );

      // Ensure at least one medication exists even on error
      if (medications.isEmpty) {
        addMedication();
      }
    }
  }

  /// Clear fields specifically for OCR pre-population (more gentle than full clear)
  void _clearAllFieldsForOcr() {
    // Don't clear everything, just prepare for OCR data
    // This allows user to maintain some manual entries if needed

    // Clear medications for fresh OCR data
    for (var medication in medications) {
      medication.dispose();
    }
    medications.clear();
  }

  /// Validate OCR pre-populated data and show specific warnings
  bool validateOcrData(PrescriptionOcrData ocrData) {
    final issues = <String>[];

    // Check if essential data is missing
    if (ocrData.doctorName?.isEmpty != false) {
      issues.add('Doctor name not detected - please enter manually');
    }

    if (ocrData.patientName?.isEmpty != false) {
      issues.add('Patient name not detected - please enter manually');
    }

    if (ocrData.medications.isEmpty) {
      issues.add('No medications detected - please add manually');
    }

    // Check for low confidence medications
    final lowConfidenceMeds = ocrData.medications
        .where((med) => med.confidence < 0.6)
        .toList();

    if (lowConfidenceMeds.isNotEmpty) {
      issues.add(
        '${lowConfidenceMeds.length} medication(s) have low confidence - please verify',
      );
    }

    if (issues.isNotEmpty && ocrData.confidenceScore < 0.5) {
      Get.snackbar(
        'OCR Quality Warning',
        'Low quality extraction detected. Please carefully review all fields.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    return true;
  }

  /// Create a comparison view showing original image alongside extracted data
  void showImageComparisonView(PrescriptionOcrData ocrData) {
    Get.dialog(
      Dialog(
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const AppText.heading5('Review Extracted Data'),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    // Original image side
                    Expanded(
                      child: Column(
                        children: [
                          const AppText.heading6('Original Prescription'),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ocrData.originalImagePath.isNotEmpty
                                  ? Image.network(
                                      ocrData.originalImagePath,
                                      fit: BoxFit.contain,
                                    )
                                  : const Center(
                                      child: AppText.bodyMedium(
                                        'Image not available',
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Extracted data side
                    Expanded(
                      child: Column(
                        children: [
                          const AppText.heading6('Extracted Data'),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildExtractedDataView(ocrData),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                      _clearAllFieldsForOcr();
                    },
                    child: const AppText.bodyMedium('Reject & Manual Entry'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      prePopulateFromOcr(ocrData);
                    },
                    child: const AppText.bodyMedium('Accept & Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a widget showing extracted data in a readable format
  Widget _buildExtractedDataView(PrescriptionOcrData ocrData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataSection('Doctor Information', [
          if (ocrData.doctorName != null) 'Name: ${ocrData.doctorName}',
          if (ocrData.doctorSpecialty != null)
            'Specialty: ${ocrData.doctorSpecialty}',
          if (ocrData.clinicName != null) 'Clinic: ${ocrData.clinicName}',
        ]),
        _buildDataSection('Patient Information', [
          if (ocrData.patientName != null) 'Name: ${ocrData.patientName}',
          if (ocrData.patientAge != null) 'Age: ${ocrData.patientAge}',
          if (ocrData.patientGender != null) 'Gender: ${ocrData.patientGender}',
        ]),
        _buildDataSection('Vitals', [
          if (ocrData.bloodPressure != null) 'BP: ${ocrData.bloodPressure}',
          if (ocrData.pulse != null) 'Pulse: ${ocrData.pulse}',
          if (ocrData.temperature != null)
            'Temperature: ${ocrData.temperature}',
          if (ocrData.weight != null) 'Weight: ${ocrData.weight}',
        ]),
        _buildMedicationsSection(ocrData.medications),
      ],
    );
  }

  Widget _buildDataSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading6(title),
        const SizedBox(height: 4),
        ...items.map((item) => AppText.bodyMedium('• $item')),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMedicationsSection(List<OcrMedicationData> medications) {
    if (medications.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.heading6('Medications'),
        const SizedBox(height: 4),
        ...medications.asMap().entries.map((entry) {
          final index = entry.key;
          final med = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: med.confidence < 0.6 ? Colors.orange.shade50 : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge('${index + 1}. ${med.name}'),
                if (med.dosage?.isNotEmpty == true)
                  AppText.bodyMedium('Dosage: ${med.dosage}'),
                if (med.frequency?.isNotEmpty == true)
                  AppText.bodyMedium('Frequency: ${med.frequency}'),
                if (med.duration?.isNotEmpty == true)
                  AppText.bodyMedium('Duration: ${med.duration}'),
                AppText.caption(
                  'Confidence: ${(med.confidence * 100).toStringAsFixed(1)}%',
                  color: med.confidence < 0.6 ? Colors.orange : Colors.green,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
