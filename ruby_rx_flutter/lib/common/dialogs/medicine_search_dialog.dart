import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/color_pallet/color_pallet.dart';
import '../../common/widgets/app_text.dart';
import '../../services/medicine_data_service.dart';

class MedicineSearchDialog extends StatefulWidget {
  final int medicationIndex;
  final Function(MedicineSearchModel, int) onMedicineSelected;

  const MedicineSearchDialog({
    Key? key,
    required this.medicationIndex,
    required this.onMedicineSelected,
  }) : super(key: key);

  @override
  State<MedicineSearchDialog> createState() => _MedicineSearchDialogState();
}

class _MedicineSearchDialogState extends State<MedicineSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<MedicineSearchModel> _searchResults =
      <MedicineSearchModel>[].obs;
  final RxBool _isSearching = false.obs;
  final RxString _currentQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadInitialMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load initial medicines for the dialog
  Future<void> _loadInitialMedicines() async {
    try {
      _isSearching.value = true;
      _currentQuery.value = '';

      List<MedicineSearchModel> medicines = [];

      // Try popular medicines first, fallback to common search
      try {
        medicines = await MedicineDataService.getPopularMedicines(limit: 10);
      } catch (e) {
        // Fallback to common medicine search
        medicines = await MedicineDataService.searchMedicines(
          query: 'paracetamol',
          limit: 10,
        );
      }

      _searchResults.value = medicines;
    } catch (e) {
      print('❌ Error loading initial medicines: $e');
      _searchResults.clear();
    } finally {
      _isSearching.value = false;
    }
  }

  /// Search medicines based on query
  Future<void> _searchMedicines(String query) async {
    if (query.trim().length < 2) {
      _searchResults.clear();
      _currentQuery.value = '';
      return;
    }

    try {
      _isSearching.value = true;
      _currentQuery.value = query;

      final results = await MedicineDataService.searchMedicines(
        query: query,
        limit: 20,
      );

      _searchResults.value = results;
    } catch (e) {
      print('❌ Error searching medicines: $e');
      Get.snackbar(
        'Search Error',
        'Failed to search medicines: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSearching.value = false;
    }
  }

  /// Handle medicine selection
  void _selectMedicine(MedicineSearchModel medicine) {
    widget.onMedicineSelected(medicine, widget.medicationIndex);
    Navigator.of(context).pop();
  }

  /// Clear search and reload initial medicines
  void _clearSearch() {
    _searchController.clear();
    _currentQuery.value = '';
    _loadInitialMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.search, color: RubyColors.primary2),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText.heading6(
                    'Search Medicine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type medicine name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => _currentQuery.value.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: RubyColors.primary2,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                _currentQuery.value = value;
                if (value.trim().isEmpty) {
                  _loadInitialMedicines();
                } else if (value.trim().length >= 2) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchMedicines(value);
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Results Title
            Obx(
              () => Align(
                alignment: Alignment.centerLeft,
                child: AppText.heading6(
                  _searchResults.isEmpty
                      ? 'No medicines found'
                      : _currentQuery.value.isEmpty
                      ? 'Popular Medicines'
                      : 'Search Results',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Search Results
            Expanded(
              child: Obx(() {
                if (_isSearching.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: RubyColors.primary2),
                        SizedBox(height: 16),
                        AppText.bodyMedium(
                          'Loading medicines...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }

                if (_searchResults.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        AppText.bodyLarge(
                          'No medicines found',
                          color: Colors.grey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        AppText.bodyMedium(
                          'Try a different search term',
                          color: Colors.grey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final medicine = _searchResults[index];
                    return _buildMedicineItem(medicine);
                  },
                );
              }),
            ),

            // Bottom Close Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RubyColors.primary2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const AppText.bodyMedium('Close', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineItem(MedicineSearchModel medicine) {
    // Build composition display from all available compositions
    final compositions = <String>[];
    if (medicine.medCompositionName1 != null &&
        medicine.medCompositionName1!.isNotEmpty) {
      String comp = medicine.medCompositionName1!;
      if (medicine.medCompositionStrength1 != null &&
          medicine.medCompositionStrength1!.isNotEmpty) {
        comp += ' ${medicine.medCompositionStrength1!}';
        if (medicine.medCompositionUnit1 != null &&
            medicine.medCompositionUnit1!.isNotEmpty) {
          comp += medicine.medCompositionUnit1!;
        }
      }
      compositions.add(comp);
    }
    if (medicine.medCompositionName2 != null &&
        medicine.medCompositionName2!.isNotEmpty) {
      String comp = medicine.medCompositionName2!;
      if (medicine.medCompositionStrength2 != null &&
          medicine.medCompositionStrength2!.isNotEmpty) {
        comp += ' ${medicine.medCompositionStrength2!}';
        if (medicine.medCompositionUnit2 != null &&
            medicine.medCompositionUnit2!.isNotEmpty) {
          comp += medicine.medCompositionUnit2!;
        }
      }
      compositions.add(comp);
    }
    final compositionText = compositions.isNotEmpty
        ? compositions.join(' + ')
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: AppText.bodyMedium(
          medicine.medBrandName ??
              medicine.medGenericName ??
              'Unknown Medicine',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compositionText.isNotEmpty) ...[
              const SizedBox(height: 2),
              AppText.linkText(
                compositionText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color: RubyColors.primary2,
              ),
            ],
            if (medicine.medManufacturerName != null &&
                medicine.medManufacturerName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              AppText.bodyUltraSmall(
                'By: ${medicine.medManufacturerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color: Colors.grey[600],
              ),
            ],
          ],
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RubyColors.primary2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () => _selectMedicine(medicine),
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        onTap: () => _selectMedicine(medicine),
      ),
    );
  }
}
