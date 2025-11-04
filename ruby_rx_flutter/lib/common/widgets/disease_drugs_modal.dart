import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import '../components/app_navigation_bar.dart';
import '../../controllers/home_controller.dart';

class DiseaseDrugsModal extends StatelessWidget {
  const DiseaseDrugsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: RubyColors.primary2,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Obx(
                () => AppNavigationBar.gradientHeader(
                  title: '${controller.selectedDisease.value} Medications',
                  onBackPressed: controller.closeDiseaseModal,
                ),
              ),
            ),

            // Content
            Flexible(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (controller.diseaseDrugs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: AppText.bodyLarge(
                        'No medications found for this condition.',
                        color: RubyColors.grey,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.diseaseDrugs.length,
                  itemBuilder: (context, index) {
                    final drug = controller.diseaseDrugs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: RubyColors.primary2.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: RubyColors.primary2,
                          ),
                        ),
                        title: AppText.bodyLarge(drug['name'] ?? 'Unknown'),
                        subtitle: AppText.bodyMedium(
                          drug['tty'] ?? '',
                          color: RubyColors.darkGrey,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: RubyColors.grey,
                        ),
                        onTap: () {
                          controller.selectDiseaseDrug(drug['name'] ?? '');
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
