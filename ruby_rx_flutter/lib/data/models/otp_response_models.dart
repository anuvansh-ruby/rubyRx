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

// New Patient OTP Verify Response to handle auto-registration
class PatientVerifyOtpResponse {
  final String token;
  final bool isNewUser;
  final PatientInfo patientInfo;

  PatientVerifyOtpResponse({
    required this.token,
    required this.isNewUser,
    required this.patientInfo,
  });

  factory PatientVerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return PatientVerifyOtpResponse(
      token: json['token'] ?? '',
      isNewUser: json['isNewUser'] ?? false,
      patientInfo: PatientInfo.fromJson(json['patient'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'isNewUser': isNewUser,
      'patient': patientInfo.toJson(),
    };
  }
}

// Patient Information Model
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
