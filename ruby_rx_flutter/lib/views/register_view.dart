import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../common/components/mobile_input.dart';
import '../common/components/app_button.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/components/error_display.dart';
import '../common/color_pallet/color_pallet.dart';
import '../common/widgets/app_text.dart';
import '../routes/app_routes.dart';
import '../utils/navigation_helper.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation Header
                AppNavigationBar(
                  title: 'Create Account',
                  showBackButton: true,
                  showThemeToggle: true,
                  showProfileIcon: false,
                  onBackPressed: controller.goBack,
                ),

                const SizedBox(height: 20),

                // Ruby AI Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'lib/assets/ruby_rx_logo_real.png',
                      height: 200,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Welcome Text
                AppText.heading3(
                  'Complete Your Profile',
                  color: RubyColors.primary1,
                ),

                const SizedBox(height: 40),

                // Error Display
                Obx(
                  () => ErrorDisplay(
                    message: controller.lastError.value ?? '',
                    isVisible: controller.lastError.value != null,
                    onDismiss: () => controller.clearError(),
                  ),
                ),

                // Mobile Number Input
                Obx(
                  () => MobileNumberInput(
                    controller: controller.phoneController,
                    countryCode: '+91',
                    isEnabled: !controller.isSendingOtp.value,
                  ),
                ),

                SizedBox(height: 40),

                // Continue Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Obx(() {
                    final isSending = controller.isSendingOtp.value;

                    return AppButton(
                      label: isSending
                          ? 'Sending OTP...'
                          : 'Get verification code',
                      onPressed: isSending
                          ? null
                          : () {
                              // Clear any previous errors
                              controller.clearError();

                              // Validate phone number before sending
                              final phoneError = controller.validatePhone(
                                controller.phoneController.text,
                              );

                              if (phoneError != null) {
                                controller.lastError.value = phoneError;
                                return;
                              }

                              controller.loginWithPhone(
                                controller.phoneController.text,
                              );
                            },
                      color: RubyColors.primary2,
                      isDisabled: isSending,
                    );
                  }),
                ),

                const SizedBox(height: 5),

                // "or" divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: RubyColors.getTextColor(
                          context,
                        ).withValues(alpha: 0.3),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AppText.bodyMedium(
                        'or',
                        color: RubyColors.getTextColor(context),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: RubyColors.getTextColor(
                          context,
                        ).withValues(alpha: 0.3),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Skip hyperlink
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.home);
                    },
                    child: AppText.bodySmall(
                      'Skip',
                      color: RubyColors.primary2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 40), // Replace Spacer with fixed spacing
                // Terms and Conditions section
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: RubyColors.getTextColor(context),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'By signing in you agree to our '),
                        TextSpan(
                          text: 'Terms & conditions',
                          style: TextStyle(
                            color: RubyColors.primary2,
                            decoration: TextDecoration.underline,
                            decorationColor: RubyColors.primary2,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showTermsAndConditions();
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: RubyColors.primary2,
                            decoration: TextDecoration.underline,
                            decorationColor: RubyColors.primary2,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showPrivacyPolicy();
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsAndConditions() {
    Get.dialog(
      AlertDialog(
        title: AppText.heading5('Terms & Conditions'),
        content: SingleChildScrollView(
          child: AppText.bodyMedium(
            'Welcome to Ruby AI!\n\n'
            '1. Acceptance of Terms\n'
            'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.\n\n'
            '2. Use License\n'
            'Permission is granted to temporarily download one copy of Ruby AI per device for personal, non-commercial transitory viewing only.\n\n'
            '3. Disclaimer\n'
            'The materials in Ruby AI are provided on an "as is" basis. Ruby AI makes no warranties, expressed or implied.\n\n'
            '4. Limitations\n'
            'In no event shall Ruby AI or its suppliers be liable for any damages arising out of the use or inability to use the materials on Ruby AI.\n\n'
            '5. Privacy Policy\n'
            'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service.\n\n'
            'For complete terms and conditions, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
            },
            child: AppText.buttonMedium('Close', color: RubyColors.primary2),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Get.dialog(
      AlertDialog(
        title: AppText.heading5('Privacy Policy'),
        content: SingleChildScrollView(
          child: AppText.bodyMedium(
            'Privacy Policy for Ruby AI\n\n'
            '1. Information We Collect\n'
            'We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support.\n\n'
            '2. How We Use Your Information\n'
            'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.\n\n'
            '3. Information Sharing\n'
            'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.\n\n'
            '4. Data Security\n'
            'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.\n\n'
            '5. Your Rights\n'
            'You have the right to access, update, or delete your personal information. You may also opt out of certain communications from us.\n\n'
            '6. Contact Us\n'
            'If you have any questions about this Privacy Policy, please contact us through our support channels.\n\n'
            'Last updated: September 2025',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              NavigationHelper.closeDialog();
            },
            child: AppText.buttonMedium('Close', color: RubyColors.primary2),
          ),
        ],
      ),
    );
  }
}
