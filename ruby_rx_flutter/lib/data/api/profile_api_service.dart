import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/api_models.dart';

class ProfileApiService {
  final Dio _dio = ApiClient.instance.dio;

  /// Update patient profile information
  /// Endpoint: PUT /v1/patient/profile
  /// Requires JWT authentication
  Future<ApiResponse<PatientInfo>> updatePatientProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
    String? address,
    String? nationalIdType,
    String? nationalIdNumber,
  }) async {
    try {
      final response = await _dio.put(
        '/v1/patient/profile',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'dateOfBirth': dateOfBirth,
          'address': address,
          'nationalIdType': nationalIdType,
          'nationalIdNumber': nationalIdNumber,
        },
      );

      return ApiResponse.fromJson(response.data, (data) {
        // Extract patient data from response
        final patientData = data['patient'];
        return PatientInfo(
          id: patientData['id'],
          firstName: patientData['firstName'],
          lastName: patientData['lastName'],
          email: patientData['email'],
          phone: patientData['phone'],
          dateOfBirth: patientData['dateOfBirth'],
          address: patientData['address'],
          lastVisitDate: patientData['lastVisitDate'],
          hasPinSetup: true, // User already has PIN if they can update profile
        );
      });
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }
}
