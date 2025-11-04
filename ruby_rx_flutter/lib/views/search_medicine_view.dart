import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/components/floating_actions.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import '../controllers/home_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/widgets/disease_drugs_modal.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation Header
                Obx(
                  () => AppNavigationBar.home(
                    title: 'Welcome, ${controller.userName}',
                    onProfilePressed: controller.navigateToProfile,
                  ),
                ),

                const SizedBox(height: 24),

                // Medicine Converter Section
                _buildMedicineConverter(context, controller),

                const SizedBox(height: 24),

                // Drug Suggestions Section
                _buildDrugSuggestions(context, controller),

                const SizedBox(height: 24),

                // Disease Categories Section
                _buildDiseaseCategories(context, controller),

                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        onHomePressed: () {
          print('Home Pressed');
        },
        onPrescriptionPressed: () {
          Get.toNamed('/prescription-manager');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Medicine Converter Section
  Widget _buildMedicineConverter(
    BuildContext context,
    HomeController controller,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: RubyColors.primary1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: RubyColors.primary1,
                  ),
                ),
                const SizedBox(width: 12),
                AppText.heading4('Medicine Converter'),
              ],
            ),

            const SizedBox(height: 16),

            // Search input with autocomplete
            Container(
              decoration: BoxDecoration(
                color: RubyColors.getGreyColor(context, light: true),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RubyColors.getBorderColor(context)),
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Enter medicine name...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Suggestions dropdown
            Obx(() {
              if (controller.suggestions.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: RubyColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: RubyColors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = controller.suggestions[index];
                    return ListTile(
                      title: AppText.bodyMedium(suggestion),
                      onTap: () => controller.selectSuggestion(suggestion),
                      dense: true,
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 16),

            // Conversion results
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.conversionResults.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.heading5('Conversion Results:'),
                  const SizedBox(height: 12),
                  ...controller.conversionResults.map((result) {
                    return _buildMedicineCard(result);
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // Drug Suggestions Section
  Widget _buildDrugSuggestions(
    BuildContext context,
    HomeController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading4('Popular Medicines'),
        const SizedBox(height: 12),
        Obx(
          () => SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.popularDrugs.length,
              itemBuilder: (context, index) {
                final drug = controller.popularDrugs[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: AppText.bodySmall(drug),
                    onPressed: () => controller.selectPopularDrug(drug),
                    backgroundColor: RubyColors.primary2.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: RubyColors.primary2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Disease Categories Section
  Widget _buildDiseaseCategories(
    BuildContext context,
    HomeController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading4('Browse by Condition'),
        const SizedBox(height: 12),
        Obx(
          () => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: controller.diseaseCategories.length,
            itemBuilder: (context, index) {
              final category = controller.diseaseCategories[index];
              final color = Color(int.parse(category['color']!));

              return GestureDetector(
                onTap: () {
                  controller.selectDiseaseCategory(category['name']!);
                  _showDiseaseModal(context, controller);
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText.heading2(category['icon']!),
                        const SizedBox(height: 8),
                        AppText.bodyMedium(
                          category['name']!,
                          color: color,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Beautiful medicine card widget
  Widget _buildMedicineCard(Map<String, dynamic> result) {
    final String medicineName = result['original'] ?? '';
    final String type = result['type'] ?? '';
    final List<dynamic> brands = result['brands'] ?? [];
    final List<dynamic> generics = result['generics'] ?? [];

    // Determine if it's brand or generic for styling
    final bool isBrand = type == 'BN';

    // Extract composition from medicine name if possible
    String composition = _extractComposition(medicineName);
    String displayName = _cleanMedicineName(medicineName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pill icon and medicine name
            Row(
              children: [
                // Pill icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: RubyColors.primary1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: RubyColors.primary1,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Medicine name and composition
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.heading4(
                        displayName,
                        color: Colors.black87,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (composition.isNotEmpty) ...[
                        AppText.bodyMedium(
                          composition,
                          color: Colors.grey[600],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isBrand
                              ? RubyColors.green.withOpacity(0.1)
                              : RubyColors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppText.caption(
                          isBrand ? 'Brand Name' : 'Generic Name',
                          color: isBrand ? RubyColors.green : RubyColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                // Three dots menu
                Icon(Icons.more_horiz, color: Colors.grey[400], size: 24),
              ],
            ),

            const SizedBox(height: 20),

            // Dosage information (if available in future)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  AppText.caption(
                    'Consult your doctor for proper dosage',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Brand alternatives section
            if (brands.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: RubyColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.local_pharmacy,
                      size: 16,
                      color: RubyColors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppText.bodyMedium(
                    'Brand Alternatives',
                    color: Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: brands.take(6).map((brand) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: RubyColors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: RubyColors.green.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medication,
                          size: 14,
                          color: RubyColors.green,
                        ),
                        const SizedBox(width: 6),
                        AppText.caption(
                          brand.toString(),
                          color: RubyColors.green.withOpacity(0.9),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Generic alternatives section
            if (generics.isNotEmpty) ...[
              if (brands.isNotEmpty) const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: RubyColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.science,
                      size: 16,
                      color: RubyColors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppText.bodyMedium(
                    'Generic Alternatives',
                    color: Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: generics.take(6).map((generic) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: RubyColors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: RubyColors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.biotech, size: 14, color: RubyColors.blue),
                        const SizedBox(width: 6),
                        AppText.caption(
                          generic.toString(),
                          color: RubyColors.blue.withOpacity(0.9),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // If no alternatives found
            if (brands.isEmpty && generics.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppText.bodyMedium(
                        'No alternatives found for this medicine',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to extract composition from medicine name
  String _extractComposition(String medicineName) {
    // Look for patterns like "Medicine Name (composition)" or "Medicine Name composition mg"
    RegExp regExp = RegExp(
      r'\((.*?)\)|(\d+\s*mg|\d+\s*mcg|\d+\s*g)',
      caseSensitive: false,
    );
    Match? match = regExp.firstMatch(medicineName);
    if (match != null) {
      return match.group(1) ?? match.group(2) ?? '';
    }

    // Look for patterns with '+' indicating combination
    if (medicineName.contains('+')) {
      List<String> parts = medicineName.split(' ');
      String composition = parts
          .where(
            (part) =>
                part.contains('+') ||
                part.toLowerCase().contains('mg') ||
                part.toLowerCase().contains('mcg') ||
                part.toLowerCase().contains('g'),
          )
          .join(' ');
      return composition;
    }

    return '';
  }

  // Helper method to clean medicine name for display
  String _cleanMedicineName(String medicineName) {
    // Remove composition part and clean up the name
    String cleaned = medicineName.replaceAll(RegExp(r'\s*\(.*?\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\d+\s*(mg|mcg|g)\s*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize first letter of each word
    return cleaned
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  void _showDiseaseModal(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (context) => const DiseaseDrugsModal(),
    );
  }
}
