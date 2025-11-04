// Re-export all API models for convenience
export 'api_response.dart';
export 'api_error.dart';
export 'otp_request_models.dart';
export 'otp_response_models.dart';

// ===== PATIENT AUTHENTICATION MODELS =====

// Patient Registration Request
class PatientRegistrationRequest {
  final String phoneNumber;
  final String email;
  final String firstName;
  final String lastName;
  final String dateOfBirth; // ISO 8601 string
  final String? address;
  final String? nationalIdType;
  final String? nationalIdNumber;

  PatientRegistrationRequest({
    required this.phoneNumber,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.address,
    this.nationalIdType,
    this.nationalIdNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      if (address != null) 'address': address,
      if (nationalIdType != null) 'nationalIdType': nationalIdType,
      if (nationalIdNumber != null) 'nationalIdNumber': nationalIdNumber,
    };
  }
}

// PIN Setup Request
class SetupPinRequest {
  final String pin;

  SetupPinRequest({required this.pin});

  Map<String, dynamic> toJson() {
    return {'pin': pin};
  }
}

// PIN Verification Request
class VerifyPinRequest {
  final String phoneNumber;
  final String pin;

  VerifyPinRequest({required this.phoneNumber, required this.pin});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber, 'pin': pin};
  }
}

// PIN Reset Request
class ResetPinRequest {
  final String newPin;

  ResetPinRequest({required this.newPin});

  Map<String, dynamic> toJson() {
    return {'newPin': newPin};
  }
}

// Patient Registration Response
class PatientRegistrationResponse {
  final String token;
  final PatientInfo patient;

  PatientRegistrationResponse({required this.token, required this.patient});

  factory PatientRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return PatientRegistrationResponse(
      token: json['token'] ?? '',
      patient: PatientInfo.fromJson(json['patient'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'patient': patient.toJson()};
  }
}

// PIN Setup Response
class SetupPinResponse {
  final bool pinSetup;

  SetupPinResponse({required this.pinSetup});

  factory SetupPinResponse.fromJson(Map<String, dynamic> json) {
    return SetupPinResponse(pinSetup: json['pinSetup'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {'pinSetup': pinSetup};
  }
}

// PIN Verification Response
class VerifyPinResponse {
  final String token;
  final PatientInfo patientInfo;

  VerifyPinResponse({required this.token, required this.patientInfo});

  factory VerifyPinResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPinResponse(
      token: json['token'] ?? '',
      patientInfo: PatientInfo.fromJson(json['patientInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'patientInfo': patientInfo.toJson()};
  }
}

// PIN Reset Response
class ResetPinResponse {
  final bool pinReset;

  ResetPinResponse({required this.pinReset});

  factory ResetPinResponse.fromJson(Map<String, dynamic> json) {
    return ResetPinResponse(pinReset: json['pinReset'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {'pinReset': pinReset};
  }
}

// Patient Info Model
class PatientInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? dateOfBirth;
  final String? address;
  final String? lastVisitDate;
  final bool hasPinSetup;

  PatientInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.address,
    this.lastVisitDate,
    this.hasPinSetup = false,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      address: json['address'],
      lastVisitDate: json['lastVisitDate'],
      hasPinSetup: json['hasPinSetup'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (address != null) 'address': address,
      if (lastVisitDate != null) 'lastVisitDate': lastVisitDate,
      'hasPinSetup': hasPinSetup,
    };
  }

  String get fullName => '$firstName $lastName';
}

// Forgot PIN Response
class ForgotPinResponse {
  final String resetToken;
  final int expiresIn; // seconds

  ForgotPinResponse({required this.resetToken, required this.expiresIn});

  factory ForgotPinResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPinResponse(
      resetToken: json['resetToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'resetToken': resetToken, 'expiresIn': expiresIn};
  }
}

// Logout Response
class LogoutResponse {
  final String message;

  LogoutResponse({required this.message});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(message: json['message'] ?? 'Logout successful');
  }

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}

// Enhanced Send OTP Response for patients
class PatientSendOtpResponse extends SendOtpResponse {
  final int expiresIn;

  PatientSendOtpResponse({required super.phoneNumber, required this.expiresIn});

  factory PatientSendOtpResponse.fromJson(Map<String, dynamic> json) {
    return PatientSendOtpResponse(
      phoneNumber: json['phoneNumber'] ?? '',
      expiresIn: json['expiresIn'] ?? 300,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['expiresIn'] = expiresIn;
    return json;
  }
}

// Enhanced Verify OTP Response for patients
class PatientVerifyOtpResponse extends VerifyOtpResponse {
  final PatientInfo patientInfo;
  final bool isNewUser;

  PatientVerifyOtpResponse({
    required super.token,
    required this.patientInfo,
    required this.isNewUser,
  }) : super(
         user: AuthUser(
           phoneNumber: patientInfo.phone,
           name: patientInfo.fullName,
           verified: true,
         ),
       );

  factory PatientVerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return PatientVerifyOtpResponse(
      token: json['token'] ?? '',
      patientInfo: PatientInfo.fromJson(json['patient'] ?? {}),
      isNewUser: json['isNewUser'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['patient'] = patientInfo.toJson();
    json['isNewUser'] = isNewUser;
    return json;
  }
}

// ===== LEGACY OTP MODELS (for backwards compatibility) =====

// OTP Request Models
class SendOtpRequest {
  final String phoneNumber;

  SendOtpRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }
}

class VerifyOtpRequest {
  final String phoneNumber;
  final String otp;
  final String? name;

  VerifyOtpRequest({required this.phoneNumber, required this.otp, this.name});

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'otp': otp,
      if (name != null) 'name': name,
    };
  }
}

class ResendOtpRequest {
  final String phoneNumber;

  ResendOtpRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }
}

// OTP Response Models
class SendOtpResponse {
  final String phoneNumber;

  SendOtpResponse({required this.phoneNumber});

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(phoneNumber: json['phoneNumber'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }
}

class VerifyOtpResponse {
  final String token;
  final AuthUser user;

  VerifyOtpResponse({required this.token, required this.user});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      token: json['token'] ?? '',
      user: AuthUser.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

class AuthUser {
  final String phoneNumber;
  final String name;
  final bool verified;

  AuthUser({
    required this.phoneNumber,
    required this.name,
    required this.verified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'] ?? 'User',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber, 'name': name, 'verified': verified};
  }
}

// Error Response Model
class ApiError {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  ApiError({required this.message, this.statusCode, this.code, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Unknown error occurred',
      statusCode: json['statusCode'],
      code: json['code'],
      details: json['details'],
    );
  }

  factory ApiError.fromDioError(dynamic error) {
    if (error.response != null) {
      final responseData = error.response.data;
      return ApiError(
        message: responseData['message'] ?? 'Request failed',
        statusCode: error.response.statusCode,
        code: responseData['code'],
        details: responseData is Map<String, dynamic> ? responseData : null,
      );
    } else {
      return ApiError(
        message: error.message ?? 'Network error occurred',
        statusCode: null,
        code: 'NETWORK_ERROR',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'code': code,
      'details': details,
    };
  }

  @override
  String toString() {
    return 'ApiError(message: $message, statusCode: $statusCode, code: $code)';
  }
}
