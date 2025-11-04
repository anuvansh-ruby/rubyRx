import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import '../controllers/auth_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/components/pin_input.dart';
import '../common/components/biometric_button.dart';
import '../common/color_pallet/color_pallet.dart';
import '../utils/navigation_helper.dart';
import '../models/message_state.dart';

class PinEntryView extends StatefulWidget {
  const PinEntryView({super.key});

  @override
  State<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<PinEntryView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Navigation Header
                    AppNavigationBar(
                      title: 'Enter PIN',
                      showBackButton: true,
                      showThemeToggle: true,
                      showProfileIcon: false,
                      onBackPressed: controller.goBack,
                    ),

                    const SizedBox(height: 20),

                    // Title
                    AppText.heading2(
                      'Enter Your PIN',
                      color: RubyColors.getTextColor(context, primary: true),
                    ),

                    const SizedBox(height: 8),

                    AppText.bodyMedium(
                      'Please enter your 4-digit PIN to continue',
                      color: RubyColors.getTextColor(context),
                    ),

                    const SizedBox(height: 40),

                    // PIN Input Component
                    Obx(
                      () => PINInput(
                        length: 4,
                        fieldWidth: 65,
                        fieldHeight: 65,
                        primaryColor: RubyColors.otpPrimaryColor,
                        backgroundColor: RubyColors.getCardBackgroundColor(
                          context,
                        ),
                        textColor: RubyColors.getTextColor(
                          context,
                          primary: true,
                        ),
                        borderColor: RubyColors.getBorderColor(context),
                        isLoading: controller.isLoading.value,
                        verifyButtonIcon: const Icon(Icons.lock, size: 18),
                        onCompleted: (pin) async {
                          final success = await controller.verifyPin(pin);
                          if (success) {
                            NavigationHelper.navigateToHome();
                          }
                        },
                        onChanged: (pin) {
                          // Update the controller's PIN length for other UI elements if needed
                          controller.pinLength.value = pin.length;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Error/Success Message
                    Obx(() {
                      final messageState = controller.messageState.value;
                      if (messageState.hasMessage) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: messageState.type == MessageType.error
                                ? Colors.red.withOpacity(0.1)
                                : messageState.type == MessageType.success
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: messageState.type == MessageType.error
                                  ? Colors.red.withOpacity(0.3)
                                  : messageState.type == MessageType.success
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: AppText.bodyMedium(
                            messageState.message ?? '',
                            color: messageState.type == MessageType.error
                                ? Colors.red
                                : messageState.type == MessageType.success
                                ? Colors.green
                                : Colors.blue,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Forgot PIN Option
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Get.toNamed('/forgot-pin');
                        },
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: AppText.buttonMedium('Forgot PIN?'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Biometric Authentication Button (if enabled by user) - Bottom position
                    Obx(() {
                      // Show button only if both device supports biometric AND user has enabled it from profile
                      if (controller.biometricAvailable.value &&
                          controller.biometricEnabled.value) {
                        return Column(
                          children: [
                            Center(
                              child: BiometricButton(
                                hasBiometricStored:
                                    true, // User has biometric access available
                                height: 120,
                                width: 120,
                                isLoading: controller.isLoading.value,
                                loginBiometricText:
                                    controller.biometricTypeName.value,
                                loginBiometricIcon:
                                    controller.biometricTypeName.value ==
                                        'Face ID'
                                    ? Icons.face
                                    : Icons.fingerprint,
                                iconColor: RubyColors.primary1,
                                loginBiometricTextColor: RubyColors.primary1,
                                fontSize: 12,
                                iconSize: 48,
                                borderRadius: 60,
                                spaceBetweenIconAndText: 8,
                                onLoginWithBiometric: () async {
                                  // Use the controller's built-in biometric authentication method
                                  // which handles all permission checks, error handling, and navigation
                                  final success = await controller
                                      .authenticateWithBiometrics();
                                  if (success) {
                                    // Navigation is handled inside the controller method
                                    NavigationHelper.navigateToHome();
                                  }
                                  // Error messages are handled inside the controller method
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Security Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RubyColors.getTextColor(
                          context,
                        ).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: RubyColors.getTextColor(
                            context,
                          ).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security,
                            size: 20,
                            color: RubyColors.getTextColor(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppText.caption(
                              'Your PIN is stored securely on this device for offline access.',
                              color: RubyColors.getTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
