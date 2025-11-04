import 'package:get/get.dart';
import '../models/drug_wallet_model.dart';
import '../data/services/api_client.dart';
import '../data/config/app_config.dart';

/// Drug Wallet Service
/// Handles API calls for patient's medicine wallet
class DrugWalletService extends GetxService {
  static String get baseUrl => AppConfig.baseUrl;

  ApiClient? _apiClient;

  @override
  void onInit() {
    super.onInit();
    _initializeApiClient();
  }

  /// Initialize API client safely
  void _initializeApiClient() {
    try {
      _apiClient = Get.find<ApiClient>();
      print('✅ DrugWalletService ApiClient initialized successfully');
    } catch (e) {
      print('❌ Error initializing DrugWalletService ApiClient: $e');
      _apiClient = null;
    }
  }

  /// Get API client with safety check
  ApiClient get apiClient {
    if (_apiClient == null) {
      _initializeApiClient();
    }

    if (_apiClient == null) {
      throw Exception('ApiClient not initialized. Please restart the app.');
    }

    return _apiClient!;
  }

  /// Get patient's drug wallet with all medicines
  ///
  /// Parameters:
  /// - page: Page number for pagination (default: 1)
  /// - limit: Number of medicines per page (default: 20)
  /// - sortBy: Sort field - 'date', 'name', 'doctor' (default: 'date')
  /// - order: Sort order - 'asc' or 'desc' (default: 'desc')
  /// - filter: Filter by medicine name (optional)
  Future<DrugWalletResponse> getDrugWallet({
    int page = 1,
    int limit = 20,
    String sortBy = 'date',
    String order = 'desc',
    String? filter,
  }) async {
    try {
      print('\n========================================');
      print('💊 DRUG WALLET SERVICE - Get Medicines');
      print('========================================');
      print('📄 Page: $page, Limit: $limit');
      print('🔍 Sort: $sortBy $order');
      print('🔎 Filter: ${filter ?? 'None'}');

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort_by': sortBy,
        'order': order,
      };

      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }

      print('📋 Query params: $queryParams');

      // Make API call
      final response = await apiClient.get<Map<String, dynamic>>(
        'v1/patient/drug-wallet',
        (data) => data,
        queryParams: queryParams,
      );

      print('📥 Response received:');
      print('   - Success: ${response.success}');
      print('   - Message: ${response.message}');

      if (response.success && response.data != null) {
        print('✅ Drug wallet data loaded successfully');

        // Parse the response
        final drugWalletResponse = DrugWalletResponse.fromJson({
          'status': 'SUCCESS',
          'message': response.message,
          'data': response.data,
        });

        final medicinesCount = drugWalletResponse.data?.medicines.length ?? 0;
        final totalCount =
            drugWalletResponse.data?.statistics.totalMedicines ?? 0;

        print('📊 Statistics:');
        print('   - Medicines in response: $medicinesCount');
        print('   - Total medicines: $totalCount');
        print(
          '   - Unique medicines: ${drugWalletResponse.data?.statistics.uniqueMedicines ?? 0}',
        );
        print(
          '   - Total prescriptions: ${drugWalletResponse.data?.statistics.totalPrescriptions ?? 0}',
        );
        print(
          '   - Total doctors: ${drugWalletResponse.data?.statistics.totalDoctors ?? 0}',
        );
        print('========================================\n');

        return drugWalletResponse;
      } else {
        print('❌ API Error: ${response.message}');
        print('========================================\n');

        return DrugWalletResponse(
          success: false,
          message: response.message,
          data: null,
          error: response.error,
        );
      }
    } catch (e, stackTrace) {
      print('❌ Exception in getDrugWallet: $e');
      print('📚 Stack trace: $stackTrace');
      print('========================================\n');

      return DrugWalletResponse(
        success: false,
        message: 'Error loading drug wallet: ${e.toString()}',
        data: null,
        error: e.toString(),
      );
    }
  }

  /// Refresh drug wallet (fetch first page with latest data)
  Future<DrugWalletResponse> refreshDrugWallet({
    String sortBy = 'date',
    String order = 'desc',
  }) async {
    print('🔄 Refreshing drug wallet...');
    return getDrugWallet(page: 1, limit: 20, sortBy: sortBy, order: order);
  }

  /// Search medicines in drug wallet
  Future<DrugWalletResponse> searchMedicines(
    String searchQuery, {
    int page = 1,
    int limit = 20,
  }) async {
    print('🔍 Searching medicines: $searchQuery');
    return getDrugWallet(
      page: page,
      limit: limit,
      filter: searchQuery,
      sortBy: 'name',
      order: 'asc',
    );
  }

  /// Load more medicines (pagination)
  Future<DrugWalletResponse> loadMoreMedicines({
    required int nextPage,
    int limit = 20,
    String sortBy = 'date',
    String order = 'desc',
    String? filter,
  }) async {
    print('📄 Loading page $nextPage...');
    return getDrugWallet(
      page: nextPage,
      limit: limit,
      sortBy: sortBy,
      order: order,
      filter: filter,
    );
  }
}

/// Service initialization binding
class DrugWalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DrugWalletService>(() => DrugWalletService());
  }
}
