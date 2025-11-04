import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import 'package:ruby_rx_flutter/common/components/app_navigation_bar.dart';
import 'package:ruby_rx_flutter/common/components/gradient_background.dart';
import '../controllers/manual_entry_controller.dart';
import '../common/components/notification_card.dart';
import '../common/components/app_button.dart';
import '../common/components/app_text_field_with_label.dart';
import '../common/components/app_dropdown_with_label.dart';

class ManualEntryView extends StatelessWidget {
  const ManualEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    final ManualEntryController controller = Get.put(ManualEntryController());

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Navigation Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppNavigationBar.profile(
                  title: 'Your Prescription',
                  onBackPressed: controller.navigateBack,
                ),
              ),

              // Notification cards at the top
              NotificationCardsList(
                controller: controller.notificationController,
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // OCR Information Banner (if applicable)
                      Obx(
                        () => controller.isOcrPrefilled.value
                            ? _buildOcrInfoBanner(context, controller)
                            : const SizedBox.shrink(),
                      ),

                      // Doctor Information Section
                      _buildDoctorInformationSection(context, controller),
                      const SizedBox(height: 20),

                      // Medications Section
                      _buildMedicationsSection(context, controller),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: Obx(
          () => AppButton(
            onPressed: controller.isSaving.value
                ? null
                : controller.savePrescription,
            label: controller.isSaving.value
                ? 'Saving...'
                : 'Save Prescription',
            isDisabled: controller.isSaving.value,
            color: RubyColors.primary1,
            borderRadius: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInformationSection(
    BuildContext context,
    ManualEntryController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading4(
            'Prescription Details',
            color: RubyColors.getTextColor(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Doctor Name
          AppTextFieldWithLabel.standard(
            label: 'Doctor Name *',
            controller: controller.doctorNameController,
            hintText: 'Enter doctor name',
          ),
          const SizedBox(height: 16),

          // Doctor Number
          AppTextFieldWithLabel.standard(
            label: 'Doctor Number *',
            controller: controller.doctorNumberController,
            hintText: 'Enter doctor phone number',
          ),
          const SizedBox(height: 16),

          // Appointment Date
          AppTextFieldWithLabel.standard(
            label: 'Appointment Date *',
            controller: controller.appointmentDateController,
            hintText: 'Select appointment date',
            readOnly: true,
            onTap: () => controller.selectAppointmentDate(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          const SizedBox(height: 16),

          // Clinic Address (Optional)
          AppTextFieldWithLabel.standard(
            label: 'Clinic Address',
            controller: controller.clinicAddressController,
            hintText: 'Enter clinic address (optional)',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsSection(
    BuildContext context,
    ManualEntryController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.heading4(
                'Medications',
                color: RubyColors.getTextColor(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              ElevatedButton(
                onPressed: controller.addMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RubyColors.primary1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: AppText.buttonMedium('Add', color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Medications List
          Obx(
            () => Column(
              children: controller.medications
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                        _buildMedicationCard(context, controller, entry.key),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    ManualEntryController controller,
    int index,
  ) {
    final medication = controller.medications[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.heading5(
                'Medication ${index + 1}',
                color: RubyColors.getTextColor(context),
              ),
              if (index > 0)
                IconButton(
                  onPressed: () => controller.removeMedication(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Medication Name with Search
          _buildMedicineNameFieldWithSearch(
            label: 'Medication Name *',
            controller: medication.nameController,
            hintText: 'Enter medicine name',
            medicationIndex: index,
          ),
          const SizedBox(height: 12),

          // Dosage and Frequency
          Row(
            children: [
              // Expanded(
              //   child: _buildTextFieldWithLabel(
              //     label: 'Dosage',
              //     controller: medication.dosageController,
              //     hintText: 'e.g., 500mg',
              //   ),
              // ),
              // const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => AppDropdownWithLabel_.standard(
                    label: 'Frequency',
                    value: medication.selectedFrequency.value.isEmpty
                        ? null
                        : medication.selectedFrequency.value,
                    items: MedicalDropdownOptions.frequency,
                    hintText: 'Select frequency',
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        medication.selectedFrequency.value = newValue;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration
          Obx(
            () => AppDropdownWithLabel_.standard(
              label: 'Duration',
              value: medication.selectedDuration.value.isEmpty
                  ? null
                  : medication.selectedDuration.value,
              items: MedicalDropdownOptions.duration,
              hintText: 'Select duration',
              onChanged: (String? newValue) {
                if (newValue != null) {
                  medication.selectedDuration.value = newValue;
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // Instructions
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(
                'Instructions',
                color: RubyColors.getTextColor(context),
              ),
              const SizedBox(height: 8),
              Container(
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RubyColors.primary1.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: RubyColors.primary1.withOpacity(0.5),
                  ),
                ),
                child: TextField(
                  controller: medication.instructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Take with food',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOcrInfoBanner(
    BuildContext context,
    ManualEntryController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.heading5('AI Scanned Prescription'),
                    AppText.caption(
                      'Extracted from ${controller.ocrSource.value}',
                      color: Colors.grey.shade600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: AppText.caption(
                    'Please review all fields carefully before saving. AI extraction may not be 100% accurate.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build medicine name field with search functionality
  Widget _buildMedicineNameFieldWithSearch({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required int medicationIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(label, color: RubyColors.getTextColor(Get.context!)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: RubyColors.primary1.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RubyColors.primary1.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: RubyColors.getTextColor(
                        Get.context!,
                      ).withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: RubyColors.getTextColor(Get.context!),
                  ),
                  onTap: () {
                    // Open search dialog when user taps on the input field
                    Get.find<ManualEntryController>().showMedicineSearchDialog(
                      medicationIndex,
                    );
                  },
                  readOnly:
                      true, // Make it read-only since we're using dialog for input
                ),
              ),
              // Search button
              Container(
                width: 1,
                height: 30,
                color: RubyColors.primary1.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              GestureDetector(
                onTap: () {
                  Get.find<ManualEntryController>().triggerMedicineSearch(
                    medicationIndex,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.search,
                    color: RubyColors.primary1,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
