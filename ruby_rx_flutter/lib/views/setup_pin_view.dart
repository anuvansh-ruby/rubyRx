import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/components/pin_input.dart';
import '../common/color_pallet/color_pallet.dart';
import '../common/widgets/app_text.dart';
import '../models/message_state.dart';
import '../models/auth_state.dart';
import '../utils/navigation_helper.dart';

class SetupPinView extends StatefulWidget {
  const SetupPinView({super.key});

  @override
  State<SetupPinView> createState() => _SetupPinViewState();
}

class _SetupPinViewState extends State<SetupPinView> {
  String _newPin = '';
  String _confirmPin = '';
  bool _showConfirmPin = false;

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
                      title: 'Setup PIN',
                      showBackButton: true,
                      showThemeToggle: true,
                      showProfileIcon: false,
                      onBackPressed: controller.goBack,
                    ),

                    const SizedBox(height: 20),

                    // Title
                    AppText.heading2(
                      'Setup PIN',
                      color: RubyColors.getTextColor(context, primary: true),
                    ),

                    const SizedBox(height: 8),

                    AppText.bodyMedium(
                      _showConfirmPin
                          ? 'Confirm your 4-digit PIN'
                          : 'Create a 4-digit PIN to secure your account',
                      color: RubyColors.getTextColor(context),
                    ),

                    const SizedBox(height: 40),

                    // New PIN Input
                    if (!_showConfirmPin) ...[
                      AppText.bodyLarge(
                        'Enter New PIN',
                        color: RubyColors.getTextColor(context, primary: true),
                      ),
                      const SizedBox(height: 16),

                      PINInput(
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
                        showVerifyButton: false,
                        onCompleted: (pin) {
                          setState(() {
                            _newPin = pin;
                            _showConfirmPin = true;
                          });
                        },
                        onChanged: (pin) {
                          setState(() {
                            _newPin = pin;
                          });
                        },
                      ),
                    ],

                    // Confirm PIN Input
                    if (_showConfirmPin) ...[
                      AppText.bodyLarge(
                        'Confirm PIN',
                        color: RubyColors.getTextColor(context, primary: true),
                      ),
                      const SizedBox(height: 16),

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
                          verifyButtonIcon: const Icon(
                            Icons.security,
                            size: 18,
                          ),
                          verifyButtonText: 'Setup PIN',
                          onCompleted: (pin) async {
                            setState(() {
                              _confirmPin = pin;
                            });

                            if (_newPin == _confirmPin) {
                              // Check if this is called after registration
                              final arguments =
                                  Get.arguments as Map<String, dynamic>? ?? {};
                              final isRegistrationComplete =
                                  arguments['registrationComplete'] ?? false;

                              if (isRegistrationComplete) {
                                // Use the new registration PIN setup method
                                await controller.setupPin(_newPin, _confirmPin);
                              } else {
                                // Use the regular PIN setup method
                                await controller.setupPin(_newPin, _confirmPin);
                              }

                              // Check if PIN setup was successful by monitoring auth state
                              if (controller.authState.value.status ==
                                  AuthStatus.authenticated) {
                                NavigationHelper.navigateToHome();
                              }
                            } else {
                              controller.messageState.value =
                                  MessageState.error(
                                    'PINs do not match. Please try again.',
                                  );
                              _resetPinInputs();
                            }
                          },
                          onChanged: (pin) {
                            setState(() {
                              _confirmPin = pin;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Back to New PIN Button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showConfirmPin = false;
                              _confirmPin = '';
                            });
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: AppText.buttonMedium('Change New PIN'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],

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

                    const Spacer(),

                    // Security Tips
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                size: 20,
                                color: RubyColors.getTextColor(context),
                              ),
                              const SizedBox(width: 12),
                              AppText.bodyLarge(
                                'Security Tips:',
                                color: RubyColors.getTextColor(
                                  context,
                                  primary: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AppText.bodySmall(
                            '• Use a unique 4-digit combination\n• Don\'t use common patterns like 1234\n• Keep your PIN private and secure',
                            color: RubyColors.getTextColor(context),
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

  void _resetPinInputs() {
    setState(() {
      _showConfirmPin = false;
      _newPin = '';
      _confirmPin = '';
    });
  }
}
