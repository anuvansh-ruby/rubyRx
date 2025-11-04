import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/components/floating_actions.dart';
import '../controllers/prescription_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../models/prescription_model.dart';

class PrescriptionManagerView extends StatelessWidget {
  const PrescriptionManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final PrescriptionController controller = Get.put(PrescriptionController());

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Navigation Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppNavigationBar.profile(
                  title: 'Saved Prescriptions',
                  onBackPressed: controller.navigateBack,
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSearchBar(controller),
              ),

              const SizedBox(height: 16),

              // Prescription List
              Expanded(
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4),
                          ),
                        )
                      : controller.filteredPrescriptions.isEmpty
                      ? RefreshIndicator(
                          onRefresh: controller.refreshPrescriptions,
                          color: Color(0xFF00BCD4),
                          backgroundColor: Colors.white,
                          strokeWidth: 3.0,
                          displacement: 40.0,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: _buildEmptyState(),
                            ),
                          ),
                        )
                      : _buildPrescriptionList(controller),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        onHomePressed: () {
          Get.toNamed('/home');
        },
        onPrescriptionPressed: () {
          Get.toNamed('/prescription-manager');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSearchBar(PrescriptionController controller) {
    return TextField(
      onChanged: controller.searchPrescriptions,
      decoration: InputDecoration(
        hintText: 'Search prescriptions...',
        hintStyle: const TextStyle(color: Color(0xFF7F8C8D)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF7F8C8D)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildPrescriptionList(PrescriptionController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshPrescriptions,
      color: const Color(0xFF00BCD4),
      backgroundColor: Colors.white,
      strokeWidth: 3.0,
      displacement: 40.0,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.filteredPrescriptions.length,
        itemBuilder: (context, index) {
          final prescription = controller.filteredPrescriptions[index];
          return _buildPrescriptionCard(prescription, controller);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(
    PrescriptionModel prescription,
    PrescriptionController controller,
  ) {
    // Get medicine count text
    String medicineCountText = '1 medicine';
    if (prescription.medicineCount != null) {
      final count = prescription.medicineCount!;
      medicineCountText = count == 1 ? '1 medicine' : '$count medicines';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => controller.viewPrescription(prescription),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Name
                    Text(
                      prescription.displayDoctorName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Condition/Diagnosis (if available)
                    if (prescription.doctorSpecialization != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          prescription.doctorSpecialization!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF7F8C8D),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                    // Date and Medicine Count Row
                    Row(
                      children: [
                        // Date
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF00BCD4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prescription.visitDate,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Medicine Count
                        const Icon(
                          Icons.medication,
                          size: 16,
                          color: Color(0xFF00BCD4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          medicineCountText,
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

              // Chevron Icon
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF7F8C8D),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 40,
                color: Color(0xFF00BCD4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Prescriptions Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your prescription history will appear here.\nPrescriptions you create or receive will be listed below.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh or create a new prescription',
              style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Get.find<PrescriptionController>().createNewPrescription(),
              icon: const Icon(Icons.add),
              label: const Text(
                'Create New Prescription',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
