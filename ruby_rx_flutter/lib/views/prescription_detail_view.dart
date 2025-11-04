import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import 'package:ruby_rx_flutter/models/prescription_detail_model.dart';
import '../controllers/prescription_detail_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../models/prescription_model.dart';
import 'widgets/medicine_detail_dialog.dart';

class PrescriptionDetailView extends StatelessWidget {
  const PrescriptionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final PrescriptionDetailController controller =
        Get.find<PrescriptionDetailController>();
    final prescription = Get.arguments as PrescriptionModel?;

    // If no prescription in arguments, show error
    if (prescription == null) {
      return Scaffold(
        body: GradientBackground(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: RubyColors.grey,
                  ),
                  const SizedBox(height: 16),
                  AppText.bodyMedium(
                    'No prescription data available',
                    color: RubyColors.grey,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: AppText.buttonMedium('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If prescription is available and controller hasn't loaded it yet, load it
    if (controller.prescriptionDetail.value == null &&
        !controller.isLoading.value) {
      controller.loadPrescriptionDetails(prescription.prescriptionId);
    }

    return _buildPrescriptionView(controller, prescription);
  }

  Widget _buildPrescriptionView(
    PrescriptionDetailController controller,
    PrescriptionModel prescription,
  ) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Navigation Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppNavigationBar.profile(
                  title: prescription.displayDoctorName,
                  onBackPressed: () => Get.back(),
                ),
              ),

              // Main Content
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: RubyColors.primary1,
                      ),
                    );
                  }

                  if (controller.prescriptionDetail.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: RubyColors.grey,
                          ),
                          const SizedBox(height: 16),
                          AppText.bodyMedium(
                            'Unable to load prescription details',
                            color: RubyColors.grey,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => controller.loadPrescriptionDetails(
                              prescription.prescriptionId,
                            ),
                            child: AppText.buttonMedium('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final prescriptionDetail =
                      controller.prescriptionDetail.value!;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Doctor Information Card
                        if (prescriptionDetail.doctor != null)
                          _buildDoctorInfoCard(prescriptionDetail.doctor!),

                        // const SizedBox(height: 16),

                        // // Patient Information Card
                        // _buildPatientInfoCard(prescriptionDetail),
                        const SizedBox(height: 16),

                        // Medicines List
                        _buildMedicinesList(prescriptionDetail.medicines),

                        const SizedBox(
                          height: 100,
                        ), // Space for floating buttons
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildActionButtons(prescription),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDoctorInfoCard(DoctorModelData doctor) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.doctorName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (doctor.doctorSpecialization != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: Color(0xFF7F8C8D),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                doctor.doctorSpecialization!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Doctor contact info
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                Text(
                  doctor.doctorPhoneNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesList(List<PatientMedicineModelData> medicines) {
    final controller = Get.find<PrescriptionDetailController>();
    final prescriptionDetail = controller.prescriptionDetail.value;

    // Format prescription date - use appointment date if available
    String prescriptionDate = 'October 17, 2025';
    if (prescriptionDetail?.prescription.appointmentDate != null) {
      final date = prescriptionDetail!.prescription.appointmentDate!;
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      prescriptionDate = '${months[date.month - 1]} ${date.day}, ${date.year}';
    } else if (prescriptionDetail?.prescription.createdAt != null) {
      final date = prescriptionDetail!.prescription.createdAt;
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      prescriptionDate = '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescribed Medicines',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 20),
            ...medicines.asMap().entries.map((entry) {
              final index = entry.key;
              final medicine = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < medicines.length - 1 ? 16 : 0,
                ),
                child: _buildMedicineCard(medicine),
              );
            }),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Prescription Date: $prescriptionDate',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7F8C8D),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(PatientMedicineModelData medicine) {
    // Parse frequency to extract parts - prioritize model fields over parsing
    Map<String, String> frequencyParts;

    if (medicine.duration != null || medicine.notes != null) {
      // Use direct fields from model
      frequencyParts = {
        'frequency': medicine.medicineFrequency ?? 'Once daily (Morning)',
        if (medicine.duration != null) 'duration': medicine.duration!,
        if (medicine.notes != null) 'notes': medicine.notes!,
      };
    } else {
      // Fall back to parsing the frequency string
      frequencyParts = _parseFrequency(medicine.medicineFrequency ?? '');
    }

    return GestureDetector(
      onTap: () {
        // Show medicine detail dialog with substitutes
        MedicineDetailDialog.show(context: Get.context!, medicine: medicine);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.medicineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      if (medicine.compositionInfo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              size: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                medicine.compositionInfo,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7F8C8D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (medicine.medicineSalt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          medicine.medicineSalt!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Add tap indicator icon
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF00BCD4),
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Frequency and Duration
            Row(
              children: [
                Expanded(
                  child: _buildMedicineInfo(
                    Icons.access_time,
                    'Frequency:',
                    frequencyParts['frequency'] ?? 'Once daily (Morning)',
                  ),
                ),
              ],
            ),

            if (frequencyParts['duration'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMedicineInfo(
                      Icons.calendar_today,
                      'Duration:',
                      frequencyParts['duration']!,
                    ),
                  ),
                ],
              ),
            ],

            // Notes section
            if (frequencyParts['notes'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF00BCD4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            frequencyParts['notes']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2C3E50),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Add "Tap for details" hint
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Tap for details and substitutes',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00BCD4)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _parseFrequency(String frequencyText) {
    final Map<String, String> result = {};

    if (frequencyText.isEmpty) {
      return result;
    }

    // Try to extract frequency, duration, and notes from the text
    // Example formats:
    // "Once daily (Morning) - 30 days - Take with or without food"
    // "Once daily (Evening) - 14 days - May cause drowsiness"

    final parts = frequencyText.split(' - ');

    if (parts.isNotEmpty) {
      result['frequency'] = parts[0].trim();
    }

    if (parts.length > 1) {
      // Check if second part looks like duration (contains "days", "weeks", etc.)
      if (parts[1].toLowerCase().contains(RegExp(r'\d+\s*(day|week|month)'))) {
        result['duration'] = parts[1].trim();

        // If there's a third part, it's notes
        if (parts.length > 2) {
          result['notes'] = parts.sublist(2).join(' - ').trim();
        }
      } else {
        // Second part is notes
        result['notes'] = parts.sublist(1).join(' - ').trim();
      }
    }

    return result;
  }

  Widget _buildActionButtons(PrescriptionModel prescription) {
    final controller = Get.find<PrescriptionDetailController>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Download Button
          if (prescription.prescriptionRawUrl != null ||
              prescription.compiledPrescriptionUrl != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.downloadPrescriptionPdf(
                  prescriptionId: prescription.prescriptionId,
                ),
                icon: const Icon(Icons.download, size: 18),
                label: AppText.buttonMedium('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RubyColors.primary1,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          const SizedBox(width: 12),

          // Share Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => controller.sharePrescription(),
              icon: const Icon(Icons.share, size: 18),
              label: AppText.buttonMedium('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RubyColors.primary2,
                side: const BorderSide(color: RubyColors.primary2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
