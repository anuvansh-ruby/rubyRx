import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import '../controllers/auth_controller.dart';
import '../common/components/mobile_input.dart';
import '../common/components/app_button.dart';
import '../common/components/gradient_background.dart';
import '../common/components/theme_toggle_button.dart';
import '../routes/app_routes.dart';
import '../utils/navigation_helper.dart';

class ForgotPinView extends GetView<AuthController> {
  const ForgotPinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(24.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with back button and theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: RubyColors.getIconColor(context),
                        ),
                        onPressed: () {
                          NavigationHelper.goBack(
                            fallbackRoute: AppRoutes.login,
                          );
                        },
                      ),
                      const ThemeToggleIconButton(),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Title
                  AppText.heading2(
                    'Forgot PIN?',
                    color: RubyColors.getTextColor(context, primary: true),
                  ),

                  const SizedBox(height: 8),

                  AppText.bodyMedium(
                    'Enter your mobile number to reset your PIN',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey,
                  ),

                  const SizedBox(height: 40),

                  // Illustration
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: RubyColors.primary1.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: RubyColors.primary1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Mobile Number Input
                  MobileNumberInput(
                    controller: controller.phoneController,
                    countryCode: '+91',
                  ),

                  const Spacer(),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Continue',
                      onPressed: () {
                        // Navigate to OTP screen for PIN reset
                        Get.toNamed(
                          '/otp-verify',
                          arguments: {
                            'phone': controller.phoneController.text,
                            'isForPinReset': true,
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Help Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyLarge(
                          'What happens next?',
                          color: Colors.black87,
                        ),
                        SizedBox(height: 8),
                        AppText.bodySmall(
                          '• We\'ll send an OTP to your mobile number\n• Verify the OTP to confirm your identity\n• Set up a new 4-digit PIN for your account',
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
