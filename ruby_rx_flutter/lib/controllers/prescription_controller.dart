import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prescription_model.dart';
import '../services/prescription_manager_service.dart';
import '../utils/platform_file_helper.dart';

class PrescriptionController extends GetxController {
  // Observable lists
  final filteredPrescriptions = <PrescriptionModel>[].obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'All'.obs;

  // Filter options
  final filterOptions = ['All', 'Compiled', 'Draft', 'New'];

  // Service
  late final PrescriptionManagerService _prescriptionService;

  // Computed properties
  RxList<PrescriptionModel> get prescriptions =>
      _prescriptionService.prescriptions;
  RxBool get isLoading => _prescriptionService.isLoading;

  @override
  void onInit() {
    super.onInit();

    // Get the existing service instance
    try {
      _prescriptionService = Get.find<PrescriptionManagerService>();
      print('✅ Found existing PrescriptionManagerService');
    } catch (e) {
      print(
        '❌ PrescriptionManagerService not found, creating new instance: $e',
      );
      _prescriptionService = Get.put(PrescriptionManagerService());
    }

    // Initialize filtered prescriptions with current data
    _filterPrescriptions();

    // Listen to prescription changes from service
    ever(prescriptions, (_) => _filterPrescriptions());

    // Check if we came from manual entry with a success message
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final showSuccessMessage = arguments['show_success_message'] ?? false;

      if (showSuccessMessage) {
        // Show success message after a delay to ensure UI is loaded
        Future.delayed(const Duration(milliseconds: 1500), () {
          Get.snackbar(
            'Prescription Saved!',
            'Your prescription has been saved successfully and is now available in your prescription history.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(8),
            borderRadius: 8,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        });
      }
    }

    // Listen to search query changes
    debounce(
      searchQuery,
      (_) => _filterPrescriptions(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onReady() {
    super.onReady();
    // Always load prescriptions when view is ready
    // This ensures fresh data every time user navigates to this page
    print('🔄 PrescriptionController ready - loading prescriptions...');
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    try {
      print('🔄 Loading prescriptions via service...');

      // Use the service's load method
      await _prescriptionService.loadPrescriptions();

      // Filter prescriptions after loading
      _filterPrescriptions();

      print(
        '✅ Successfully loaded ${prescriptions.length} prescriptions via controller',
      );

      // Only show message if no prescriptions found (optional)
      if (prescriptions.isEmpty) {
        print('⚠️ No prescriptions found via controller');
      }
    } catch (e) {
      print('❌ Error loading prescriptions via controller: $e');
      Get.snackbar(
        'Error',
        'Failed to load prescriptions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      // Ensure filtered list is updated even on error
      _filterPrescriptions();
    }
  }

  void searchPrescriptions(String query) {
    searchQuery.value = query;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    _filterPrescriptions();
  }

  void _filterPrescriptions() {
    var filtered = prescriptions.where((prescription) {
      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        final searchLower = searchQuery.value.toLowerCase();
        final matchesSearch =
            prescription.prescriptionId.toString().contains(searchLower) ||
            prescription.formattedDate.toLowerCase().contains(searchLower) ||
            prescription.status.toLowerCase().contains(searchLower) ||
            (prescription.doctorName?.toLowerCase().contains(searchLower) ??
                false) ||
            (prescription.doctorSpecialization?.toLowerCase().contains(
                  searchLower,
                ) ??
                false);
        if (!matchesSearch) return false;
      }

      // Apply status filter
      if (selectedFilter.value != 'All') {
        if (prescription.status != selectedFilter.value) return false;
      }

      return true;
    }).toList();

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    filteredPrescriptions.assignAll(filtered);

    print(
      '🔍 Filtered ${filtered.length} prescriptions from ${prescriptions.length} total (search: "${searchQuery.value}", filter: "${selectedFilter.value}")',
    );
  }

  Future<void> refreshPrescriptions() async {
    await _prescriptionService.refreshPrescriptions();
    _filterPrescriptions();
  }

  void viewPrescription(PrescriptionModel prescription) {
    Get.toNamed('/prescription-detail', arguments: prescription);
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

  void sharePrescription(PrescriptionModel prescription) {
    // TODO: Implement share functionality
    Get.snackbar(
      'Share',
      'Share functionality will be implemented soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  void navigateBack() {
    Get.back();
  }

  void createNewPrescription() {
    Get.toNamed('/manual-entry');
  }
}
