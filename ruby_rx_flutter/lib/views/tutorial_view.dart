import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tutorial_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_button.dart';
import '../common/color_pallet/color_pallet.dart';
import '../common/widgets/app_text.dart';

class TutorialView extends StatelessWidget {
  const TutorialView({super.key});

  @override
  Widget build(BuildContext context) {
    final TutorialController controller = Get.find<TutorialController>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Tutorial content area
              Expanded(
                child: Obx(() {
                  final currentItem =
                      controller.tutorialItems[controller.currentIndex.value];

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: Container(
                      key: ValueKey(controller.currentIndex.value),
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tutorial Image
                          Container(
                            height: 280,
                            width: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                currentItem.imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: RubyColors.primary1.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      size: 80,
                                      color: RubyColors.primary1,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // Tutorial Title
                          AppText.heading2(
                            currentItem.title,
                            textAlign: TextAlign.center,
                            color: RubyColors.getTextColor(
                              context,
                              primary: true,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tutorial Description
                          AppText.bodyLarge(
                            currentItem.description,
                            textAlign: TextAlign.center,
                            color: RubyColors.getTextColor(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              // Dots Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      controller.tutorialItems.length,
                      (index) => GestureDetector(
                        onTap: () => controller.onDotTapped(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          height: 12,
                          width: controller.currentIndex.value == index
                              ? 30
                              : 12,
                          decoration: BoxDecoration(
                            color: controller.currentIndex.value == index
                                ? RubyColors.primary2
                                : RubyColors.primary2.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Skip Button
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: AppButton(
                  onPressed: () => controller.skipTutorial(),
                  label: 'Skip Tutorial',
                  width: MediaQuery.of(context).size.width * 0.7,
                  fontSize: 16,
                  textColor: RubyColors.white,
                  color: RubyColors.primary2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
