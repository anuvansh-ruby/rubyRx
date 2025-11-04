// Self-Service Prescription Models for Ruby RX
// Based on new database schema where logged-in users create prescriptions for themselves
// Updated: October 12, 2025

// Self-service prescription creation request (user creates prescription for themselves)
class CreateSelfServicePrescriptionRequest {
  // Doctor information (required - will be created/found)
  final String doctorName;
  final String? doctorSpecialty;
  final String? doctorLicenseNumber;
  final String? doctorEmail;
  final String? doctorPhone;
  final String? clinicName;

  // Patient vitals (stored directly in prescription table)
  final String? patientBloodPressure;
  final String? patientPulse;
  final String? patientTemperature;
  final String? patientWeight;
  final String? patientHeight;

  // Prescription metadata
  final String? prescriptionDate;
  final String? diagnosis;
  final String? medicalConditions;
  final String? additionalNotes;
  final String? appointmentSummary;
  final String? appointmentTranscription;

  // Medications (required)
  final List<CreateSelfServiceMedicineRequest> medicines;

  CreateSelfServicePrescriptionRequest({
    required this.doctorName,
    this.doctorSpecialty,
    this.doctorLicenseNumber,
    this.doctorEmail,
    this.doctorPhone,
    this.clinicName,
    this.patientBloodPressure,
    this.patientPulse,
    this.patientTemperature,
    this.patientWeight,
    this.patientHeight,
    this.prescriptionDate,
    this.diagnosis,
    this.medicalConditions,
    this.additionalNotes,
    this.appointmentSummary,
    this.appointmentTranscription,
    required this.medicines,
  });

  Map<String, dynamic> toJson() {
    return {
      // Doctor information
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
      'doctor_license_number': doctorLicenseNumber,
      'doctor_email': doctorEmail,
      'doctor_phone': doctorPhone,
      'clinic_name': clinicName,

      // Patient vitals
      'patient_blood_pressure': patientBloodPressure,
      'patient_pulse': patientPulse,
      'patient_temperature': patientTemperature,
      'patient_weight': patientWeight,
      'patient_height': patientHeight,

      // Prescription metadata
      'prescription_date': prescriptionDate,
      'diagnosis': diagnosis,
      'medical_conditions': medicalConditions,
      'additional_notes': additionalNotes,
      'appointment_summary': appointmentSummary,
      'appointment_transcription': appointmentTranscription,

      // Medications
      'medicines': medicines.map((m) => m.toJson()).toList(),
    };
  }
}

class CreateSelfServiceMedicineRequest {
  final String medicineName;
  final String? medicineFrequency;
  final String? medicineSalt;
  final String? medicineGenericName;
  final String? medicineDosage;
  final String? medicineDuration;
  final String? medicineInstructions;
  final int? medDrugId; // Anuvansh medicine database ID

  CreateSelfServiceMedicineRequest({
    required this.medicineName,
    this.medicineFrequency,
    this.medicineSalt,
    this.medicineGenericName,
    this.medicineDosage,
    this.medicineDuration,
    this.medicineInstructions,
    this.medDrugId,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicine_name': medicineName,
      'medicine_frequency': medicineFrequency,
      'medicine_salt': medicineSalt,
      'generic_name': medicineGenericName,
      'dosage': medicineDosage,
      'duration': medicineDuration,
      'instructions': medicineInstructions,
      'med_drug_id': medDrugId,
    };
  }
}

// Enhanced prescription response for self-service flow
class SelfServicePrescriptionResponse {
  final bool success;
  final String message;
  final SelfServicePrescriptionData? data;
  final String? error;

  SelfServicePrescriptionResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory SelfServicePrescriptionResponse.fromJson(Map<String, dynamic> json) {
    return SelfServicePrescriptionResponse(
      success: json['status'] == 'SUCCESS',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SelfServicePrescriptionData.fromJson(json['data'])
          : null,
      error: json['error'],
    );
  }
}

class SelfServicePrescriptionData {
  final int prescriptionId;
  final int doctorId;
  final int patientId;
  final List<int> medicineIds;
  final int medicinesCount;
  final List<CreatedMedicine> medicinesCreated;
  final EntitiesCreated entitiesCreated;

  SelfServicePrescriptionData({
    required this.prescriptionId,
    required this.doctorId,
    required this.patientId,
    required this.medicineIds,
    required this.medicinesCount,
    required this.medicinesCreated,
    required this.entitiesCreated,
  });

  factory SelfServicePrescriptionData.fromJson(Map<String, dynamic> json) {
    return SelfServicePrescriptionData(
      prescriptionId: json['prescription_id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      medicineIds: List<int>.from(json['medicine_ids'] ?? []),
      medicinesCount: json['medicines_count'] ?? 0,
      medicinesCreated:
          (json['medicines_created'] as List<dynamic>?)
              ?.map((m) => CreatedMedicine.fromJson(m))
              .toList() ??
          [],
      entitiesCreated: EntitiesCreated.fromJson(json['entities_created'] ?? {}),
    );
  }
}

class CreatedMedicine {
  final int id;
  final String name;
  final String? frequency;
  final String? salt;
  final int? medDrugId;
  final bool anuvanshLinked;

  CreatedMedicine({
    required this.id,
    required this.name,
    this.frequency,
    this.salt,
    this.medDrugId,
    this.anuvanshLinked = false,
  });

  factory CreatedMedicine.fromJson(Map<String, dynamic> json) {
    return CreatedMedicine(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      frequency: json['frequency'],
      salt: json['salt'],
      medDrugId: json['med_drug_id'],
      anuvanshLinked: json['anuvansh_linked'] ?? false,
    );
  }
}

class EntitiesCreated {
  final CreatedDoctor doctor;
  final CreatedPatient patient;
  final CreatedPrescription prescription;

  EntitiesCreated({
    required this.doctor,
    required this.patient,
    required this.prescription,
  });

  factory EntitiesCreated.fromJson(Map<String, dynamic> json) {
    return EntitiesCreated(
      doctor: CreatedDoctor.fromJson(json['doctor'] ?? {}),
      patient: CreatedPatient.fromJson(json['patient'] ?? {}),
      prescription: CreatedPrescription.fromJson(json['prescription'] ?? {}),
    );
  }
}

class CreatedDoctor {
  final int id;
  final String name;
  final String? specialty;

  CreatedDoctor({required this.id, required this.name, this.specialty});

  factory CreatedDoctor.fromJson(Map<String, dynamic> json) {
    return CreatedDoctor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      specialty: json['specialty'],
    );
  }
}

class CreatedPatient {
  final int id;
  final String name;

  CreatedPatient({required this.id, required this.name});

  factory CreatedPatient.fromJson(Map<String, dynamic> json) {
    return CreatedPatient(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class CreatedPrescription {
  final int id;
  final String date;
  final int medicinesCount;
  final PrescriptionVitals vitals;

  CreatedPrescription({
    required this.id,
    required this.date,
    required this.medicinesCount,
    required this.vitals,
  });

  factory CreatedPrescription.fromJson(Map<String, dynamic> json) {
    return CreatedPrescription(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      medicinesCount: json['medicines_count'] ?? 0,
      vitals: PrescriptionVitals.fromJson(json['vitals'] ?? {}),
    );
  }
}

class PrescriptionVitals {
  final String? bloodPressure;
  final String? pulse;
  final String? temperature;
  final String? weight;
  final String? height;

  PrescriptionVitals({
    this.bloodPressure,
    this.pulse,
    this.temperature,
    this.weight,
    this.height,
  });

  factory PrescriptionVitals.fromJson(Map<String, dynamic> json) {
    return PrescriptionVitals(
      bloodPressure: json['blood_pressure'],
      pulse: json['pulse'],
      temperature: json['temperature'],
      weight: json['weight'],
      height: json['height'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blood_pressure': bloodPressure,
      'pulse': pulse,
      'temperature': temperature,
      'weight': weight,
      'height': height,
    };
  }

  bool get hasAnyVitals {
    return bloodPressure != null ||
        pulse != null ||
        temperature != null ||
        weight != null ||
        height != null;
  }
}

// Enhanced prescription details model
class EnhancedPrescriptionDetails {
  final PrescriptionInfo prescription;
  final PrescriptionVitals vitals;
  final DoctorInfo doctor;
  final PatientInfo patient;
  final List<MedicineInfo> medicines;
  final int medicineCount;

  EnhancedPrescriptionDetails({
    required this.prescription,
    required this.vitals,
    required this.doctor,
    required this.patient,
    required this.medicines,
    required this.medicineCount,
  });

  factory EnhancedPrescriptionDetails.fromJson(Map<String, dynamic> json) {
    return EnhancedPrescriptionDetails(
      prescription: PrescriptionInfo.fromJson(json['prescription'] ?? {}),
      vitals: PrescriptionVitals.fromJson(json['vitals'] ?? {}),
      doctor: DoctorInfo.fromJson(json['doctor'] ?? {}),
      patient: PatientInfo.fromJson(json['patient'] ?? {}),
      medicines:
          (json['medicines'] as List<dynamic>?)
              ?.map((m) => MedicineInfo.fromJson(m))
              .toList() ??
          [],
      medicineCount: json['medicine_count'] ?? 0,
    );
  }
}

class PrescriptionInfo {
  final int prescriptionId;
  final int patientId;
  final int doctorId;
  final String? prescriptionDate;
  final DateTime createdAt;
  final String? diagnosis;
  final String? medicalConditions;
  final String? additionalNotes;
  final String? appointmentSummary;
  final String? appointmentTranscription;
  final String? prescriptionRawUrl;
  final String? compiledPrescriptionUrl;

  PrescriptionInfo({
    required this.prescriptionId,
    required this.patientId,
    required this.doctorId,
    this.prescriptionDate,
    required this.createdAt,
    this.diagnosis,
    this.medicalConditions,
    this.additionalNotes,
    this.appointmentSummary,
    this.appointmentTranscription,
    this.prescriptionRawUrl,
    this.compiledPrescriptionUrl,
  });

  factory PrescriptionInfo.fromJson(Map<String, dynamic> json) {
    return PrescriptionInfo(
      prescriptionId: json['prescription_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      prescriptionDate: json['prescription_date'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      diagnosis: json['diagnosis'],
      medicalConditions: json['medical_conditions'],
      additionalNotes: json['additional_notes'],
      appointmentSummary: json['appointment_summary'],
      appointmentTranscription: json['appointment_transcription'],
      prescriptionRawUrl: json['prescription_raw_url'],
      compiledPrescriptionUrl: json['compiled_prescription_url'],
    );
  }
}

class DoctorInfo {
  final String name;
  final String? email;
  final String? phone;
  final String? specialization;
  final String? licenseId;
  final String? designation;

  DoctorInfo({
    required this.name,
    this.email,
    this.phone,
    this.specialization,
    this.licenseId,
    this.designation,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      specialization: json['specialization'],
      licenseId: json['license_id'],
      designation: json['designation'],
    );
  }
}

class PatientInfo {
  final String name;
  final String? email;
  final String? phone;
  final String? dateOfBirth;

  PatientInfo({required this.name, this.email, this.phone, this.dateOfBirth});

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
    );
  }
}

class MedicineInfo {
  final int medicinId;
  final String medicineName;
  final String? medicineFrequency;
  final String? medicineSalt;
  final int? medDrugId;
  final DateTime createdAt;

  MedicineInfo({
    required this.medicinId,
    required this.medicineName,
    this.medicineFrequency,
    this.medicineSalt,
    this.medDrugId,
    required this.createdAt,
  });

  factory MedicineInfo.fromJson(Map<String, dynamic> json) {
    return MedicineInfo(
      medicinId: json['medicin_id'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      medicineFrequency: json['medicine_frequency'],
      medicineSalt: json['medicine_salt'],
      medDrugId: json['med_drug_id'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  bool get hasAnuvanshLink => medDrugId != null;
}

// My Prescriptions list model
class MyPrescriptionsResponse {
  final bool success;
  final String message;
  final MyPrescriptionsData? data;
  final String? error;

  MyPrescriptionsResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory MyPrescriptionsResponse.fromJson(Map<String, dynamic> json) {
    return MyPrescriptionsResponse(
      success: json['status'] == 'SUCCESS',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? MyPrescriptionsData.fromJson(json['data'])
          : null,
      error: json['error'],
    );
  }
}

class MyPrescriptionsData {
  final List<PrescriptionSummary> prescriptions;
  final MyPatientInfo patientInfo;
  final PaginationInfo pagination;

  MyPrescriptionsData({
    required this.prescriptions,
    required this.patientInfo,
    required this.pagination,
  });

  factory MyPrescriptionsData.fromJson(Map<String, dynamic> json) {
    return MyPrescriptionsData(
      prescriptions:
          (json['prescriptions'] as List<dynamic>?)
              ?.map((p) => PrescriptionSummary.fromJson(p))
              .toList() ??
          [],
      patientInfo: MyPatientInfo.fromJson(json['patient_info'] ?? {}),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PrescriptionSummary {
  final int prescriptionId;
  final String? prescriptionDate;
  final DateTime createdAt;
  final String doctorName;
  final String? doctorSpecialization;
  final String? diagnosis;
  final String? medicalConditions;
  final int medicineCount;
  final PrescriptionVitals vitals;
  final String? prescriptionRawUrl;
  final String? compiledPrescriptionUrl;

  PrescriptionSummary({
    required this.prescriptionId,
    this.prescriptionDate,
    required this.createdAt,
    required this.doctorName,
    this.doctorSpecialization,
    this.diagnosis,
    this.medicalConditions,
    required this.medicineCount,
    required this.vitals,
    this.prescriptionRawUrl,
    this.compiledPrescriptionUrl,
  });

  factory PrescriptionSummary.fromJson(Map<String, dynamic> json) {
    return PrescriptionSummary(
      prescriptionId: json['prescription_id'] ?? 0,
      prescriptionDate: json['prescription_date'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      doctorName: json['doctor_name'] ?? '',
      doctorSpecialization: json['doctor_specialization'],
      diagnosis: json['diagnosis'],
      medicalConditions: json['medical_conditions'],
      medicineCount: json['medicine_count'] ?? 0,
      vitals: PrescriptionVitals.fromJson(json['vitals'] ?? {}),
      prescriptionRawUrl: json['prescription_raw_url'],
      compiledPrescriptionUrl: json['compiled_prescription_url'],
    );
  }

  String get displayDate {
    if (prescriptionDate != null) {
      return prescriptionDate!;
    }
    return createdAt.toString().split(' ')[0]; // YYYY-MM-DD format
  }

  String get doctorDisplayName {
    if (doctorSpecialization != null && doctorSpecialization!.isNotEmpty) {
      return '$doctorName ($doctorSpecialization)';
    }
    return doctorName;
  }
}

class MyPatientInfo {
  final int patientId;
  final String patientName;
  final String? patientEmail;

  MyPatientInfo({
    required this.patientId,
    required this.patientName,
    this.patientEmail,
  });

  factory MyPatientInfo.fromJson(Map<String, dynamic> json) {
    return MyPatientInfo(
      patientId: json['patient_id'] ?? 0,
      patientName: json['patient_name'] ?? '',
      patientEmail: json['patient_email'],
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int limit;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.limit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalRecords: json['total_records'] ?? 0,
      limit: json['limit'] ?? 10,
    );
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}

// Prescription Summary/Statistics model
class PrescriptionSummaryStats {
  final int patientId;
  final String patientName;
  final String? patientEmail;
  final int totalPrescriptions;
  final int uniqueDoctorsConsulted;
  final int totalMedicinesPrescribed;
  final int prescriptionsLast30Days;
  final DateTime? lastPrescriptionDate;
  final DateTime? firstPrescriptionDate;

  PrescriptionSummaryStats({
    required this.patientId,
    required this.patientName,
    this.patientEmail,
    required this.totalPrescriptions,
    required this.uniqueDoctorsConsulted,
    required this.totalMedicinesPrescribed,
    required this.prescriptionsLast30Days,
    this.lastPrescriptionDate,
    this.firstPrescriptionDate,
  });

  factory PrescriptionSummaryStats.fromJson(Map<String, dynamic> json) {
    return PrescriptionSummaryStats(
      patientId: json['patient_id'] ?? 0,
      patientName: json['patient_name'] ?? '',
      patientEmail: json['patient_email'],
      totalPrescriptions: json['total_prescriptions'] ?? 0,
      uniqueDoctorsConsulted: json['unique_doctors_consulted'] ?? 0,
      totalMedicinesPrescribed: json['total_medicines_prescribed'] ?? 0,
      prescriptionsLast30Days: json['prescriptions_last_30_days'] ?? 0,
      lastPrescriptionDate: json['last_prescription_date'] != null
          ? DateTime.parse(json['last_prescription_date'])
          : null,
      firstPrescriptionDate: json['first_prescription_date'] != null
          ? DateTime.parse(json['first_prescription_date'])
          : null,
    );
  }

  bool get hasActivePrescriptions => totalPrescriptions > 0;
  bool get hasRecentActivity => prescriptionsLast30Days > 0;

  String get memberSince {
    if (firstPrescriptionDate != null) {
      final now = DateTime.now();
      final difference = now.difference(firstPrescriptionDate!);
      if (difference.inDays < 30) {
        return '${difference.inDays} days';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} months';
      } else {
        return '${(difference.inDays / 365).floor()} years';
      }
    }
    return 'Unknown';
  }
}

// Enhanced validation for self-service prescriptions
class SelfServicePrescriptionValidation {
  static const int maxMedicineNameLength = 255;
  static const int maxCharVaryingLength = 255;
  static const int maxDoctorNameLength = 255;
  static const int maxTextLength = 5000;

  static String? validateDoctorName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Doctor name is required';
    }
    if (value.length > maxDoctorNameLength) {
      return 'Doctor name must be less than $maxDoctorNameLength characters';
    }
    return null;
  }

  static String? validateMedicineName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Medicine name is required';
    }
    if (value.length > maxMedicineNameLength) {
      return 'Medicine name must be less than $maxMedicineNameLength characters';
    }
    return null;
  }

  static String? validateMedicineFrequency(String? value) {
    if (value != null && value.length > maxCharVaryingLength) {
      return 'Frequency must be less than $maxCharVaryingLength characters';
    }
    return null;
  }

  static String? validateBloodPressure(String? value) {
    if (value != null && value.isNotEmpty) {
      final bpPattern = RegExp(r'^\d{2,3}\/\d{2,3}$');
      if (!bpPattern.hasMatch(value.trim())) {
        return 'Enter valid blood pressure (e.g., 120/80)';
      }
    }
    return null;
  }

  static String? validatePulse(String? value) {
    if (value != null && value.isNotEmpty) {
      final numericPulse = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (numericPulse.isEmpty) {
        return 'Enter valid pulse rate';
      }
      final pulse = int.tryParse(numericPulse);
      if (pulse == null || pulse < 30 || pulse > 300) {
        return 'Pulse rate should be between 30-300 bpm';
      }
    }
    return null;
  }

  static String? validateTemperature(String? value) {
    if (value != null && value.isNotEmpty) {
      final tempStr = value.replaceAll(RegExp(r'[^\d\.]'), '');
      final temp = double.tryParse(tempStr);
      if (temp == null || temp < 90 || temp > 110) {
        return 'Enter valid temperature (90-110°F)';
      }
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value != null && value.isNotEmpty) {
      final weightStr = value.replaceAll(RegExp(r'[^\d\.]'), '');
      final weight = double.tryParse(weightStr);
      if (weight == null || weight <= 0) {
        return 'Enter valid weight';
      }
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value != null && value.isNotEmpty) {
      final heightStr = value.replaceAll(RegExp(r'[^\d\.]'), '');
      final height = double.tryParse(heightStr);
      if (height == null || height <= 0) {
        return 'Enter valid height';
      }
    }
    return null;
  }

  static String? validateTextfield(
    String? value,
    String fieldName, {
    int? maxLength,
  }) {
    if (value != null && value.isNotEmpty) {
      final effectiveMaxLength = maxLength ?? maxTextLength;
      if (value.length > effectiveMaxLength) {
        return '$fieldName must be less than $effectiveMaxLength characters';
      }
    }
    return null;
  }

  static List<String> validateMedicines(
    List<CreateSelfServiceMedicineRequest> medicines,
  ) {
    List<String> errors = [];

    if (medicines.isEmpty) {
      errors.add('At least one medicine is required');
      return errors;
    }

    for (int i = 0; i < medicines.length; i++) {
      final medicine = medicines[i];
      final medicineError = validateMedicineName(medicine.medicineName);
      if (medicineError != null) {
        errors.add('Medicine ${i + 1}: $medicineError');
      }

      final frequencyError = validateMedicineFrequency(
        medicine.medicineFrequency,
      );
      if (frequencyError != null) {
        errors.add('Medicine ${i + 1}: $frequencyError');
      }
    }

    return errors;
  }
}
