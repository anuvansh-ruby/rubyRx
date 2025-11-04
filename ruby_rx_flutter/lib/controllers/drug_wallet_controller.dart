import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/drug_wallet_model.dart';
import '../services/drug_wallet_service.dart';
import '../common/components/notification_card.dart';

/// Drug Wallet Controller
/// Manages patient's medicine wallet state and operations
class DrugWalletController extends GetxController {
  final DrugWalletService _drugWalletService = Get.find<DrugWalletService>();

  // Notification controller for card-based notifications
  final NotificationController notificationController =
      NotificationController();

  // Observable states
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final medicines = <MedicineWalletItem>[].obs;
  final statistics = Rx<DrugWalletStatistics?>(null);
  final pagination = Rx<PaginationInfo?>(null);
  final filters = Rx<FilterInfo?>(null);

  // Search and filter states
  final searchController = TextEditingController();
  final isSearching = false.obs;
  final searchQuery = ''.obs;

  // Sort states
  final sortBy = 'date'.obs;
  final sortOrder = 'desc'.obs;

  // Error state
  final errorMessage = ''.obs;
  final hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('💊 DrugWalletController initialized');
    loadDrugWallet();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load drug wallet data (first page)
  Future<void> loadDrugWallet() async {
    try {
      print('\n========================================');
      print('💊 Loading Drug Wallet');
      print('========================================');

      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await _drugWalletService.getDrugWallet(
        page: 1,
        limit: 20,
        sortBy: sortBy.value,
        order: sortOrder.value,
        filter: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      if (response.success && response.data != null) {
        medicines.value = response.data!.medicines;
        statistics.value = response.data!.statistics;
        pagination.value = response.data!.pagination;
        filters.value = response.data!.filters;

        print('✅ Drug wallet loaded successfully');
        print('   - Medicines: ${medicines.length}');
        print('   - Total: ${statistics.value?.totalMedicines ?? 0}');

        if (medicines.isEmpty) {
          notificationController.showInfo(
            'No Medicines Found',
            'Your drug wallet is empty. Add prescriptions to see medicines here.',
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        hasError.value = true;
        errorMessage.value = response.message;

        print('❌ Failed to load drug wallet: ${response.message}');

        notificationController.showError(
          'Error Loading Drug Wallet',
          response.message,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading drug wallet: $e';

      print('❌ Exception in loadDrugWallet: $e');

      notificationController.showError(
        'Unexpected Error',
        'Failed to load drug wallet. Please try again.',
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      print('========================================\n');
    }
  }

  /// Refresh drug wallet
  Future<void> refreshDrugWallet() async {
    print('🔄 Refreshing drug wallet...');
    await loadDrugWallet();
  }

  /// Load more medicines (pagination)
  Future<void> loadMoreMedicines() async {
    if (isLoadingMore.value || pagination.value == null) {
      return;
    }

    if (!pagination.value!.hasNext) {
      print('📄 No more pages to load');
      return;
    }

    try {
      print('📄 Loading more medicines...');

      isLoadingMore.value = true;
      final nextPage = pagination.value!.currentPage + 1;

      final response = await _drugWalletService.loadMoreMedicines(
        nextPage: nextPage,
        limit: 20,
        sortBy: sortBy.value,
        order: sortOrder.value,
        filter: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      if (response.success && response.data != null) {
        medicines.addAll(response.data!.medicines);
        pagination.value = response.data!.pagination;

        print('✅ Loaded ${response.data!.medicines.length} more medicines');
      } else {
        notificationController.showError(
          'Error Loading More',
          response.message,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ Exception in loadMoreMedicines: $e');
      notificationController.showError(
        'Error',
        'Failed to load more medicines',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Search medicines
  Future<void> searchMedicines(String query) async {
    searchQuery.value = query;

    if (query.isEmpty) {
      // Clear search and reload all
      await loadDrugWallet();
      return;
    }

    try {
      print('🔍 Searching: $query');

      isSearching.value = true;
      hasError.value = false;

      final response = await _drugWalletService.searchMedicines(
        query,
        page: 1,
        limit: 20,
      );

      if (response.success && response.data != null) {
        medicines.value = response.data!.medicines;
        pagination.value = response.data!.pagination;
        filters.value = response.data!.filters;

        print('✅ Search completed: ${medicines.length} results');

        if (medicines.isEmpty) {
          notificationController.showInfo(
            'No Results',
            'No medicines found matching "$query"',
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        notificationController.showError(
          'Search Failed',
          response.message,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ Exception in searchMedicines: $e');
      notificationController.showError(
        'Search Error',
        'Failed to search medicines',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadDrugWallet();
  }

  /// Change sort order
  Future<void> changeSortOrder(String newSortBy, String newOrder) async {
    if (sortBy.value == newSortBy && sortOrder.value == newOrder) {
      return;
    }

    print('🔄 Changing sort: $newSortBy $newOrder');

    sortBy.value = newSortBy;
    sortOrder.value = newOrder;

    await loadDrugWallet();
  }

  /// Toggle sort order for current sort field
  Future<void> toggleSortOrder() async {
    final newOrder = sortOrder.value == 'desc' ? 'asc' : 'desc';
    await changeSortOrder(sortBy.value, newOrder);
  }

  /// Sort by date
  Future<void> sortByDate({bool ascending = false}) async {
    await changeSortOrder('date', ascending ? 'asc' : 'desc');
  }

  /// Sort by name
  Future<void> sortByName({bool ascending = true}) async {
    await changeSortOrder('name', ascending ? 'asc' : 'desc');
  }

  /// Sort by doctor
  Future<void> sortByDoctor({bool ascending = true}) async {
    await changeSortOrder('doctor', ascending ? 'asc' : 'desc');
  }

  /// Show sort options dialog
  void showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSortOption(context, 'Date', 'date', Icons.calendar_today),
            _buildSortOption(
              context,
              'Medicine Name',
              'name',
              Icons.medical_services,
            ),
            _buildSortOption(context, 'Doctor Name', 'doctor', Icons.person),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Order:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ChoiceChip(
                  label: const Text('Ascending'),
                  selected: sortOrder.value == 'asc',
                  onSelected: (selected) {
                    if (selected) {
                      changeSortOrder(sortBy.value, 'asc');
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Descending'),
                  selected: sortOrder.value == 'desc',
                  onSelected: (selected) {
                    if (selected) {
                      changeSortOrder(sortBy.value, 'desc');
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = sortBy.value == value;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        changeSortOrder(value, sortOrder.value);
        Navigator.pop(context);
      },
    );
  }

  /// Get formatted statistics summary
  String get statisticsSummary {
    if (statistics.value == null) return '';

    final stats = statistics.value!;
    return '${stats.uniqueMedicines} unique medicines from ${stats.totalPrescriptions} prescriptions';
  }

  /// Check if can load more
  bool get canLoadMore {
    return pagination.value?.hasNext ?? false;
  }

  /// Get current page info
  String get pageInfo {
    if (pagination.value == null) return '';

    final page = pagination.value!;
    return 'Page ${page.currentPage} of ${page.totalPages}';
  }
}
