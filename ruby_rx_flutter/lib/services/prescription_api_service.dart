import 'dart:async';
import 'package:get/get.dart';
import '../models/prescription_models.dart';
import '../data/services/api_client.dart';
import '../data/config/app_config.dart';

class PrescriptionApiService extends GetxService {
  static String get baseUrl => AppConfig.baseUrl;

  ApiClient? _apiClient;

  @override
  void onInit() {
    super.onInit();
    _initializeApiClient();
  }

  /// Initialize API client safely
  void _initializeApiClient() {
    try {
      _apiClient = Get.find<ApiClient>();
      print('✅ PrescriptionApi ApiClient initialized successfully');
    } catch (e) {
      print('❌ Error initializing PrescriptionApi ApiClient: $e');
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

  /// Create a new prescription using name-based data with current patient ID to prevent patient creation
  Future<PrescriptionResponse> createPrescriptionByNameWithPatientId({
    required CreatePrescriptionByNameRequest prescriptionData,
    int? currentPatientId,
  }) async {
    try {
      print('🏥 ===============================================');
      print('🏥 PRESCRIPTION API SERVICE - CREATE BY NAME');
      print('🏥 ===============================================');
      print('📤 Creating prescription by name with existing patient...');
      print('👤 Current Patient ID: $currentPatientId');

      // Create a modified JSON payload that includes current patient ID
      final jsonPayload = prescriptionData.toJson();

      // Add current patient ID to prevent new patient creation
      if (currentPatientId != null) {
        jsonPayload['current_patient_id'] = currentPatientId;
        jsonPayload['use_existing_patient'] = true;
        print('👤 Added current_patient_id to request: $currentPatientId');
      }

      print('📋 Full request payload:');
      print('   - Doctor: ${jsonPayload['doctor_name']}');
      print('   - Patient: ${jsonPayload['patient_name']}');
      print('   - Medicines: ${(jsonPayload['medicines'] as List).length}');
      print('   - Current Patient ID: ${jsonPayload['current_patient_id']}');
      print(
        '   - Use Existing Patient: ${jsonPayload['use_existing_patient']}',
      );

      final response = await apiClient.post<Map<String, dynamic>>(
        'v1/prescriptions/createPrescription',
        (data) => data,
        body: jsonPayload,
        requireAuth: true, // Explicitly require authentication
      );

      print('📥 API Response received:');
      print('   - Success: ${response.success}');
      print('   - Message: ${response.message}');
      print('   - Data: ${response.data}');
      print('   - Error: ${response.error}');

      // Handle response (by-name endpoint)
      if (response.success) {
        print('✅ Prescription created successfully with existing patient!');

        final prescriptionResponse = PrescriptionResponse.fromJson({
          'success': true,
          'message': response.message,
        });

        print('📋 Processed response data:');
        print(
          '   - Prescription ID: ${prescriptionResponse.data?.prescriptionId}',
        );
        print(
          '   - Appointment ID: ${prescriptionResponse.data?.appointmentId}',
        );

        return prescriptionResponse;
      } else {
        print('❌ API Error: ${response.message}');
        return PrescriptionResponse(
          success: false,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      print('💥 Exception in createPrescriptionByNameWithPatientId: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      return PrescriptionResponse(
        success: false,
        message: 'Error creating prescription: ${e.toString()}',
        data: null,
      );
    } finally {
      print('🏥 ===============================================');
    }
  }
}

// Service initialization
class PrescriptionApiBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PrescriptionApiService>(PrescriptionApiService());
  }
}
