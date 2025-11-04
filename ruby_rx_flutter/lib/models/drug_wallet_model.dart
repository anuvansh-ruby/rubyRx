/// Drug Wallet Models
/// Models for patient's medicine wallet - all medicines from all prescriptions
/// Provides comprehensive medicine history and details

class DrugWalletResponse {
  final bool success;
  final String message;
  final DrugWalletData? data;
  final String? error;

  const DrugWalletResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory DrugWalletResponse.fromJson(Map<String, dynamic> json) {
    return DrugWalletResponse(
      success: json['status'] == 'SUCCESS',
      message: json['message'] ?? '',
      data: json['data'] != null ? DrugWalletData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class DrugWalletData {
  final List<MedicineWalletItem> medicines;
  final DrugWalletStatistics statistics;
  final PaginationInfo pagination;
  final FilterInfo filters;

  const DrugWalletData({
    required this.medicines,
    required this.statistics,
    required this.pagination,
    required this.filters,
  });

  factory DrugWalletData.fromJson(Map<String, dynamic> json) {
    return DrugWalletData(
      medicines:
          (json['medicines'] as List<dynamic>?)
              ?.map((e) => MedicineWalletItem.fromJson(e))
              .toList() ??
          [],
      statistics: DrugWalletStatistics.fromJson(json['statistics'] ?? {}),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      filters: FilterInfo.fromJson(json['filters'] ?? {}),
    );
  }
}

class CompositionInfo {
  final int? compositionId1;
  final int? compositionId2;
  final int? compositionId3;
  final int? compositionId4;
  final int? compositionId5;

  const CompositionInfo({
    this.compositionId1,
    this.compositionId2,
    this.compositionId3,
    this.compositionId4,
    this.compositionId5,
  });

  factory CompositionInfo.fromJson(Map<String, dynamic> json) {
    return CompositionInfo(
      compositionId1: json['composition_id_1'],
      compositionId2: json['composition_id_2'],
      compositionId3: json['composition_id_3'],
      compositionId4: json['composition_id_4'],
      compositionId5: json['composition_id_5'],
    );
  }

  /// Get all non-null composition IDs
  List<int> get allCompositionIds {
    return [
      compositionId1,
      compositionId2,
      compositionId3,
      compositionId4,
      compositionId5,
    ].where((id) => id != null && id != 0).cast<int>().toList();
  }

  /// Check if has any compositions
  bool get hasCompositions {
    return allCompositionIds.isNotEmpty;
  }
}

class MedicineWalletItem {
  final int medicineId;
  final String medicineName;
  final String? medicineSalt;
  final String? medicineFrequency;
  final DateTime medicineAddedDate;
  final int? medDrugId;
  final CompositionInfo compositions;
  final bool hasCompositionOverlap;
  final String warningLevel;
  final PrescriptionInfo prescription;
  final DoctorInfo? doctor;

  const MedicineWalletItem({
    required this.medicineId,
    required this.medicineName,
    this.medicineSalt,
    this.medicineFrequency,
    required this.medicineAddedDate,
    this.medDrugId,
    required this.compositions,
    required this.hasCompositionOverlap,
    required this.warningLevel,
    required this.prescription,
    this.doctor,
  });

  factory MedicineWalletItem.fromJson(Map<String, dynamic> json) {
    return MedicineWalletItem(
      medicineId: json['medicine_id'],
      medicineName: json['medicine_name'],
      medicineSalt: json['medicine_salt'],
      medicineFrequency: json['medicine_frequency'],
      medicineAddedDate: DateTime.parse(json['medicine_added_date']),
      medDrugId: json['med_drug_id'],
      compositions: CompositionInfo.fromJson(json['compositions'] ?? {}),
      hasCompositionOverlap: json['has_composition_overlap'] ?? false,
      warningLevel: json['warning_level'] ?? 'none',
      prescription: PrescriptionInfo.fromJson(json['prescription']),
      doctor: json['doctor'] != null
          ? DoctorInfo.fromJson(json['doctor'])
          : null,
    );
  }

  /// Get formatted frequency display
  String get frequencyDisplay {
    if (medicineFrequency == null || medicineFrequency!.isEmpty) {
      return 'As directed';
    }
    return medicineFrequency!;
  }

  /// Get formatted date display
  String get dateDisplay {
    final now = DateTime.now();
    final difference = now.difference(medicineAddedDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Get short date format
  String get shortDate {
    return '${medicineAddedDate.day}/${medicineAddedDate.month}/${medicineAddedDate.year}';
  }

  /// Check if medicine has a warning
  bool get hasWarning {
    return hasCompositionOverlap;
  }

  /// Get warning message
  String get warningMessage {
    if (hasCompositionOverlap) {
      return 'This medicine shares composition with another medicine in your wallet';
    }
    return '';
  }
}

class PrescriptionInfo {
  final int prescriptionId;
  final DateTime prescriptionDate;
  final String? prescriptionUrl;
  final int? appointmentId;
  final VitalsInfo vitals;

  const PrescriptionInfo({
    required this.prescriptionId,
    required this.prescriptionDate,
    this.prescriptionUrl,
    this.appointmentId,
    required this.vitals,
  });

  factory PrescriptionInfo.fromJson(Map<String, dynamic> json) {
    return PrescriptionInfo(
      prescriptionId: json['prescription_id'],
      prescriptionDate: DateTime.parse(json['prescription_date']),
      prescriptionUrl: json['prescription_url'],
      appointmentId: json['appointment_id'],
      vitals: VitalsInfo.fromJson(json['vitals'] ?? {}),
    );
  }

  /// Get formatted date
  String get formattedDate {
    return '${prescriptionDate.day}/${prescriptionDate.month}/${prescriptionDate.year}';
  }
}

class VitalsInfo {
  final String? bloodPressure;
  final String? pulse;
  final String? temperature;
  final String? weight;
  final String? height;

  const VitalsInfo({
    this.bloodPressure,
    this.pulse,
    this.temperature,
    this.weight,
    this.height,
  });

  factory VitalsInfo.fromJson(Map<String, dynamic> json) {
    return VitalsInfo(
      bloodPressure: json['blood_pressure'],
      pulse: json['pulse'],
      temperature: json['temperature'],
      weight: json['weight'],
      height: json['height'],
    );
  }

  /// Check if any vitals are available
  bool get hasVitals {
    return bloodPressure != null ||
        pulse != null ||
        temperature != null ||
        weight != null ||
        height != null;
  }

  /// Get vitals summary string
  String get summary {
    final parts = <String>[];
    if (bloodPressure != null) parts.add('BP: $bloodPressure');
    if (pulse != null) parts.add('Pulse: $pulse');
    if (temperature != null) parts.add('Temp: $temperature');
    if (weight != null) parts.add('Weight: $weight kg');
    return parts.join(' | ');
  }
}

class DoctorInfo {
  final int doctorId;
  final String doctorName;
  final String? doctorSpecialization;
  final String? doctorPhone;
  final String? doctorEmail;
  final String? doctorCity;

  const DoctorInfo({
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialization,
    this.doctorPhone,
    this.doctorEmail,
    this.doctorCity,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      doctorSpecialization: json['doctor_specialization'],
      doctorPhone: json['doctor_phone'],
      doctorEmail: json['doctor_email'],
      doctorCity: json['doctor_city'],
    );
  }

  /// Get doctor display name with title
  String get displayName {
    return 'Dr. $doctorName';
  }

  /// Get doctor info with specialization
  String get fullInfo {
    if (doctorSpecialization != null && doctorSpecialization!.isNotEmpty) {
      return 'Dr. $doctorName - $doctorSpecialization';
    }
    return 'Dr. $doctorName';
  }
}

class DrugWalletStatistics {
  final int totalMedicines;
  final int uniqueMedicines;
  final int totalPrescriptions;
  final int totalDoctors;
  final int medicinesWithOverlaps;
  final DateTime? firstPrescriptionDate;
  final DateTime? latestPrescriptionDate;

  const DrugWalletStatistics({
    required this.totalMedicines,
    required this.uniqueMedicines,
    required this.totalPrescriptions,
    required this.totalDoctors,
    required this.medicinesWithOverlaps,
    this.firstPrescriptionDate,
    this.latestPrescriptionDate,
  });

  factory DrugWalletStatistics.fromJson(Map<String, dynamic> json) {
    return DrugWalletStatistics(
      totalMedicines: json['total_medicines'] ?? 0,
      uniqueMedicines: json['unique_medicines'] ?? 0,
      totalPrescriptions: json['total_prescriptions'] ?? 0,
      totalDoctors: json['total_doctors'] ?? 0,
      medicinesWithOverlaps: json['medicines_with_overlaps'] ?? 0,
      firstPrescriptionDate: json['first_prescription_date'] != null
          ? DateTime.parse(json['first_prescription_date'])
          : null,
      latestPrescriptionDate: json['latest_prescription_date'] != null
          ? DateTime.parse(json['latest_prescription_date'])
          : null,
    );
  }

  /// Get duration of medical history in readable format
  String get historyDuration {
    if (firstPrescriptionDate == null || latestPrescriptionDate == null) {
      return 'N/A';
    }

    final difference = latestPrescriptionDate!
        .difference(firstPrescriptionDate!)
        .inDays;

    if (difference < 30) {
      return '$difference days';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (difference / 365).floor();
      final remainingMonths = ((difference % 365) / 30).floor();
      if (remainingMonths > 0) {
        return '$years ${years == 1 ? 'year' : 'years'}, $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
      }
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int limit;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.limit,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalRecords: json['total_records'] ?? 0,
      limit: json['limit'] ?? 20,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }
}

class FilterInfo {
  final String sortBy;
  final String order;
  final String? filter;

  const FilterInfo({required this.sortBy, required this.order, this.filter});

  factory FilterInfo.fromJson(Map<String, dynamic> json) {
    return FilterInfo(
      sortBy: json['sort_by'] ?? 'date',
      order: json['order'] ?? 'desc',
      filter: json['filter'],
    );
  }
}
