import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import 'package:ruby_rx_flutter/models/prescription_detail_model.dart';
import 'package:ruby_rx_flutter/services/medicine_substitute_service.dart';
import 'package:ruby_rx_flutter/controllers/prescription_detail_controller.dart';

class MedicineDetailDialog {
  static void show({
    required BuildContext context,
    required PatientMedicineModelData medicine,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MedicineDetailContent(medicine: medicine),
    );
  }
}

class _MedicineDetailContent extends StatefulWidget {
  final PatientMedicineModelData medicine;

  const _MedicineDetailContent({required this.medicine});

  @override
  State<_MedicineDetailContent> createState() => _MedicineDetailContentState();
}

class _MedicineDetailContentState extends State<_MedicineDetailContent> {
  bool _isLoadingSubstitutes = false;
  List<MedicineSubstituteModel> _substitutes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubstitutes();
  }

  Future<void> _loadSubstitutes() async {
    // Debug: Print medicine data
    print('🔍 Medicine Details:');
    print('   Name: ${widget.medicine.medicineName}');
    print('   med_drug_id: ${widget.medicine.medDrugId}');
    print('   composition1Id: ${widget.medicine.composition1Id}');
    print('   composition2Id: ${widget.medicine.composition2Id}');
    print('   composition1Name: ${widget.medicine.composition1Name}');
    print('   compositionInfo: ${widget.medicine.compositionInfo}');

    // Check if medicine has composition data
    if (widget.medicine.composition1Id == null ||
        widget.medicine.composition1Id!.isEmpty ||
        widget.medicine.composition1Id == '0') {
      print('❌ No valid composition ID - cannot load substitutes');
      setState(() {
        _errorMessage =
            'Composition information not available for this medicine';
      });
      return;
    }

    print('✅ Valid composition ID found, loading substitutes...');

    setState(() {
      _isLoadingSubstitutes = true;
      _errorMessage = null;
    });

    try {
      final controller = Get.find<PrescriptionDetailController>();

      // Prepare composition2Id - only pass if valid
      String? comp2Id;
      if (widget.medicine.composition2Id != null &&
          widget.medicine.composition2Id!.isNotEmpty &&
          widget.medicine.composition2Id != '0') {
        comp2Id = widget.medicine.composition2Id;
      }

      print('🔍 Calling substitutes API with:');
      print('   composition1Id: ${widget.medicine.composition1Id}');
      print('   composition2Id: $comp2Id');
      print('   excludeMedId: ${widget.medicine.medDrugId}');

      // Use composition IDs from the medicine model
      final substitutes = await controller.loadMedicineSubstitutes(
        compositionId1: widget.medicine.composition1Id!,
        compositionId2: comp2Id,
        excludeMedId: widget.medicine.medDrugId,
      );

      print('📊 Received ${substitutes.length} substitutes');

      // Sort substitutes by price in ascending order
      substitutes.sort((a, b) {
        // Handle null prices - put them at the end
        if (a.price == null && b.price == null) return 0;
        if (a.price == null) return 1;
        if (b.price == null) return -1;
        return a.price!.compareTo(b.price!);
      });

      setState(() {
        _substitutes = substitutes;
        _isLoadingSubstitutes = false;
        if (substitutes.isEmpty) {
          _errorMessage = 'No substitutes found for this medicine';
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error loading substitutes: $e');
      print('📚 Stack trace: $stackTrace');
      setState(() {
        _isLoadingSubstitutes = false;
        _errorMessage = 'Failed to load substitutes: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.heading3(
                            'Medicine Details',
                            color: RubyColors.black,
                          ),
                          const SizedBox(height: 4),
                          AppText.bodySmall(
                            'View details and alternatives',
                            color: RubyColors.grey,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: RubyColors.grey,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Information Card
                      _buildMedicineInfoCard(),

                      const SizedBox(height: 24),

                      // Substitutes Section
                      _buildSubstitutesSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicineInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine name with icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RubyColors.primary1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.heading4(
                      widget.medicine.medicineName,
                      color: RubyColors.black,
                    ),
                    if (widget.medicine.medicineSalt != null) ...[
                      const SizedBox(height: 6),
                      AppText.bodySmall(
                        widget.medicine.medicineSalt!,
                        color: RubyColors.grey,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Composition
          if (widget.medicine.compositionInfo.isNotEmpty) ...[
            _buildInfoRow(
              Icons.science_outlined,
              'Composition',
              widget.medicine.compositionInfo,
            ),
            const SizedBox(height: 12),
          ],

          // Frequency
          if (widget.medicine.medicineFrequency != null)
            _buildInfoRow(
              Icons.access_time,
              'Frequency',
              widget.medicine.medicineFrequency!,
            ),

          // Duration
          if (widget.medicine.duration != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Duration',
              widget.medicine.duration!,
            ),
          ],

          // Notes
          if (widget.medicine.notes != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: RubyColors.primary1,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Instructions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RubyColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppText.bodySmall(
                        widget.medicine.notes!,
                        color: RubyColors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: RubyColors.primary1),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: RubyColors.black,
                    fontFamily: 'Inter',
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: RubyColors.grey,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubstitutesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.swap_horiz, color: RubyColors.primary1, size: 24),
            const SizedBox(width: 8),
            AppText.heading4('Available Substitutes', color: RubyColors.black),
          ],
        ),
        const SizedBox(height: 8),
        AppText.bodySmall(
          'Medicines with the same composition',
          color: RubyColors.grey,
        ),
        const SizedBox(height: 16),

        // Loading or Error State
        if (_isLoadingSubstitutes)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: RubyColors.primary1),
            ),
          )
        else if (_errorMessage != null)
          _buildEmptyState(_errorMessage!)
        else if (_substitutes.isEmpty)
          _buildEmptyState('No substitutes available')
        else
          // Substitutes List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _substitutes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final substitute = _substitutes[index];
              return _buildSubstituteCard(substitute);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          AppText.bodyMedium(
            message,
            color: RubyColors.grey,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubstituteCard(MedicineSubstituteModel substitute) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine name and price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      substitute.medName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: RubyColors.black,
                      ),
                    ),
                    if (substitute.displayInfo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AppText.bodySmall(
                        substitute.displayInfo,
                        color: RubyColors.grey,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 12,
              //     vertical: 6,
              //   ),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFE8F5E9),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Text(
              //     substitute.priceInfo,
              //     style: const TextStyle(
              //       fontSize: 12,
              //       color: Color(0xFF2E7D32),
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
            ],
          ),

          // Composition
          if (substitute.compositionInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 16,
                    color: RubyColors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppText.bodySmall(
                      substitute.compositionInfo,
                      color: RubyColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Pack size
          if (substitute.packSize != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: RubyColors.grey,
                ),
                const SizedBox(width: 6),
                AppText.bodySmall(
                  'Pack: ${substitute.packSize}',
                  color: RubyColors.grey,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
