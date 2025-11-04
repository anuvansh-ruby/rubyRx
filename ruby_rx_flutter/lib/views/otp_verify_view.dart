import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import '../controllers/auth_controller.dart';
import '../common/components/otp_input.dart';
import '../common/components/app_button.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/widgets/app_text.dart';
import '../routes/app_routes.dart';
import '../utils/navigation_helper.dart';
import '../utils/message_handler.dart';
import '../models/message_state.dart';

class OtpVerifyView extends GetView<AuthController> {
  const OtpVerifyView({super.key});

  @override
  Widget build(BuildContext context) {
    final String phoneNumber =
        Get.arguments?['phone'] ?? controller.currentPhoneNumber.value;
    final String maskedPhone = _maskPhoneNumber(phoneNumber);

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Navigation Header
                      AppNavigationBar(
                        title: 'Verify Your Number',
                        showBackButton: true,
                        showThemeToggle: true,
                        showProfileIcon: false,
                        onBackPressed: () {
                          NavigationHelper.goBack(
                            fallbackRoute: AppRoutes.login,
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Ruby AI Logo
                      Center(
                        child: Image.asset(
                          'lib/assets/ruby_rx_logo_real.png',
                          height: 80,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Title
                      AppText.heading2(
                        'Verify Your Number',
                        color: RubyColors.getTextColor(context, primary: true),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle with masked phone number
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey,
                          ),
                          children: [
                            const TextSpan(text: 'We sent a 4-digit code to '),
                            TextSpan(
                              text: maskedPhone,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: RubyColors.getTextColor(
                                  context,
                                  primary: true,
                                ),
                              ),
                            ),
                            const TextSpan(text: ' via WhatsApp'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // OTP Input
                      Center(
                        child: OTPInput(
                          length: 4,
                          onCompleted: (otp) {
                            controller.otpController.text = otp;
                            if (!controller.isVerifyingOtp.value) {
                              controller.verifyOtp(otp);
                            }
                          },
                          onChanged: (otp) {
                            controller.otpController.text = otp;
                            // Clear any previous errors when user starts typing
                            if (otp.isNotEmpty &&
                                controller.authState.value.error != null) {
                              controller.clearError();
                            }
                          },
                          primaryColor: RubyColors.primary1,
                          fieldWidth: 70,
                          fieldHeight: 70,
                          showVerifyButton: false,
                          autoFocus: true,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        child: Obx(
                          () => AppButton(
                            label: controller.isVerifyingOtp.value
                                ? 'Verifying...'
                                : 'Verify',
                            onPressed: controller.isVerifyingOtp.value
                                ? null
                                : () {
                                    // Clear any previous errors
                                    controller.clearError();

                                    final otp = controller.otpController.text;

                                    // Validate OTP before verifying
                                    final otpError = controller.validateOtp(
                                      otp,
                                    );

                                    if (otpError != null) {
                                      MessageHandler.showError(
                                        otpError,
                                        errorType: ErrorType.validation,
                                      );
                                      return;
                                    }

                                    controller.verifyOtp(otp);
                                  },
                            color: RubyColors.primary2,
                            isDisabled: controller.isVerifyingOtp.value,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Error message
                      Obx(() {
                        if (controller.authState.value.error != null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AppText.bodyMedium(
                                    controller.authState.value.error!,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      const SizedBox(height: 40),

                      // Resend OTP Section
                      Center(
                        child: Column(
                          children: [
                            AppText.bodyMedium(
                              "Didn't receive the code?",
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]!
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => TextButton(
                                onPressed:
                                    controller.canResendOtp.value &&
                                        !controller.isResendingOtp.value &&
                                        !controller.isVerifyingOtp.value
                                    ? () => controller.resendOtp()
                                    : null,
                                child: AppText.buttonMedium(
                                  controller.isResendingOtp.value
                                      ? 'Resending...'
                                      : controller.canResendOtp.value
                                      ? 'Resend Code'
                                      : 'Resend Code (${controller.resendCountdown.value}s)',
                                  color:
                                      controller.canResendOtp.value &&
                                          !controller.isResendingOtp.value
                                      ? RubyColors.primary1
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Change Phone Number
                      Center(
                        child: Obx(
                          () => TextButton.icon(
                            onPressed:
                                controller.isVerifyingOtp.value ||
                                    controller.isResendingOtp.value
                                ? null
                                : () {
                                    NavigationHelper.goBack(
                                      fallbackRoute: AppRoutes.login,
                                    );
                                  },
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color:
                                  controller.isVerifyingOtp.value ||
                                      controller.isResendingOtp.value
                                  ? Colors.grey[300]
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            label: AppText.bodyMedium(
                              'Change Phone Number',
                              color:
                                  controller.isVerifyingOtp.value ||
                                      controller.isResendingOtp.value
                                  ? Colors.grey[300]!
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey[400]!
                                  : Colors.grey[600]!,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          Obx(
            () => controller.isVerifyingOtp.value
                ? Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              AppText.bodyMedium('Verifying OTP...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';

    // Remove country code for display
    String number = phoneNumber;
    if (number.startsWith('+91')) {
      number = number.substring(3);
    } else if (number.startsWith('+')) {
      // Find where country code ends (assuming max 3 digits)
      for (int i = 1; i <= 4 && i < number.length; i++) {
        if (number.length - i == 10) {
          number = number.substring(i);
          break;
        }
      }
    }

    // Mask middle digits: +91-XXXXX-12345 -> +91-XXXXX-****5
    if (number.length >= 10) {
      return '+91 ${number.substring(0, 5)}****${number.substring(9)}';
    }

    return phoneNumber;
  }
}
