import '../api/profile_api_service.dart';
import '../models/api_models.dart';
import '../services/hive_storage_service.dart';
import '../../models/user_model.dart';

class ProfileRepository {
  final ProfileApiService _profileApiService = ProfileApiService();

  /// Update patient profile and sync with local storage
  Future<ApiResponse<PatientInfo>> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
    String? address,
    String? nationalIdType,
    String? nationalIdNumber,
  }) async {
    try {
      final response = await _profileApiService.updatePatientProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
        address: address,
        nationalIdType: nationalIdType,
        nationalIdNumber: nationalIdNumber,
      );

      // If successful, update local storage with new patient data
      if (response.isSuccess && response.data != null) {
        await _storePatientData(response.data!);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Store patient data in local storage
  Future<void> _storePatientData(PatientInfo patient) async {
    final userModel = UserModel.fromPatientInfo(
      patient,
      token: await HiveStorageService.getAuthToken(),
      hasPinSetup: await HiveStorageService.getPinSetupStatus(),
    );

    await HiveStorageService.setUserData(userModel.toJson());
  }
}
