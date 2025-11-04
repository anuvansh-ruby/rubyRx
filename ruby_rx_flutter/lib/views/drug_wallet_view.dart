import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/drug_wallet_controller.dart';
import '../common/color_pallet/color_pallet.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/components/notification_card.dart';
import '../common/widgets/app_text.dart';
import '../models/drug_wallet_model.dart';

/// Drug Wallet View
/// Displays patient's complete medicine history from all prescriptions
class DrugWalletView extends StatelessWidget {
  const DrugWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DrugWalletController());

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Notifications
              NotificationCardsList(
                controller: controller.notificationController,
              ),

              // App Bar
              AppNavigationBar.simple(
                title: 'Drug Wallet',
                onBackPressed: () => Get.back(),
              ),

              // Content
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildLoadingState(context);
                  }

                  if (controller.hasError.value) {
                    return _buildErrorState(context, controller);
                  }

                  if (controller.medicines.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildMedicinesList(context, controller);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loading State
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(RubyColors.primary1),
          ),
          const SizedBox(height: 20),
          AppText.bodyLarge(
            'Loading your medicine wallet...',
            color: RubyColors.getTextColor(context),
          ),
        ],
      ),
    );
  }

  /// Error State
  Widget _buildErrorState(
    BuildContext context,
    DrugWalletController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: RubyColors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            AppText.heading3(
              'Error Loading Drug Wallet',
              color: RubyColors.getTextColor(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AppText.bodyMedium(
              controller.errorMessage.value,
              color: RubyColors.getTextColor(context).withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: controller.loadDrugWallet,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RubyColors.primary1,
                foregroundColor: RubyColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 100,
              color: RubyColors.primary1.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            AppText.heading3(
              'Your Drug Wallet is Empty',
              color: RubyColors.getTextColor(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AppText.bodyMedium(
              'Add prescriptions to see your medicine history here',
              color: RubyColors.getTextColor(context).withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/home'),
              icon: const Icon(Icons.add),
              label: const Text('Add Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RubyColors.primary1,
                foregroundColor: RubyColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Medicines List with Statistics
  Widget _buildMedicinesList(
    BuildContext context,
    DrugWalletController controller,
  ) {
    return RefreshIndicator(
      onRefresh: controller.refreshDrugWallet,
      color: RubyColors.primary1,
      child: CustomScrollView(
        slivers: [
          // Statistics Header
          SliverToBoxAdapter(
            child: _buildStatisticsHeader(context, controller),
          ),

          // Search Bar
          SliverToBoxAdapter(child: _buildSearchBar(context, controller)),

          // Sort and Filter Bar
          SliverToBoxAdapter(child: _buildSortFilterBar(context, controller)),

          // Medicines List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == controller.medicines.length) {
                  // Load more indicator
                  if (controller.canLoadMore) {
                    return _buildLoadMoreButton(context, controller);
                  }
                  return const SizedBox(height: 20);
                }

                final medicine = controller.medicines[index];
                return _buildMedicineCard(context, medicine);
              }, childCount: controller.medicines.length + 1),
            ),
          ),
        ],
      ),
    );
  }

  /// Statistics Header
  Widget _buildStatisticsHeader(
    BuildContext context,
    DrugWalletController controller,
  ) {
    final stats = controller.statistics.value;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [RubyColors.primary1, RubyColors.primary2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RubyColors.primary1.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: RubyColors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: AppText.heading3(
                  'Medicine Dashboard',
                  color: RubyColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  stats.totalMedicines.toString(),
                  'Total',
                  Icons.medication,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  stats.uniqueMedicines.toString(),
                  'Unique',
                  Icons.category,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  stats.totalPrescriptions.toString(),
                  'Prescriptions',
                  Icons.receipt_long,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  stats.totalDoctors.toString(),
                  'Doctors',
                  Icons.local_hospital,
                ),
              ),
            ],
          ),
          if (stats.medicinesWithOverlaps > 0) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RubyColors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RubyColors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: RubyColors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText.bodyMedium(
                      '${stats.medicinesWithOverlaps} ${stats.medicinesWithOverlaps == 1 ? 'medicine has' : 'medicines have'} shared compositions',
                      color: RubyColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (stats.firstPrescriptionDate != null) ...[
            const SizedBox(height: 15),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            AppText.caption(
              'Medical history span: ${stats.historyDuration}',
              color: RubyColors.white.withOpacity(0.9),
            ),
          ],
        ],
      ),
    );
  }

  /// Stat Item
  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: RubyColors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 8),
        AppText.heading2(value, color: RubyColors.white),
        const SizedBox(height: 4),
        AppText.caption(
          label,
          color: RubyColors.white.withOpacity(0.8),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Search Bar
  Widget _buildSearchBar(
    BuildContext context,
    DrugWalletController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Search medicines...',
          prefixIcon: Icon(Icons.search, color: RubyColors.primary1),
          suffixIcon: Obx(
            () => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: RubyColors.red),
                    onPressed: controller.clearSearch,
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: RubyColors.getCardBackgroundColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: RubyColors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: RubyColors.primary1, width: 2),
          ),
        ),
        onSubmitted: controller.searchMedicines,
      ),
    );
  }

  /// Sort and Filter Bar
  Widget _buildSortFilterBar(
    BuildContext context,
    DrugWalletController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => AppText.bodyMedium(
                controller.statisticsSummary,
                color: RubyColors.getTextColor(context).withOpacity(0.7),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.sort, color: RubyColors.primary1),
            onPressed: () => controller.showSortOptions(context),
            tooltip: 'Sort options',
          ),
        ],
      ),
    );
  }

  /// Medicine Card
  Widget _buildMedicineCard(BuildContext context, MedicineWalletItem medicine) {
    // Determine if medicine has warning
    final hasWarning = medicine.hasCompositionOverlap;
    final borderColor = hasWarning ? RubyColors.red : Colors.transparent;
    final backgroundColor = hasWarning
        ? RubyColors.red.withOpacity(0.05)
        : RubyColors.getCardBackgroundColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: hasWarning ? 2 : 0),
        boxShadow: [
          BoxShadow(
            color: hasWarning
                ? RubyColors.red.withOpacity(0.15)
                : RubyColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to prescription detail
            Get.toNamed(
              '/prescription-detail/${medicine.prescription.prescriptionId}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banner if medicine has composition overlap
                if (hasWarning) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: RubyColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: RubyColors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: RubyColors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText.caption(
                            medicine.warningMessage,
                            color: RubyColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Medicine Name and Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasWarning
                            ? RubyColors.red.withOpacity(0.1)
                            : RubyColors.primary1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: hasWarning
                            ? RubyColors.red
                            : RubyColors.primary1,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subtitle1(
                            medicine.medicineName,
                            color: hasWarning
                                ? RubyColors.red
                                : RubyColors.getTextColor(context),
                          ),
                          const SizedBox(height: 4),
                          AppText.caption(
                            medicine.dateDisplay,
                            color: RubyColors.getTextColor(
                              context,
                            ).withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (medicine.medicineSalt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.science,
                    'Composition',
                    medicine.medicineSalt!,
                  ),
                ],

                if (medicine.medicineFrequency != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.schedule,
                    'Frequency',
                    medicine.frequencyDisplay,
                  ),
                ],

                if (medicine.doctor != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildDoctorInfo(context, medicine.doctor!),
                ],

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildPrescriptionInfo(context, medicine.prescription),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Info Row
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: RubyColors.primary1.withOpacity(0.7)),
        const SizedBox(width: 8),
        AppText.caption(
          '$label: ',
          color: RubyColors.getTextColor(context).withOpacity(0.6),
        ),
        Expanded(
          child: AppText.bodyMedium(
            value,
            color: RubyColors.getTextColor(context),
          ),
        ),
      ],
    );
  }

  /// Doctor Info
  Widget _buildDoctorInfo(BuildContext context, DoctorInfo doctor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RubyColors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.person, color: RubyColors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(
                doctor.displayName,
                color: RubyColors.getTextColor(context),
              ),
              if (doctor.doctorSpecialization != null) ...[
                const SizedBox(height: 2),
                AppText.caption(
                  doctor.doctorSpecialization!,
                  color: RubyColors.getTextColor(context).withOpacity(0.6),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Prescription Info
  Widget _buildPrescriptionInfo(
    BuildContext context,
    PrescriptionInfo prescription,
  ) {
    return Row(
      children: [
        Icon(
          Icons.receipt,
          size: 16,
          color: RubyColors.primary1.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        AppText.caption(
          'Prescription Date: ${prescription.formattedDate}',
          color: RubyColors.getTextColor(context).withOpacity(0.6),
        ),
        const Spacer(),
        Icon(Icons.arrow_forward_ios, size: 14, color: RubyColors.primary1),
      ],
    );
  }

  /// Load More Button
  Widget _buildLoadMoreButton(
    BuildContext context,
    DrugWalletController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Obx(
        () => controller.isLoadingMore.value
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    RubyColors.primary1,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: controller.loadMoreMedicines,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RubyColors.primary1.withOpacity(0.1),
                  foregroundColor: RubyColors.primary1,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.expand_more),
                    const SizedBox(width: 8),
                    Obx(() => Text('Load More • ${controller.pageInfo}')),
                  ],
                ),
              ),
      ),
    );
  }
}
