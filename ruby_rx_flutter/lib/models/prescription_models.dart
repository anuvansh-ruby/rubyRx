class CreatePrescriptionByNameRequest {
  final String doctorName;
  final String? doctorPhoneNumber;
  final String? appointmentName;
  final String? appointmentDate; // DD/MM/YYYY format
  final String? clinicAddress;
  final String? doctorSpecialty;
  final String? doctorLicenseNumber;
  final String? clinicName;

  final String? medicalConditions;

  // Patient vitals
  final String? patientBloodPressure;
  final String? patientPulse;
  final String? patientTemperature;
  final String? patientWeight;
  final String? patientHeight;

  final String? additionalNotes;

  // Medications
  final List<CreateMedicineByNameRequest> medicines;

  CreatePrescriptionByNameRequest({
    required this.doctorName,
    this.doctorPhoneNumber,
    this.appointmentName,
    this.appointmentDate,
    this.clinicAddress,
    this.doctorSpecialty,
    this.doctorLicenseNumber,
    this.clinicName,
    this.medicalConditions,
    this.patientBloodPressure,
    this.patientPulse,
    this.patientTemperature,
    this.patientWeight,
    this.patientHeight,
    this.additionalNotes,
    required this.medicines,
  });

  Map<String, dynamic> toJson() {
    return {
      // Doctor information
      'doctor_name': doctorName,
      'doctor_phone_number': doctorPhoneNumber,
      'appointment_name': appointmentName,
      'appointment_date': appointmentDate,
      'clinic_address': clinicAddress,
      'doctor_specialty': doctorSpecialty,
      'doctor_license_number': doctorLicenseNumber,
      'clinic_name': clinicName,

      'medical_conditions': medicalConditions,

      // Patient vitals
      'patient_blood_pressure': patientBloodPressure,
      'patient_pulse': patientPulse,
      'patient_temperature': patientTemperature,
      'patient_weight': patientWeight,
      'patient_height': patientHeight,

      'additional_notes': additionalNotes,

      // Medications
      'medicines': medicines.map((m) => m.toJson()).toList(),
    };
  }
}

class CreateMedicineByNameRequest {
  final int id; // Optional ID if available
  final String medicineName;
  final String? medicineGenericName;
  final String? medicineDosage;
  final String? medicineFrequency;
  final String? medicineDuration;
  final String? medicineInstructions;
  final String? medicineSalt;

  CreateMedicineByNameRequest({
    required this.id,
    required this.medicineName,
    this.medicineGenericName,
    this.medicineDosage,
    this.medicineFrequency,
    this.medicineDuration,
    this.medicineInstructions,
    this.medicineSalt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine_name': medicineName,
      'generic_name': medicineGenericName,
      'dosage': medicineDosage,
      'medicine_frequency': medicineFrequency,
      'duration': medicineDuration,
      'instructions': medicineInstructions,
      'medicine_salt': medicineSalt,
    };
  }
}

class PrescriptionResponse {
  final bool success;
  final String? message;
  final PrescriptionData? data;
  final String? error;

  PrescriptionResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory PrescriptionResponse.fromJson(Map<String, dynamic> json) {
    return PrescriptionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PrescriptionData.fromJson(json['data'])
          : null,
      error: json['error'],
    );
  }
}

class PrescriptionData {
  final int appointmentId;
  final int prescriptionId;
  final int appointmentDetailId;
  final List<int> medicineIds;

  PrescriptionData({
    required this.appointmentId,
    required this.prescriptionId,
    required this.appointmentDetailId,
    required this.medicineIds,
  });

  factory PrescriptionData.fromJson(Map<String, dynamic> json) {
    return PrescriptionData(
      appointmentId: json['appointment_id'] ?? 0,
      prescriptionId: json['prescription_id'] ?? 0,
      appointmentDetailId: json['appointment_detail_id'] ?? 0,
      medicineIds: List<int>.from(json['medicine_ids'] ?? []),
    );
  }
}

// Validation rules matching database constraints
class PrescriptionValidation {
  static const int maxMedicineNameLength = 255;
  static const int maxCharVaryingLength = 255;
  static const int maxPatientNameLength = 255;
  static const int maxDoctorNameLength = 255;

  static String? validateMedicineName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Medicine name is required';
    }
    if (value.length > maxMedicineNameLength) {
      return 'Medicine name must be less than $maxMedicineNameLength characters';
    }
    return null;
  }

  static String? validateFrequency(String? value) {
    if (value != null && value.length > maxCharVaryingLength) {
      return 'Frequency must be less than $maxCharVaryingLength characters';
    }
    return null;
  }

  static String? validateBloodPressure(String? value) {
    if (value != null && value.isNotEmpty) {
      // Basic BP validation pattern (e.g., 120/80)
      final bpPattern = RegExp(r'^\d{2,3}\/\d{2,3}$');
      if (!bpPattern.hasMatch(value)) {
        return 'Enter valid blood pressure (e.g., 120/80)';
      }
    }
    return null;
  }

  static String? validatePulse(String? value) {
    if (value != null && value.isNotEmpty) {
      // Extract numeric value from pulse (e.g., "72 bpm" -> "72")
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
      // Extract numeric value from temperature
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
      // Extract numeric value from weight
      final weightStr = value.replaceAll(RegExp(r'[^\d\.]'), '');
      final weight = double.tryParse(weightStr);
      if (weight == null || weight <= 0) {
        return 'Enter valid weight';
      }
    }
    return null;
  }
}
