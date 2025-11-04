import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../common/components/app_button.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/components/error_display.dart';
import '../common/color_pallet/color_pallet.dart';
import '../common/widgets/app_text.dart';
import '../models/message_state.dart';

class RegistrationFormView extends GetView<AuthController> {
  const RegistrationFormView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize form controllers
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final dobController = TextEditingController();
    final addressController = TextEditingController();

    // Get phone number from arguments
    final arguments = Get.arguments as Map<String, dynamic>? ?? {};
    final phoneNumber = arguments['phone'] ?? '';
    final isOtpVerified = arguments['otpVerified'] ?? false;

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    // Selected date state
    DateTime? selectedDate;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation Header
                  AppNavigationBar(
                    title: 'Complete Registration',
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
                        height: 150,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Welcome Text
                  AppText.heading3('Almost There!', color: RubyColors.primary1),

                  const SizedBox(height: 8),

                  AppText.bodyMedium(
                    'Please provide your details to complete registration',
                    color: RubyColors.getTextColor(
                      context,
                    ).withValues(alpha: 0.7),
                  ),

                  const SizedBox(height: 30),

                  // Show phone number (read-only)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RubyColors.primary1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: RubyColors.primary1.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: RubyColors.primary1, size: 20),
                        const SizedBox(width: 12),
                        AppText.subtitle1(
                          'Phone: $phoneNumber',
                          color: RubyColors.getTextColor(context),
                        ),
                        if (isOtpVerified) ...[
                          const Spacer(),
                          Icon(Icons.verified, color: Colors.green, size: 20),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Error Display
                  Obx(
                    () => ErrorDisplay(
                      message: controller.messageState.value.message ?? '',
                      isVisible:
                          controller.messageState.value.type ==
                          MessageType.error,
                      onDismiss: () => controller.clearMessage(),
                    ),
                  ),

                  // First Name
                  TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name *',
                      hintText: 'Enter your first name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.getTextColor(
                            context,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.primary1,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'First name must be at least 2 characters';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 20),

                  // Last Name
                  TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name *',
                      hintText: 'Enter your last name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.getTextColor(
                            context,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.primary1,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Last name must be at least 2 characters';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 20),

                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.getTextColor(
                            context,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.primary1,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email address is required';
                      }
                      if (!GetUtils.isEmail(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                  ),

                  const SizedBox(height: 20),

                  // Date of Birth
                  TextFormField(
                    controller: dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      hintText: 'Select your date of birth',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.getTextColor(
                            context,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.primary1,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Date of birth is required';
                      }

                      if (selectedDate == null) {
                        return 'Date of birth is required';
                      }

                      final age = DateTime.now().year - selectedDate!.year;
                      if (age < 13) {
                        return 'You must be at least 13 years old';
                      }
                      if (age > 120) {
                        return 'Please enter a valid date of birth';
                      }
                      return null;
                    },
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            selectedDate ??
                            DateTime.now().subtract(
                              const Duration(
                                days: 365 * 25,
                              ), // Default to 25 years ago
                            ),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now().subtract(
                          const Duration(days: 365 * 13), // Minimum age 13
                        ),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(primary: RubyColors.primary1),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (date != null) {
                        selectedDate = date;
                        dobController.text =
                            '${date.day}/${date.month}/${date.year}';
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Address (Optional)
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Address (Optional)',
                      hintText: 'Enter your address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.getTextColor(
                            context,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: RubyColors.primary1,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: 30),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => AppButton(
                        label: controller.isLoading.value
                            ? 'Registering...'
                            : 'Complete Registration',
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                                // Clear any previous errors
                                controller.clearMessage();

                                // Validate form
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                if (selectedDate == null) {
                                  controller.messageState.value =
                                      MessageState.error(
                                        'Please select your date of birth',
                                      );
                                  return;
                                }

                                // Call registration API with new endpoint
                                await _registerUser(
                                  phoneNumber: phoneNumber,
                                  firstName: firstNameController.text.trim(),
                                  lastName: lastNameController.text.trim(),
                                  email: emailController.text.trim(),
                                  dateOfBirth: selectedDate!,
                                  address: addressController.text.trim().isEmpty
                                      ? null
                                      : addressController.text.trim(),
                                );
                              },
                        color: RubyColors.primary2,
                        isDisabled: controller.isLoading.value,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Required fields note
                  AppText.caption(
                    '* Required fields',
                    color: RubyColors.getTextColor(
                      context,
                    ).withValues(alpha: 0.6),
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

  // Register user with the new registration endpoint
  Future<void> _registerUser({
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String email,
    required DateTime dateOfBirth,
    String? address,
  }) async {
    try {
      final authController = Get.find<AuthController>();
      authController.isLoading.value = true;

      // Since we don't have direct access to the repository, we'll use the controller's registerUser method
      // But first we need to add a new method that uses the new endpoint
      await authController.registerUserWithNewEndpoint(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
        address: address,
      );
    } catch (e) {
      // Error handling is done in the controller method
      print('Registration error: $e');
    }
  }
}
