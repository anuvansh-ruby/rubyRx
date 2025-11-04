import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import 'package:ruby_rx_flutter/utils/font_styles.dart';
import '../controllers/profile_controller.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/components/gradient_background.dart';

class PersonalInfoView extends StatelessWidget {
  const PersonalInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Obx(
            () => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Navigation Header
                        AppNavigationBar.profile(
                          title: 'Personal Information',
                          onBackPressed: controller.goBack,
                        ),

                        // const SizedBox(height: 8),

                        // // Profile Header Card\
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Obx(
                              () => controller.isEditing.value
                                  ? const SizedBox.shrink()
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: RubyColors.primary2,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: RubyColors.white,
                                          size: 20,
                                        ),
                                        onPressed: controller.toggleEditMode,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Personal Info Form Card
                        _buildPersonalInfoCard(controller),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(ProfileController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildPersonalInfoForm(controller),
      ),
    );
  }

  Widget _buildPersonalInfoForm(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading4('Personal Details'),
        const SizedBox(height: 20),

        // Form Fields
        _buildFormField(
          controller: controller.nameController,
          label: 'Full Name',
          value: controller.userName,
          isEditing: controller.isEditing.value,
          icon: Icons.person_outline,
        ),

        const SizedBox(height: 16),

        _buildFormField(
          controller: controller.phoneController,
          label: 'Phone Number',
          value: controller.userPhone,
          isEditing: false,
          icon: Icons.phone_outlined,
        ),

        const SizedBox(height: 16),

        _buildFormField(
          controller: controller.emailController,
          label: 'Email Address',
          value: controller.userEmail,
          isEditing: controller.isEditing.value,
          icon: Icons.email_outlined,
        ),

        const SizedBox(height: 16),

        _buildFormField(
          controller: controller.addressController,
          label: 'Address',
          value: controller.userAddress,
          isEditing: controller.isEditing.value,
          icon: Icons.location_on_outlined,
          maxLines: 3,
        ),

        const SizedBox(height: 24),

        // Save Button
        Obx(
          () => controller.isEditing.value
              ? SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RubyColors.primary2,
                      foregroundColor: RubyColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: AppText.buttonMedium('Save Changes'),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String value,
    required bool isEditing,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: AppText.bodySmall(label, color: RubyColors.grey),
        ),
        Container(
          decoration: BoxDecoration(
            color: isEditing
                ? RubyColors.white
                : RubyColors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEditing
                  ? RubyColors.primary2.withOpacity(0.5)
                  : RubyColors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: isEditing,
            maxLines: maxLines,
            style: FontStyles.bodyMedium.copyWith(
              color: RubyColors.black,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintStyle: FontStyles.bodyMedium.copyWith(color: RubyColors.grey),
              prefixIcon: Icon(
                icon,
                color: isEditing ? RubyColors.primary2 : RubyColors.grey,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
