import '../data/models/api_models.dart';

class UserModel {
  final int? id;
  final String? email;
  final String? phone;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? address;
  final String? lastVisitDate;
  final bool isLoggedIn;
  final bool hasPinSetup;
  final String? profileImage;
  final String? token;

  UserModel({
    this.id,
    this.email,
    this.phone,
    this.name,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.address,
    this.lastVisitDate,
    this.isLoggedIn = false,
    this.hasPinSetup = false,
    this.profileImage,
    this.token,
  });

  // Factory constructor for creating UserModel from PatientInfo
  factory UserModel.fromPatientInfo(
    PatientInfo patient, {
    String? token,
    bool? hasPinSetup,
  }) {
    return UserModel(
      id: patient.id,
      email: patient.email,
      phone: patient.phone,
      firstName: patient.firstName,
      lastName: patient.lastName,
      name: patient.fullName,
      dateOfBirth: patient.dateOfBirth,
      address: patient.address,
      lastVisitDate: patient.lastVisitDate,
      isLoggedIn: true,
      hasPinSetup: hasPinSetup ?? patient.hasPinSetup,
      token: token,
    );
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? phone,
    String? name,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? address,
    String? lastVisitDate,
    bool? isLoggedIn,
    bool? hasPinSetup,
    String? profileImage,
    String? token,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      hasPinSetup: hasPinSetup ?? this.hasPinSetup,
      profileImage: profileImage ?? this.profileImage,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'lastVisitDate': lastVisitDate,
      'isLoggedIn': isLoggedIn,
      'hasPinSetup': hasPinSetup,
      'profileImage': profileImage,
      'token': token,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      name: json['name'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: json['dateOfBirth'],
      address: json['address'],
      lastVisitDate: json['lastVisitDate'],
      isLoggedIn: json['isLoggedIn'] ?? false,
      hasPinSetup: json['hasPinSetup'] ?? false,
      profileImage: json['profileImage'],
      token: json['token'],
    );
  }

  // Computed properties
  String get displayName => name ?? '$firstName $lastName'.trim();

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    } else if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return name![0].toUpperCase();
      }
    }
    return 'U';
  }

  bool get hasValidProfile {
    return firstName != null &&
        lastName != null &&
        email != null &&
        phone != null;
  }
}
