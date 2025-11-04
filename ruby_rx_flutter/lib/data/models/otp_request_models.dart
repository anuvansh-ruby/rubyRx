// OTP Request Models
class SendOtpRequest {
  final String phoneNumber;

  SendOtpRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) {
    return SendOtpRequest(phoneNumber: json['phoneNumber'] ?? '');
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

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) {
    return VerifyOtpRequest(
      phoneNumber: json['phoneNumber'] ?? '',
      otp: json['otp'] ?? '',
      name: json['name'],
    );
  }
}

class ResendOtpRequest {
  final String phoneNumber;

  ResendOtpRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }

  factory ResendOtpRequest.fromJson(Map<String, dynamic> json) {
    return ResendOtpRequest(phoneNumber: json['phoneNumber'] ?? '');
  }
}
