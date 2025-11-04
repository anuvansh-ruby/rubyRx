import '../controllers/manual_entry_controller.dart';

/// Data model for prescription information extracted from OCR
/// This bridges the gap between Google Vision API results and manual entry form
class PrescriptionOcrData {
  // Doctor Information
  final String? doctorName;
  final String? doctorSpecialty;
  final String? doctorLicenseNumber;
  final String? clinicName;
  final String? clinicAddress;

  // Patient Information
  final String? patientName;
  final String? patientAge;
  final String? patientGender;
  final String? medicalConditions;

  // Patient Vitals (if mentioned)
  final String? bloodPressure;
  final String? pulse;
  final String? temperature;
  final String? weight;
  final String? height;

  // Prescription Date & General Info
  final DateTime? prescriptionDate;
  final String? diagnosis;
  final String? additionalNotes;

  // Extracted Medications
  final List<OcrMedicationData> medications;

  // OCR Metadata
  final double confidenceScore;
  final bool requiresManualReview;
  final List<String> extractionWarnings;
  final String originalImagePath;

  PrescriptionOcrData({
    this.doctorName,
    this.doctorSpecialty,
    this.doctorLicenseNumber,
    this.clinicName,
    this.clinicAddress,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.medicalConditions,
    this.bloodPressure,
    this.pulse,
    this.temperature,
    this.weight,
    this.height,
    this.prescriptionDate,
    this.diagnosis,
    this.additionalNotes,
    required this.medications,
    required this.confidenceScore,
    required this.requiresManualReview,
    required this.extractionWarnings,
    required this.originalImagePath,
  });

  factory PrescriptionOcrData.fromJson(Map<String, dynamic> json) {
    return PrescriptionOcrData(
      doctorName: json['doctor_name']?.toString(),
      doctorSpecialty: json['doctor_specialty']?.toString(),
      doctorLicenseNumber: json['doctor_license_number']?.toString(),
      clinicName: json['clinic_name']?.toString(),
      clinicAddress: json['clinic_address']?.toString(),
      patientName: json['patient_name']?.toString(),
      patientAge: json['patient_age']?.toString(),
      patientGender: json['patient_gender']?.toString(),
      medicalConditions: json['medical_conditions']?.toString(),
      bloodPressure: json['blood_pressure']?.toString(),
      pulse: json['pulse']?.toString(),
      temperature: json['temperature']?.toString(),
      weight: json['weight']?.toString(),
      height: json['height']?.toString(),
      prescriptionDate: json['prescription_date'] != null
          ? DateTime.tryParse(json['prescription_date'])
          : null,
      diagnosis: json['diagnosis']?.toString(),
      additionalNotes: json['additional_notes']?.toString(),
      medications:
          (json['medications'] as List<dynamic>?)
              ?.map((med) => OcrMedicationData.fromJson(med))
              .toList() ??
          [],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      requiresManualReview: json['requires_manual_review'] ?? false,
      extractionWarnings: List<String>.from(json['extraction_warnings'] ?? []),
      originalImagePath: json['original_image_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
      'doctor_license_number': doctorLicenseNumber,
      'clinic_name': clinicName,
      'clinic_address': clinicAddress,
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'medical_conditions': medicalConditions,
      'blood_pressure': bloodPressure,
      'pulse': pulse,
      'temperature': temperature,
      'weight': weight,
      'height': height,
      'prescription_date': prescriptionDate?.toIso8601String(),
      'diagnosis': diagnosis,
      'additional_notes': additionalNotes,
      'medications': medications.map((med) => med.toJson()).toList(),
      'confidence_score': confidenceScore,
      'requires_manual_review': requiresManualReview,
      'extraction_warnings': extractionWarnings,
      'original_image_path': originalImagePath,
    };
  }
}

/// Individual medication extracted from prescription image
class OcrMedicationData {
  final String name;
  final String? genericName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;
  final String? salt; // Active ingredient
  final double confidence; // Confidence level for this specific medication

  OcrMedicationData({
    required this.name,
    this.genericName,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
    this.salt,
    required this.confidence,
  });

  factory OcrMedicationData.fromJson(Map<String, dynamic> json) {
    return OcrMedicationData(
      name: json['name']?.toString() ?? '',
      genericName: json['generic_name']?.toString(),
      dosage: json['dosage']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      instructions: json['instructions']?.toString(),
      salt: json['salt']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'generic_name': genericName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'salt': salt,
      'confidence': confidence,
    };
  }

  /// Convert OCR medication data to MedicationModel for manual entry form
  MedicationModel toMedicationModel() {
    final medicationModel = MedicationModel();
    medicationModel.nameController.text = name;
    medicationModel.dosageController.text = dosage ?? '';
    medicationModel.selectedFrequency.value = frequency ?? '';
    medicationModel.selectedDuration.value = duration ?? '';
    medicationModel.instructionsController.text = instructions ?? salt ?? '';
    return medicationModel;
  }
}

/// Response model for prescription OCR processing
class PrescriptionOcrResponse {
  final String status;
  final String message;
  final PrescriptionOcrData? data;
  final String? error;
  final String? prescriptionId;
  final String? processingId;

  PrescriptionOcrResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
    this.prescriptionId,
    this.processingId,
  });

  factory PrescriptionOcrResponse.fromJson(Map<String, dynamic> json) {
    return PrescriptionOcrResponse(
      status: json['status'] ?? 'FAILURE',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PrescriptionOcrData.fromJson(json['data'])
          : null,
      error: json['error'],
      prescriptionId: json['prescription_id'],
      processingId: json['processing_id'],
    );
  }

  bool get isSuccess => status == 'SUCCESS';
  bool get isFailure => status == 'FAILURE';
  bool get isPending => status == 'PENDING';
}

/// Extension methods for converting OCR data to manual entry form data
extension PrescriptionOcrDataExtensions on PrescriptionOcrData {
  /// Generate summary for user review
  String generateSummary() {
    final buffer = StringBuffer();
    buffer.writeln('📄 Prescription OCR Summary');
    buffer.writeln(
      'Confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%',
    );

    if (requiresManualReview) {
      buffer.writeln('⚠️ Manual review required');
    }

    if (extractionWarnings.isNotEmpty) {
      buffer.writeln('⚠️ Warnings: ${extractionWarnings.join(', ')}');
    }

    buffer.writeln('\nDoctor: ${doctorName ?? 'Not detected'}');
    buffer.writeln('Patient: ${patientName ?? 'Not detected'}');
    buffer.writeln('Medications: ${medications.length} found');

    return buffer.toString();
  }

  /// Check if the OCR data has sufficient information for form pre-population
  bool get hasMinimumRequiredData {
    return medications.isNotEmpty &&
        (doctorName?.isNotEmpty == true || patientName?.isNotEmpty == true);
  }

  /// Get list of fields that have low confidence and need review
  List<String> getLowConfidenceFields() {
    final lowConfidenceFields = <String>[];

    if (confidenceScore < 0.7) {
      lowConfidenceFields.add('Overall prescription');
    }

    for (final medication in medications) {
      if (medication.confidence < 0.6) {
        lowConfidenceFields.add('Medication: ${medication.name}');
      }
    }

    return lowConfidenceFields;
  }
}
