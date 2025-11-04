import 'package:dio/dio.dart';

class RxNormApiService {
  static const String baseUrl = 'https://rxnav.nlm.nih.gov/REST';
  final Dio _dio = Dio();

  RxNormApiService() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  // Get spelling suggestions for drug names
  Future<List<String>> getSpellingSuggestions(String term) async {
    try {
      final response = await _dio.get('/spellingsuggestions.json?name=$term');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['suggestionGroup'] != null &&
            data['suggestionGroup']['suggestionList'] != null &&
            data['suggestionGroup']['suggestionList']['suggestion'] != null) {
          final suggestions =
              data['suggestionGroup']['suggestionList']['suggestion'];
          if (suggestions is List) {
            return suggestions.cast<String>();
          } else if (suggestions is String) {
            return [suggestions];
          }
        }
      }
      return [];
    } catch (e) {
      print('Error getting spelling suggestions: $e');
      return [];
    }
  }

  // Search for drugs by name
  Future<List<Map<String, dynamic>>> searchDrugs(String term) async {
    try {
      final response = await _dio.get('/drugs.json?name=$term');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['drugGroup'] != null &&
            data['drugGroup']['conceptGroup'] != null) {
          final conceptGroups = data['drugGroup']['conceptGroup'];
          List<Map<String, dynamic>> drugs = [];

          for (var group in conceptGroups) {
            if (group['conceptProperties'] != null) {
              final concepts = group['conceptProperties'];
              if (concepts is List) {
                for (var concept in concepts) {
                  drugs.add({
                    'rxcui': concept['rxcui'],
                    'name': concept['name'],
                    'synonym': concept['synonym'],
                    'tty': concept['tty'], // Term type (brand, generic, etc.)
                  });
                }
              }
            }
          }
          return drugs;
        }
      }
      return [];
    } catch (e) {
      print('Error searching drugs: $e');
      return [];
    }
  }

  // Get brand names for a generic drug
  Future<List<String>> getBrandNames(String rxcui) async {
    try {
      final response = await _dio.get('/rxcui/$rxcui/related.json?tty=BN');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['relatedGroup'] != null &&
            data['relatedGroup']['conceptGroup'] != null) {
          final conceptGroups = data['relatedGroup']['conceptGroup'];
          List<String> brands = [];

          for (var group in conceptGroups) {
            if (group['conceptProperties'] != null) {
              final concepts = group['conceptProperties'];
              if (concepts is List) {
                for (var concept in concepts) {
                  brands.add(concept['name']);
                }
              }
            }
          }
          return brands;
        }
      }
      return [];
    } catch (e) {
      print('Error getting brand names: $e');
      return [];
    }
  }

  // Get generic name for a brand drug
  Future<List<String>> getGenericNames(String rxcui) async {
    try {
      final response = await _dio.get('/rxcui/$rxcui/related.json?tty=IN');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['relatedGroup'] != null &&
            data['relatedGroup']['conceptGroup'] != null) {
          final conceptGroups = data['relatedGroup']['conceptGroup'];
          List<String> generics = [];

          for (var group in conceptGroups) {
            if (group['conceptProperties'] != null) {
              final concepts = group['conceptProperties'];
              if (concepts is List) {
                for (var concept in concepts) {
                  generics.add(concept['name']);
                }
              }
            }
          }
          return generics;
        }
      }
      return [];
    } catch (e) {
      print('Error getting generic names: $e');
      return [];
    }
  }

  // Get drugs for a specific condition/disease
  Future<List<Map<String, dynamic>>> getDrugsForCondition(
    String condition,
  ) async {
    try {
      // This is a simplified approach - in real app you might want to use
      // a more sophisticated mapping or additional APIs
      final response = await _dio.get('/drugs.json?name=$condition');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['drugGroup'] != null &&
            data['drugGroup']['conceptGroup'] != null) {
          final conceptGroups = data['drugGroup']['conceptGroup'];
          List<Map<String, dynamic>> drugs = [];

          for (var group in conceptGroups) {
            if (group['conceptProperties'] != null) {
              final concepts = group['conceptProperties'];
              if (concepts is List) {
                for (var concept in concepts) {
                  drugs.add({
                    'rxcui': concept['rxcui'],
                    'name': concept['name'],
                    'tty': concept['tty'],
                  });
                }
              }
            }
          }
          return drugs.take(20).toList(); // Limit to 20 results
        }
      }
      return [];
    } catch (e) {
      print('Error getting drugs for condition: $e');
      return [];
    }
  }
}
