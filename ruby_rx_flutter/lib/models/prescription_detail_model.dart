class PrescriptionDataDetailModel {
  final PrescriptionModelData prescription;
  final DoctorModelData? doctor;
  final List<PatientMedicineModelData> medicines;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final double? patientWeight;
  final String? vitals;
  final String? diagnosis;
  final String? patientBloodPressure;
  final String? patientPulse;
  final String? patientTemperature;
  final String? patientHeight;

  const PrescriptionDataDetailModel({
    required this.prescription,
    this.doctor,
    this.medicines = const [],
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.patientWeight,
    this.vitals,
    this.diagnosis,
    this.patientBloodPressure,
    this.patientPulse,
    this.patientTemperature,
    this.patientHeight,
  });

  factory PrescriptionDataDetailModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionDataDetailModel(
      prescription: PrescriptionModelData.fromJson(json),
      doctor: json['doctor'] != null
          ? DoctorModelData.fromJson(json['doctor'])
          : null,
      medicines:
          (json['medicines'] as List<dynamic>?)
              ?.map((e) => PatientMedicineModelData.fromJson(e))
              .toList() ??
          [],
      patientName: json['patient_name'],
      patientAge: json['patient_age'],
      patientGender: json['patient_gender'],
      patientWeight:
          json['patient_weight'] != null &&
              json['patient_weight'].toString().isNotEmpty
          ? double.tryParse(json['patient_weight'].toString())
          : null,
      vitals: json['vitals'],
      diagnosis: json['diagnosis'],
      patientBloodPressure: json['patient_blood_pressure'],
      patientPulse: json['patient_pulse'],
      patientTemperature:
          json['patient_temperature'] ?? json['patient_temprature'],
      patientHeight: json['patient_height'],
    );
  }
}

class PrescriptionModelData {
  final int prescriptionId;
  final int patientId;
  final String? prescriptionRawUrl;
  final String? compiledPrescriptionUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? appointmentDate;

  const PrescriptionModelData({
    required this.prescriptionId,
    required this.patientId,
    this.prescriptionRawUrl,
    this.compiledPrescriptionUrl,
    required this.createdAt,
    required this.updatedAt,
    this.appointmentDate,
  });

  factory PrescriptionModelData.fromJson(Map<String, dynamic> json) {
    return PrescriptionModelData(
      prescriptionId: json['prescription_id'],
      patientId: json['patient_id'],
      prescriptionRawUrl: json['prescription_raw_url'],
      compiledPrescriptionUrl: json['compiled_prescription_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      appointmentDate: json['appointment_date'] != null
          ? DateTime.tryParse(json['appointment_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prescription_id': prescriptionId,
      'patient_id': patientId,
      'prescription_raw_url': prescriptionRawUrl,
      'compiled_prescription_url': compiledPrescriptionUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'appointment_date': appointmentDate?.toIso8601String(),
    };
  }
}

class PatientMedicineModelData {
  final int medicineId;
  final String medicineName;
  final String? medicineSalt;
  final String? medicineFrequency;
  final int? medDrugId;
  final String? duration;
  final String? notes;
  final String? composition1Id;
  final String? composition1Name;
  final String? composition1Dose;
  final String? composition2Id;
  final String? composition2Name;
  final String? composition2Dose;

  const PatientMedicineModelData({
    required this.medicineId,
    required this.medicineName,
    this.medicineSalt,
    this.medicineFrequency,
    this.medDrugId,
    this.duration,
    this.notes,
    this.composition1Id,
    this.composition1Name,
    this.composition1Dose,
    this.composition2Id,
    this.composition2Name,
    this.composition2Dose,
  });

  factory PatientMedicineModelData.fromJson(Map<String, dynamic> json) {
    return PatientMedicineModelData(
      medicineId: json['medicine_id'],
      medicineName: json['medicine_name'],
      medicineSalt: json['medicine_salt'],
      medicineFrequency: json['medicine_frequency'],
      medDrugId: json['med_drug_id'],
      duration: json['duration'],
      notes: json['notes'] ?? json['instructions'],
      composition1Id: json['composition_1_id']?.toString(),
      composition1Name: json['composition_1_name'],
      composition1Dose: json['composition_1_dose'],
      composition2Id: json['composition_2_id']?.toString(),
      composition2Name: json['composition_2_name'],
      composition2Dose: json['composition_2_dose'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'medicine_salt': medicineSalt,
      'medicine_frequency': medicineFrequency,
      'med_drug_id': medDrugId,
      'duration': duration,
      'notes': notes,
      'composition_1_id': composition1Id,
      'composition_1_name': composition1Name,
      'composition_1_dose': composition1Dose,
      'composition_2_id': composition2Id,
      'composition_2_name': composition2Name,
      'composition_2_dose': composition2Dose,
    };
  }

  /// Get formatted composition string for display
  String get compositionInfo {
    final compositions = <String>[];

    if (composition1Name != null && composition1Name!.isNotEmpty) {
      String comp = composition1Name!;
      if (composition1Dose != null && composition1Dose!.isNotEmpty) {
        comp += ' ${composition1Dose!}';
      }
      compositions.add(comp);
    }

    if (composition2Name != null && composition2Name!.isNotEmpty) {
      String comp = composition2Name!;
      if (composition2Dose != null && composition2Dose!.isNotEmpty) {
        comp += ' ${composition2Dose!}';
      }
      compositions.add(comp);
    }

    return compositions.isNotEmpty ? compositions.join(' + ') : '';
  }
}

class DoctorModelData {
  final int doctorId;
  final String doctorName;
  final String doctorEmail;
  final String doctorPhoneNumber;
  final String? doctorSpecialization;
  final String? doctorDesignation;
  final String? doctorLicenseId;
  final String? doctorCity;
  final String? doctorState;
  final String? doctorCountry;

  const DoctorModelData({
    required this.doctorId,
    required this.doctorName,
    required this.doctorEmail,
    required this.doctorPhoneNumber,
    this.doctorSpecialization,
    this.doctorDesignation,
    this.doctorLicenseId,
    this.doctorCity,
    this.doctorState,
    this.doctorCountry,
  });

  factory DoctorModelData.fromJson(Map<String, dynamic> json) {
    return DoctorModelData(
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      doctorEmail: json['doctor_email'],
      doctorPhoneNumber: json['doctor_phone_number'],
      doctorSpecialization: json['doctor_specialization'],
      doctorDesignation: json['doctor_designation'],
      doctorLicenseId: json['doctor_license_id'],
      doctorCity: json['doctor_city'],
      doctorState: json['doctor_state'],
      doctorCountry: json['doctor_country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_email': doctorEmail,
      'doctor_phone_number': doctorPhoneNumber,
      'doctor_specialization': doctorSpecialization,
      'doctor_designation': doctorDesignation,
      'doctor_license_id': doctorLicenseId,
      'doctor_city': doctorCity,
      'doctor_state': doctorState,
      'doctor_country': doctorCountry,
    };
  }
}
