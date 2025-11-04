import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/models/prescription_detail_model.dart';
import '../models/prescription_model.dart';
import '../data/services/api_client.dart';
import '../data/config/app_config.dart';

class PrescriptionManagerService extends GetxService {
  static String get baseUrl => AppConfig.baseUrl;

  ApiClient? _apiClient;

  // Observable lists for UI
  final prescriptions = <PrescriptionModel>[].obs;
  final isLoading = false.obs;
  final lastFetchTime = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    _initializeApiClient();
    loadPrescriptions(); // Load prescriptions when service initializes
  }

  /// Initialize API client safely
  void _initializeApiClient() {
    try {
      _apiClient = Get.find<ApiClient>();
      print('✅ ApiClient initialized successfully');
    } catch (e) {
      print('❌ Error initializing ApiClient: $e');
      _apiClient = null;
    }
  }

  /// Get API client with safety check
  ApiClient get apiClient {
    if (_apiClient == null) {
      _initializeApiClient();
    }

    if (_apiClient == null) {
      throw Exception('ApiClient not initialized. Please restart the app.');
    }

    return _apiClient!;
  }

  /// Get all prescriptions for current user (patient) using JWT authentication
  Future<List<PrescriptionModel>> getAllPrescriptions() async {
    try {
      print('🔍 Getting prescriptions for authenticated user using JWT...');

      final response = await apiClient.get<Map<String, dynamic>>(
        'v1/prescriptions/getMyPrescriptionList',
        (data) => data,
      );

      print('🔍 JWT response success: ${response.success}');
      print('🔍 JWT response message: ${response.message}');

      if (response.success && response.data != null) {
        // Extract prescriptions from the response
        final List<dynamic> prescriptionsData =
            response.data!['prescriptions'] ?? [];

        print('✅ Found ${prescriptionsData.length} prescriptions via JWT');

        // Convert API response to PrescriptionModel format
        final prescriptionsList = prescriptionsData.map((json) {
          // Transform API response to match PrescriptionModel format
          final prescriptionData = {
            'prescription_id': json['prescription_id'],
            'patient_id': json['patient_id'] ?? 0,
            'prescription_raw_url': json['prescription_raw_url'],
            'compiled_prescription_url': json['compiled_prescription_url'],
            'is_active': json['is_active'] ?? 1,
            'created_at': json['created_at'],
            'updated_at': json['updated_at'],
            'created_by': json['created_by'],
            'updated_by': json['updated_by'],
            // Add doctor information if available in the response
            'doctor_name': json['dr_name'], // API returns 'dr_name'
            'doctor_specialization':
                json['dr_specialization'], // API returns 'dr_specialization'
            'appointment_date':
                json['appointment_date'] ??
                json['created_at'], // Use appointment_date or fallback to created_at
            'medicine_count':
                json['medicine_count'], // Add medicine count from API
          };

          return PrescriptionModel.fromJson(prescriptionData);
        }).toList();

        // Remove duplicates based on prescription_id and keep the one with more recent data
        final Map<int, PrescriptionModel> uniquePrescriptions = {};
        for (final prescription in prescriptionsList) {
          final existingPrescription =
              uniquePrescriptions[prescription.prescriptionId];
          if (existingPrescription == null ||
              prescription.updatedAt.isAfter(existingPrescription.updatedAt)) {
            uniquePrescriptions[prescription.prescriptionId] = prescription;
          }
        }

        final finalList = uniquePrescriptions.values.toList();
        print('✅ Returning ${finalList.length} unique prescriptions');
        return finalList;
      } else {
        print('⚠️ API response not successful or no data: ${response.message}');
        // If response exists but no data, check the message for more context
        if (response.message.contains('No prescriptions found') ||
            response.message.contains('empty')) {
          print('📝 API explicitly states no prescriptions found');
          return <PrescriptionModel>[]; // Return empty list - this is expected
        } else {
          print('❌ API returned unsuccessful response: ${response.message}');
          throw Exception('API Error: ${response.message}');
        }
      }
    } catch (e) {
      print('❌ Error getting prescriptions: $e');
      return <PrescriptionModel>[]; // Return empty list on error
    }
  }

  /// Load prescriptions and update observable list
  Future<void> loadPrescriptions() async {
    try {
      isLoading.value = true;
      print('🔄 Loading prescriptions into observable list...');

      final prescriptionsList = await getAllPrescriptions();
      prescriptions.assignAll(prescriptionsList);
      lastFetchTime.value = DateTime.now();

      print(
        '✅ Successfully loaded ${prescriptionsList.length} prescriptions into observable list',
      );
    } catch (e) {
      print('❌ Error loading prescriptions into observable list: $e');
      prescriptions.clear(); // Clear on error
      rethrow; // Re-throw so controllers can handle the error
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh prescriptions (force reload from API)
  Future<void> refreshPrescriptions() async {
    await loadPrescriptions();
  }

  /// Get prescriptions from local observable (for immediate UI updates)
  List<PrescriptionModel> get localPrescriptions => prescriptions.toList();

  /// Check if prescriptions data is fresh (less than 5 minutes old)
  bool get isDataFresh {
    if (lastFetchTime.value == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastFetchTime.value!);
    return difference.inMinutes < 5;
  }

  /// Get detailed prescription information including medicines
  Future<PrescriptionDataDetailModel?> getPrescriptionDetail(
    int prescriptionId,
  ) async {
    try {
      print('🔍 Getting prescription detail for ID: $prescriptionId');

      final response = await apiClient.get<Map<String, dynamic>>(
        'v1/prescriptions/getPrescriptionDetail/$prescriptionId',
        (data) => data,
      );

      print('🔍 Prescription detail response success: ${response.success}');
      print('🔍 Prescription detail response message: ${response.message}');

      if (response.success && response.data != null) {
        final data = response.data!;

        print(
          '✅ Successfully loaded prescription detail with ${(data['medicines'] as List?)?.length ?? 0} medicines',
        );

        // Debug: Print first medicine data if available
        if (data['medicines'] != null &&
            (data['medicines'] as List).isNotEmpty) {
          final firstMedicine = (data['medicines'] as List).first;
          print('📋 First medicine data sample:');
          print('   medicine_name: ${firstMedicine['medicine_name']}');
          print('   med_drug_id: ${firstMedicine['med_drug_id']}');
          print('   composition_1_id: ${firstMedicine['composition_1_id']}');
          print(
            '   composition_1_name: ${firstMedicine['composition_1_name']}',
          );
          print('   composition_2_id: ${firstMedicine['composition_2_id']}');
        }

        // Use the model's fromJson method for safer parsing
        return PrescriptionDataDetailModel.fromJson(data);
      } else {
        print(
          '⚠️ Prescription detail API response not successful: ${response.message}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error getting prescription detail: $e');
      return null;
    }
  }

  Future<Uint8List> downloadPrescriptionPdf(int prescriptionId) async {
    try {
      print('📄 Starting PDF download for prescription ID: $prescriptionId');

      // 1️⃣ Call your Node.js endpoint using GET
      final response = await apiClient.get<Map<String, dynamic>>(
        'v1/download-prescription-pdf/$prescriptionId',
        (data) => data,
      );

      print('📥 PDF API Response status: ${response.success}');
      print('📥 PDF API Message: ${response.message}');

      if (response.success && response.data != null) {
        final data = response.data!;

        // 2️⃣ Extract base64 PDF
        var pdfBase64 = data['pdf_base64'];

        if (pdfBase64 == null) {
          print('⚠️ No pdf_base64 field found in response.');
          throw Exception(
            'PDF data is missing from response. Please try again.',
          );
        }

        // Handle case where backend might return as array instead of string
        if (pdfBase64 is List) {
          print('⚠️ PDF data received as array, converting...');
          // If it's a list of bytes, convert directly
          try {
            final pdfBytes = Uint8List.fromList(pdfBase64.cast<int>());
            print(
              '✅ Successfully converted array to bytes: ${pdfBytes.length} bytes',
            );
            return pdfBytes;
          } catch (e) {
            print('❌ Error converting array to bytes: $e');
            throw Exception(
              'Failed to process PDF data format. Please try again.',
            );
          }
        }

        // Handle normal base64 string
        if (pdfBase64 is! String) {
          print('❌ PDF data is not a string: ${pdfBase64.runtimeType}');
          throw Exception(
            'Invalid PDF data format received. Please try again.',
          );
        }

        if (pdfBase64.isEmpty) {
          print('⚠️ PDF base64 string is empty.');
          throw Exception('PDF data is empty. Please try again.');
        }

        print(
          '📄 PDF base64 preview: ${pdfBase64.substring(0, pdfBase64.length > 50 ? 50 : pdfBase64.length)}...',
        );

        // 3️⃣ Decode base64 to bytes
        try {
          final pdfBytes = base64Decode(pdfBase64);
          print('✅ Successfully decoded PDF: ${pdfBytes.length} bytes');
          return pdfBytes;
        } catch (e) {
          print('❌ Error decoding base64 PDF: $e');
          print('Base64 string length: ${pdfBase64.length}');
          throw Exception('Failed to decode PDF data. Please try again.');
        }
      } else {
        print('⚠️ PDF download failed: ${response.message}');
        throw Exception(response.message);
      }
    } catch (e) {
      print('❌ Error downloading prescription PDF: $e');
      rethrow;
    }
  }
}
