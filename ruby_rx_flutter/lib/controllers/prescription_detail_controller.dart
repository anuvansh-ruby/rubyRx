import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/models/prescription_detail_model.dart';
import '../models/prescription_model.dart';
import '../services/prescription_manager_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/platform_file_helper.dart';
import '../services/medicine_substitute_service.dart';

class PrescriptionDetailController extends GetxController {
  // Observable variables
  final prescriptionDetail = Rxn<PrescriptionDataDetailModel>();
  final isLoading = false.obs;

  // Service
  late final PrescriptionManagerService _prescriptionService;

  // Prescription from arguments
  PrescriptionModel? prescription;

  @override
  void onInit() {
    super.onInit();

    // Initialize service
    _prescriptionService = Get.find<PrescriptionManagerService>();

    // Get prescription from arguments if available
    final args = Get.arguments;
    if (args != null && args is PrescriptionModel) {
      prescription = args;
      // Load prescription details automatically
      loadPrescriptionDetail();
    }
  }

  Future<void> loadPrescriptionDetail() async {
    if (prescription == null) {
      print('❌ No prescription available to load details');
      return;
    }

    try {
      isLoading.value = true;

      // Load prescription details from API
      final detail = await _prescriptionService.getPrescriptionDetail(
        prescription!.prescriptionId,
      );

      prescriptionDetail.value = detail;

      print(
        '✅ Loaded prescription details for ID: ${prescription!.prescriptionId}',
      );
    } catch (e) {
      print('❌ Error loading prescription details: $e');
      Get.snackbar(
        'Error',
        'Failed to load prescription details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Alternative method to load prescription details by ID (for manual loading)
  Future<void> loadPrescriptionDetails(int prescriptionId) async {
    try {
      isLoading.value = true;

      // Load prescription details from API
      final detail = await _prescriptionService.getPrescriptionDetail(
        prescriptionId,
      );

      prescriptionDetail.value = detail;

      print('✅ Loaded prescription details for ID: $prescriptionId');
    } catch (e) {
      print('❌ Error loading prescription details: $e');
      Get.snackbar(
        'Error',
        'Failed to load prescription details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadPrescriptionPdf({required int prescriptionId}) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      print('📥 Starting PDF download for prescription #$prescriptionId');

      // 1️⃣ Call the API
      final pdfBytes = await _prescriptionService.downloadPrescriptionPdf(
        prescriptionId,
      );

      // 2️⃣ Check if PDF bytes are empty
      if (pdfBytes.isEmpty) {
        throw Exception('Failed to download PDF - empty response');
      }

      print(
        '✅ Received PDF data: ${PlatformFileHelper.formatFileSize(pdfBytes.length)}',
      );

      // Validate PDF data
      final validationError = PlatformFileHelper.validatePdfData(pdfBytes);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // 3️⃣ Save PDF to device storage
      final dir = await getApplicationDocumentsDirectory();
      final fileName = PlatformFileHelper.getSafePdfFileName(prescriptionId);
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('✅ PDF saved to: $filePath');

      // Close loading dialog
      Get.back();

      // 4️⃣ Open PDF with native viewer
      final result = await OpenFilex.open(file.path);

      print('📄 PDF open result: ${result.type} - ${result.message}');

      // Show success message
      if (result.type == ResultType.done) {
        Get.snackbar(
          'Success',
          'Prescription PDF downloaded successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.white),
          margin: const EdgeInsets.all(8),
        );
      } else if (result.type == ResultType.noAppToOpen) {
        Get.snackbar(
          'Info',
          'PDF saved at: $filePath\nNo app found to open PDF files.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.info, color: Colors.white),
          margin: const EdgeInsets.all(8),
        );
      }

      print('✅ PDF downloaded and opened successfully');
    } catch (e) {
      // Close loading dialog if open
      try {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (backError) {
        print('⚠️ Error closing dialog: $backError');
      }

      print('❌ Error downloading PDF: $e');

      // Use Future.delayed to ensure the dialog is closed before showing snackbar
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(
          'Error',
          'Failed to download PDF: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.error, color: Colors.white),
          margin: const EdgeInsets.all(8),
        );
      });
    }
  }

  void sharePrescription() {
    // TODO: Implement share functionality
    Get.snackbar(
      'Share',
      'Share functionality will be implemented soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  /// Load medicine substitutes based on composition IDs
  Future<List<MedicineSubstituteModel>> loadMedicineSubstitutes({
    required String compositionId1,
    String? compositionId2,
    int? excludeMedId,
  }) async {
    try {
      print(
        '🔍 Loading substitutes for composition: $compositionId1${compositionId2 != null ? ' + $compositionId2' : ''}',
      );

      final substitutes =
          await MedicineSubstituteService.getMedicineSubstitutes(
            compositionId1: compositionId1,
            compositionId2: compositionId2,
            excludeMedId: excludeMedId,
            sortBy:
                'price', // Sort by price to show cheapest alternatives first
            limit: 20,
          );

      print('✅ Found ${substitutes.length} substitute medicines');

      return substitutes;
    } catch (e) {
      print('❌ Error loading medicine substitutes: $e');
      return [];
    }
  }

  void navigateBack() {
    Get.back();
  }
}
