import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/services/storage_service.dart';
import '../data/config/app_config.dart';

class MedicineSubstituteModel {
  final int medId;
  final String medName;
  final String? manufacturer;
  final String? medicineType;
  final double? price;
  final String? packSize;
  final String? composition1Id;
  final String? composition1Name;
  final String? composition1Dose;
  final String? composition2Id;
  final String? composition2Name;
  final String? composition2Dose;

  MedicineSubstituteModel({
    required this.medId,
    required this.medName,
    this.manufacturer,
    this.medicineType,
    this.price,
    this.packSize,
    this.composition1Id,
    this.composition1Name,
    this.composition1Dose,
    this.composition2Id,
    this.composition2Name,
    this.composition2Dose,
  });

  factory MedicineSubstituteModel.fromJson(Map<String, dynamic> json) {
    return MedicineSubstituteModel(
      medId: json['med_id'] ?? 0,
      medName: json['med_name'] ?? '',
      manufacturer: json['manufacturer_name'],
      medicineType: json['medicin_type'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      packSize: json['pack_size_label'],
      composition1Id: json['short_composition_1'],
      composition1Name: json['composition_1_name'],
      composition1Dose: json['short_composition_1_dose'],
      composition2Id: json['short_composition_2'],
      composition2Name: json['composition_2_name'],
      composition2Dose: json['short_composition_2_dose'],
    );
  }

  String get compositionInfo {
    final compositions = <String>[];
    if (composition1Name != null && composition1Name!.isNotEmpty) {
      String comp = composition1Name!;
      if (composition1Dose != null && composition1Dose!.isNotEmpty) {
        comp += ' ${composition1Dose!}';
      }
      compositions.add(comp);
    }
    if (composition2Name != null && composition2Name!.isNotEmpty) {
      String comp = composition2Name!;
      if (composition2Dose != null && composition2Dose!.isNotEmpty) {
        comp += ' ${composition2Dose!}';
      }
      compositions.add(comp);
    }
    return compositions.join(' + ');
  }

  String get priceInfo {
    if (price != null && price! > 0) {
      return '₹${price!.toStringAsFixed(2)}';
    }
    return 'Price not available';
  }

  String get displayInfo {
    final parts = <String>[];
    if (manufacturer != null && manufacturer!.isNotEmpty) {
      parts.add(manufacturer!);
    }
    if (medicineType != null && medicineType!.isNotEmpty) {
      parts.add(medicineType!);
    }
    return parts.join(' • ');
  }
}

class MedicineSubstituteService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  /// Get authorization headers with JWT token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': token,
    };
  }

  /// Get medicine substitutes based on composition IDs
  /// This finds medicines with the same composition (generic alternatives)
  static Future<List<MedicineSubstituteModel>> getMedicineSubstitutes({
    required String compositionId1,
    String? compositionId2,
    int? excludeMedId,
    String sortBy = 'price', // 'price', 'name', 'manufacturer'
    int limit = 20,
  }) async {
    try {
      if (compositionId1.isEmpty) {
        print('⚠️ Invalid composition ID: $compositionId1');
        return [];
      }

      // Build URL path
      String path = '/v1/medicine-data/substitutes/$compositionId1';
      if (compositionId2 != null && compositionId2.isNotEmpty) {
        path += '/$compositionId2';
      }

      // Build query parameters
      final queryParams = {
        'limit': limit.toString(),
        'sortBy': sortBy,
        if (excludeMedId != null && excludeMedId > 0)
          'excludeMedId': excludeMedId.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl$path',
      ).replace(queryParameters: queryParams);

      print('🔍 Getting substitutes: $uri');

      final headers = await _getHeaders();
      print('🔐 Headers: ${headers.keys.join(", ")}');

      final response = await http
          .get(uri, headers: headers)
          .timeout(_timeoutDuration);

      print('🔍 Substitutes response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Substitutes data status: ${data['status']}');

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          final substitutes = data['data']['substitutes'] as List;
          print('✅ Found ${substitutes.length} substitutes');

          return substitutes
              .map((item) => MedicineSubstituteModel.fromJson(item))
              .toList();
        } else {
          print(
            '⚠️ API returned non-success status: ${data['status']}, message: ${data['message']}',
          );
        }
      } else {
        print('❌ HTTP error: ${response.statusCode} - ${response.body}');
      }

      return [];
    } catch (e) {
      print('❌ Get medicine substitutes error: $e');
      return [];
    }
  }

  /// Get detailed medicine information along with substitutes
  static Future<Map<String, dynamic>?> getMedicineWithSubstitutes({
    required int medId,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/v1/medicine-data/$medId/details',
      ).replace(queryParameters: {'limit': limit.toString()});

      print('🔍 Getting medicine with substitutes: $uri');

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(_timeoutDuration);

      print('🔍 Medicine details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if ((data['status'] == 'SUCCESS' || data['status'] == 'Success') &&
            data['data'] != null) {
          final medicine = MedicineSubstituteModel.fromJson(
            data['data']['medicine'],
          );
          final substitutes = (data['data']['substitutes'] as List)
              .map((item) => MedicineSubstituteModel.fromJson(item))
              .toList();

          print('✅ Loaded medicine with ${substitutes.length} substitutes');

          return {
            'medicine': medicine,
            'substitutes': substitutes,
            'substitutes_count': data['data']['substitutes_count'],
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Get medicine with substitutes error: $e');
      return null;
    }
  }
}
