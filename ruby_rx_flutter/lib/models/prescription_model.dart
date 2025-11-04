class DoctorModel {
  final int doctorId;
  final String doctorName;
  final String doctorEmail;
  final String? doctorSpecialization;
  final String? doctorDesignation;
  final String doctorPhoneNumber;

  const DoctorModel({
    required this.doctorId,
    required this.doctorName,
    required this.doctorEmail,
    this.doctorSpecialization,
    this.doctorDesignation,
    required this.doctorPhoneNumber,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      doctorId: json['dr_id'],
      doctorName: json['dr_name'],
      doctorEmail: json['dr_email'],
      doctorSpecialization: json['dr_specialization'],
      doctorDesignation: json['dr_highest_designation'],
      doctorPhoneNumber: json['dr_phone_number'],
    );
  }
}

// class PrescriptionDetailModel {
//   final PrescriptionModel prescription;
//   final DoctorModel? doctor;
//   final List<PatientMedicineModel> medicines;
//   final String? patientName;
//   final int? patientAge;
//   final String? patientGender;
//   final double? patientWeight;
//   final String? vitals;
//   final String? diagnosis;

//   const PrescriptionDetailModel({
//     required this.prescription,
//     this.doctor,
//     this.medicines = const [],
//     this.patientName,
//     this.patientAge,
//     this.patientGender,
//     this.patientWeight,
//     this.vitals,
//     this.diagnosis,
//   });
// }

class PrescriptionModel {
  final int prescriptionId;
  final int patientId;
  final String? prescriptionRawUrl;
  final String? compiledPrescriptionUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? updatedBy;

  // Additional fields for prescription list display
  final String? doctorName;
  final String? doctorSpecialization;
  final DateTime? appointmentDate;
  final int? medicineCount;

  const PrescriptionModel({
    required this.prescriptionId,
    required this.patientId,
    this.prescriptionRawUrl,
    this.compiledPrescriptionUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.doctorName,
    this.doctorSpecialization,
    this.appointmentDate,
    this.medicineCount,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      prescriptionId: json['prescription_id'],
      patientId: json['patient_id'] ?? 0, // Default to 0 if not provided
      prescriptionRawUrl: json['prescription_raw_url'],
      compiledPrescriptionUrl: json['compiled_prescription_url'],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      doctorName: json['doctor_name'],
      doctorSpecialization: json['doctor_specialization'],
      appointmentDate: json['appointment_date'] != null
          ? DateTime.parse(json['appointment_date'])
          : null,
      medicineCount: json['medicine_count'] != null
          ? int.tryParse(json['medicine_count'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prescription_id': prescriptionId,
      'patient_id': patientId,
      'prescription_raw_url': prescriptionRawUrl,
      'compiled_prescription_url': compiledPrescriptionUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'doctor_name': doctorName,
      'doctor_specialization': doctorSpecialization,
      'appointment_date': appointmentDate?.toIso8601String(),
      'medicine_count': medicineCount,
    };
  }

  // Helper method to get prescription status
  String get status {
    if (compiledPrescriptionUrl != null &&
        compiledPrescriptionUrl!.isNotEmpty) {
      return 'Compiled';
    } else if (prescriptionRawUrl != null && prescriptionRawUrl!.isNotEmpty) {
      return 'Draft';
    }
    return 'New';
  }

  // Helper method to get display date
  String get formattedDate {
    final dateToFormat = appointmentDate ?? createdAt;
    final now = DateTime.now();
    final difference = now.difference(dateToFormat).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${dateToFormat.day}/${dateToFormat.month}/${dateToFormat.year}';
    }
  }

  // Helper method to get visit date (different from creation date)
  String get visitDate {
    final dateToFormat = appointmentDate ?? createdAt;
    return '${dateToFormat.day}/${dateToFormat.month}/${dateToFormat.year}';
  }

  // Helper method to get doctor display name
  String get displayDoctorName {
    return doctorName ?? 'Dr. Unknown';
  }
}

class PatientMedicineModel {
  final int medicineId;
  final int prescriptionId;
  final String medicineName;
  final String? medicineSalt;
  final String? medicineFrequency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? updatedBy;

  const PatientMedicineModel({
    required this.medicineId,
    required this.prescriptionId,
    required this.medicineName,
    this.medicineSalt,
    this.medicineFrequency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory PatientMedicineModel.fromJson(Map<String, dynamic> json) {
    return PatientMedicineModel(
      medicineId: json['medicin_id'], // Note: DB has typo 'medicin_id'
      prescriptionId: json['prescription_id'],
      medicineName: json['medicine_name'],
      medicineSalt: json['medicine_salt'],
      medicineFrequency: json['medicine_frequency'],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicin_id': medicineId, // Note: DB has typo 'medicin_id'
      'prescription_id': prescriptionId,
      'medicine_name': medicineName,
      'medicine_salt': medicineSalt,
      'medicine_frequency': medicineFrequency,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}
