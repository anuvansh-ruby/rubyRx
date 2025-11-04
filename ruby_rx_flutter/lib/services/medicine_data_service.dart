import 'package:dio/dio.dart';
import '../data/api/api_client.dart';

class MedicineSearchModel {
  final int? medId;
  final String? medBrandName;
  final String? medGenericName;
  final String? medType;
  final String? medManufacturerName;
  final String? medPackSize;
  final double? medPrice;
  final String? medWeightage;
  final int? isActive;

  final String? medCompositionId1;
  final String? medCompositionId2;
  final String? medCompositionId3;
  final String? medCompositionId4;
  final String? medCompositionId5;

  final String? medCompositionName1;
  final String? medCompositionName2;
  final String? medCompositionName3;
  final String? medCompositionName4;
  final String? medCompositionName5;

  final String? medCompositionStrength1;
  final String? medCompositionStrength2;
  final String? medCompositionStrength3;
  final String? medCompositionStrength4;
  final String? medCompositionStrength5;

  final String? medCompositionUnit1;
  final String? medCompositionUnit2;
  final String? medCompositionUnit3;
  final String? medCompositionUnit4;
  final String? medCompositionUnit5;

  final String? drugName;
  final int? matchCount;

  MedicineSearchModel({
    this.medId,
    this.medBrandName,
    this.medGenericName,
    this.medType,
    this.medManufacturerName,
    this.medPackSize,
    this.medPrice,
    this.medWeightage,
    this.isActive,
    this.medCompositionId1,
    this.medCompositionId2,
    this.medCompositionId3,
    this.medCompositionId4,
    this.medCompositionId5,
    this.medCompositionName1,
    this.medCompositionName2,
    this.medCompositionName3,
    this.medCompositionName4,
    this.medCompositionName5,
    this.medCompositionStrength1,
    this.medCompositionStrength2,
    this.medCompositionStrength3,
    this.medCompositionStrength4,
    this.medCompositionStrength5,
    this.medCompositionUnit1,
    this.medCompositionUnit2,
    this.medCompositionUnit3,
    this.medCompositionUnit4,
    this.medCompositionUnit5,
    this.drugName,
    this.matchCount,
  });

  factory MedicineSearchModel.fromJson(Map<String, dynamic> json) {
    return MedicineSearchModel(
      medId: json['med_id'],
      medBrandName: json['med_brand_name'],
      medGenericName: json['med_generic_name'],
      medType: json['med_type'],
      medManufacturerName: json['med_manufacturer_name'],
      medPackSize: json['med_pack_size'],
      medPrice: json['med_price'] != null
          ? double.tryParse(json['med_price'].toString())
          : null,
      medWeightage: json['med_weightage']?.toString(),
      isActive: json['is_active'],

      medCompositionId1: json['med_composition_id_1'],
      medCompositionId2: json['med_composition_id_2'],
      medCompositionId3: json['med_composition_id_3'],
      medCompositionId4: json['med_composition_id_4'],
      medCompositionId5: json['med_composition_id_5'],

      medCompositionName1: json['med_composition_name_1'],
      medCompositionName2: json['med_composition_name_2'],
      medCompositionName3: json['med_composition_name_3'],
      medCompositionName4: json['med_composition_name_4'],
      medCompositionName5: json['med_composition_name_5'],

      medCompositionStrength1: json['med_composition_strength_1'],
      medCompositionStrength2: json['med_composition_strength_2'],
      medCompositionStrength3: json['med_composition_strength_3'],
      medCompositionStrength4: json['med_composition_strength_4'],
      medCompositionStrength5: json['med_composition_strength_5'],

      medCompositionUnit1: json['med_composition_unit_1'],
      medCompositionUnit2: json['med_composition_unit_2'],
      medCompositionUnit3: json['med_composition_unit_3'],
      medCompositionUnit4: json['med_composition_unit_4'],
      medCompositionUnit5: json['med_composition_unit_5'],

      drugName: json['drug_name'],
      matchCount: json['match_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'med_id': medId,
      'med_brand_name': medBrandName,
      'med_generic_name': medGenericName,
      'med_type': medType,
      'med_manufacturer_name': medManufacturerName,
      'med_pack_size': medPackSize,
      'med_price': medPrice,
      'med_weightage': medWeightage,
      'is_active': isActive,

      'med_composition_id_1': medCompositionId1,
      'med_composition_id_2': medCompositionId2,
      'med_composition_id_3': medCompositionId3,
      'med_composition_id_4': medCompositionId4,
      'med_composition_id_5': medCompositionId5,

      'med_composition_name_1': medCompositionName1,
      'med_composition_name_2': medCompositionName2,
      'med_composition_name_3': medCompositionName3,
      'med_composition_name_4': medCompositionName4,
      'med_composition_name_5': medCompositionName5,

      'med_composition_strength_1': medCompositionStrength1,
      'med_composition_strength_2': medCompositionStrength2,
      'med_composition_strength_3': medCompositionStrength3,
      'med_composition_strength_4': medCompositionStrength4,
      'med_composition_strength_5': medCompositionStrength5,

      'med_composition_unit_1': medCompositionUnit1,
      'med_composition_unit_2': medCompositionUnit2,
      'med_composition_unit_3': medCompositionUnit3,
      'med_composition_unit_4': medCompositionUnit4,
      'med_composition_unit_5': medCompositionUnit5,

      'drug_name': drugName,
      'match_count': matchCount,
    };
  }
}

class MedicineDataService {
  static final Dio _dio = ApiClient.instance.dio;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  /// Search medicines from the medicine database
  static Future<List<MedicineSearchModel>> searchMedicines({
    required String query,
    int limit = 20,
    int page = 1,
    String? type,
    String? manufacturer,
  }) async {
    try {
      if (query.trim().length < 2) {
        return [];
      }

      final queryParams = {
        'q': query.trim(),
        'limit': limit.toString(),
        'page': page.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (manufacturer != null && manufacturer.isNotEmpty)
          'manufacturer': manufacturer,
      };

      print(
        '🔍 [MEDICINE_API] Searching medicines with query: ${query.trim()}',
      );

      final response = await _dio.get(
        '/v1/medicines/search',
        queryParameters: queryParams,
        options: Options(
          sendTimeout: _timeoutDuration,
          receiveTimeout: _timeoutDuration,
        ),
      );

      print('🔍 [MEDICINE_API] Search response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('🔍 [MEDICINE_API] Response status: ${data['status']}');

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          final medicines = data['data']['medicines'] as List;
          print('🔍 [MEDICINE_API] Found ${medicines.length} medicines');
          return medicines
              .map((item) => MedicineSearchModel.fromJson(item))
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      print('❌ [MEDICINE_API] Dio error in searchMedicines: ${e.message}');
      print('❌ [MEDICINE_API] Error type: ${e.type}');
      if (e.response != null) {
        print('❌ [MEDICINE_API] Response status: ${e.response?.statusCode}');
        print('❌ [MEDICINE_API] Response data: ${e.response?.data}');
      }
      return [];
    } catch (e) {
      print('❌ [MEDICINE_API] Unexpected error in searchMedicines: $e');
      return [];
    }
  }

  /// Get medicine suggestions for autocomplete
  static Future<List<MedicineSearchModel>> getMedicineSuggestions({
    required String query,
    int limit = 10,
    String? type,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final queryParams = {
        'q': query.trim(),
        'limit': limit.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
      };

      print('💡 [MEDICINE_API] Getting medicine suggestions: ${query.trim()}');

      final response = await _dio.get(
        '/medicine-data/suggestions',
        queryParameters: queryParams,
        options: Options(
          sendTimeout: _timeoutDuration,
          receiveTimeout: _timeoutDuration,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          final suggestions = data['data']['suggestions'] as List;
          print('💡 [MEDICINE_API] Found ${suggestions.length} suggestions');
          return suggestions
              .map((item) => MedicineSearchModel.fromJson(item))
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      print(
        '❌ [MEDICINE_API] Dio error in getMedicineSuggestions: ${e.message}',
      );
      return [];
    } catch (e) {
      print('❌ [MEDICINE_API] Unexpected error in getMedicineSuggestions: $e');
      return [];
    }
  }

  /// Get popular medicines
  static Future<List<MedicineSearchModel>> getPopularMedicines({
    int limit = 20,
    String? type,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
      };

      print('🔥 [MEDICINE_API] Getting popular medicines');

      final response = await _dio.get(
        '/medicine-data/popular',
        queryParameters: queryParams,
        options: Options(
          sendTimeout: _timeoutDuration,
          receiveTimeout: _timeoutDuration,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          final medicines = data['data']['medicines'] as List;
          print(
            '🔥 [MEDICINE_API] Found ${medicines.length} popular medicines',
          );
          return medicines
              .map((item) => MedicineSearchModel.fromJson(item))
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      print('❌ [MEDICINE_API] Dio error in getPopularMedicines: ${e.message}');
      return [];
    } catch (e) {
      print('❌ [MEDICINE_API] Unexpected error in getPopularMedicines: $e');
      return [];
    }
  }

  /// Get medicine by ID
  static Future<MedicineSearchModel?> getMedicineById(int id) async {
    try {
      print('🔍 [MEDICINE_API] Getting medicine by ID: $id');

      final response = await _dio.get(
        '/medicine-data/$id',
        options: Options(
          sendTimeout: _timeoutDuration,
          receiveTimeout: _timeoutDuration,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          print(
            '🔍 [MEDICINE_API] Medicine found: ${data['data']['med_name']}',
          );
          return MedicineSearchModel.fromJson(data['data']);
        }
      }

      return null;
    } on DioException catch (e) {
      print('❌ [MEDICINE_API] Dio error in getMedicineById: ${e.message}');
      return null;
    } catch (e) {
      print('❌ [MEDICINE_API] Unexpected error in getMedicineById: $e');
      return null;
    }
  }

  /// Get medicine types
  static Future<List<String>> getMedicineTypes() async {
    try {
      print('📋 [MEDICINE_API] Getting medicine types');

      final response = await _dio.get(
        '/medicine-data/types',
        options: Options(
          sendTimeout: _timeoutDuration,
          receiveTimeout: _timeoutDuration,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          final types = data['data']['types'] as List;
          final typesList = types
              .map((item) => item['medicin_type'] as String)
              .where((type) => type.isNotEmpty)
              .toList();
          print('📋 [MEDICINE_API] Found ${typesList.length} medicine types');
          return typesList;
        }
      }

      return [];
    } on DioException catch (e) {
      print('❌ [MEDICINE_API] Dio error in getMedicineTypes: ${e.message}');
      return [];
    } catch (e) {
      print('❌ [MEDICINE_API] Unexpected error in getMedicineTypes: $e');
      return [];
    }
  }

  /// Get medicine manufacturers
  static Future<List<String>> getMedicineManufacturers() async {
    try {
      print('🏭 [MEDICINE_API] Getting medicine manufacturers');

      final response = await _dio.get(
        '/medicine-data/manufacturers',
        options: Options(
          sendTimeout: _timeoutDuration,
          receiveTimeout: _timeoutDuration,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          final manufacturers = data['data']['manufacturers'] as List;
          final manufacturersList = manufacturers
              .map((item) => item['manufacturer_name'] as String)
              .where((name) => name.isNotEmpty)
              .toList();
          print(
            '🏭 [MEDICINE_API] Found ${manufacturersList.length} manufacturers',
          );
          return manufacturersList;
        }
      }

      return [];
    } on DioException catch (e) {
      print(
        '❌ [MEDICINE_API] Dio error in getMedicineManufacturers: ${e.message}',
      );
      return [];
    } catch (e) {
      print(
        '❌ [MEDICINE_API] Unexpected error in getMedicineManufacturers: $e',
      );
      return [];
    }
  }
}
