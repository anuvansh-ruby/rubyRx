import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../data/api/rxnorm_api_service.dart';
import 'auth_controller.dart';

class HomeController extends GetxController {
  // Get auth controller instance
  final AuthController authController = Get.find<AuthController>();
  final RxNormApiService _rxNormService = RxNormApiService();

  // Observable variables
  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  final canNavigateBack = false.obs;
  final canNavigateForward = true.obs;

  // Medicine converter state
  final searchController = TextEditingController();
  final RxList<String> suggestions = <String>[].obs;
  final RxString selectedMedicine = ''.obs;
  final RxList<Map<String, dynamic>> conversionResults =
      <Map<String, dynamic>>[].obs;

  // Drug suggestions state
  final RxList<String> popularDrugs = <String>[
    'Acetaminophen',
    'Ibuprofen',
    'Aspirin',
    'Lisinopril',
    'Metformin',
    'Atorvastatin',
    'Levothyroxine',
    'Amlodipine',
  ].obs;

  // Disease categories state
  final RxList<Map<String, String>> diseaseCategories = <Map<String, String>>[
    {'name': 'Sugar', 'icon': '🩺', 'color': '0xFF4CAF50'},
    {'name': 'Hypertension', 'icon': '❤️', 'color': '0xFFE91E63'},
    {'name': 'Fever', 'icon': '🌡️', 'color': '0xFF9C27B0'},
    {'name': 'Joint Pain', 'icon': '🦴', 'color': '0xFF2196F3'},
  ].obs;

  final RxList<Map<String, dynamic>> diseaseDrugs =
      <Map<String, dynamic>>[].obs;
  final RxString selectedDisease = ''.obs;
  final RxBool showDiseaseModal = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPopularDrugs();
  }

  void _loadPopularDrugs() {
    // This could be enhanced to load from a local database or API
    popularDrugs.refresh();
  }

  // Medicine converter methods
  Future<void> onSearchChanged(String value) async {
    if (value.length < 2) {
      suggestions.clear();
      return;
    }

    isLoading.value = true;
    try {
      final spellingSuggestions = await _rxNormService.getSpellingSuggestions(
        value,
      );
      suggestions.value = spellingSuggestions.take(5).toList();
    } catch (e) {
      print('Error getting suggestions: $e');
      suggestions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> convertMedicine(String medicineName) async {
    if (medicineName.isEmpty) return;

    isLoading.value = true;
    selectedMedicine.value = medicineName;

    try {
      // Search for the drug first
      final drugs = await _rxNormService.searchDrugs(medicineName);

      if (drugs.isNotEmpty) {
        List<Map<String, dynamic>> results = [];

        for (var drug in drugs.take(3)) {
          // Limit to 3 results
          final rxcui = drug['rxcui'];
          final drugName = drug['name'];
          final termType = drug['tty'];

          Map<String, dynamic> result = {
            'original': drugName,
            'rxcui': rxcui,
            'type': termType,
            'brands': <String>[],
            'generics': <String>[],
          };

          // Get brand names if it's a generic
          if (termType == 'IN' || termType == 'MIN') {
            final brands = await _rxNormService.getBrandNames(rxcui);
            result['brands'] = brands;
          }

          // Get generic names if it's a brand
          if (termType == 'BN') {
            final generics = await _rxNormService.getGenericNames(rxcui);
            result['generics'] = generics;
          }

          results.add(result);
        }

        conversionResults.value = results;
      } else {
        conversionResults.clear();
      }
    } catch (e) {
      print('Error converting medicine: $e');
      conversionResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void selectSuggestion(String suggestion) {
    searchController.text = suggestion;
    suggestions.clear();
    convertMedicine(suggestion);
  }

  void selectPopularDrug(String drug) {
    searchController.text = drug;
    convertMedicine(drug);
  }

  // Disease category methods
  Future<void> selectDiseaseCategory(String diseaseName) async {
    selectedDisease.value = diseaseName;
    showDiseaseModal.value = true;

    isLoading.value = true;
    try {
      final drugs = await _rxNormService.getDrugsForCondition(
        diseaseName.toLowerCase(),
      );
      diseaseDrugs.value = drugs;
    } catch (e) {
      print('Error getting drugs for disease: $e');
      diseaseDrugs.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void closeDiseaseModal() {
    showDiseaseModal.value = false;
    selectedDisease.value = '';
    diseaseDrugs.clear();
  }

  void selectDiseaseDrug(String drugName) {
    closeDiseaseModal();
    searchController.text = drugName;
    convertMedicine(drugName);
  }

  // Getters for user data
  UserModel get currentUser => authController.currentUser.value;

  String get userName => currentUser.name ?? 'User';

  String get userEmail => currentUser.email ?? '';

  String get userPhone => currentUser.phone ?? '';

  // Navigation methods
  void navigateToProfile() {
    Get.toNamed(AppRoutes.profile);
  }

  // Logout functionality
  void logout() {
    authController.logout();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
