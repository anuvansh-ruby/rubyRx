import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';
import '../controllers/profile_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

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
                          title: 'Profile',
                          onBackPressed: controller.goBack,
                        ),

                        const SizedBox(height: 8),

                        // Profile Header
                        _buildProfileHeader(controller),

                        const SizedBox(height: 24),

                        // Settings Section
                        _buildSettingsSection(controller),

                        const SizedBox(height: 24),

                        // Account Actions
                        _buildAccountActions(controller),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                Obx(
                  () => CircleAvatar(
                    radius: 50,
                    backgroundColor: RubyColors.primary2.withOpacity(0.1),
                    backgroundImage:
                        controller.profileImagePath.value.isNotEmpty
                        ? AssetImage(controller.profileImagePath.value)
                        : null,
                    child: controller.profileImagePath.value.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: RubyColors.primary2,
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppText.heading3(controller.userName),
            const SizedBox(height: 4),
            AppText.bodyMedium(controller.userEmail, color: RubyColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ProfileController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading4('App Settings'),
            const SizedBox(height: 16),

            // Notifications Toggle
            Obx(
              () => SwitchListTile(
                title: AppText.bodyMedium('Push Notifications'),
                subtitle: AppText.bodySmall('Receive app notifications'),
                value: controller.notificationsEnabled.value,
                onChanged: controller.toggleNotifications,
                activeThumbColor: RubyColors.primary2,
              ),
            ),

            // Biometric Toggle
            Obx(
              () => SwitchListTile(
                title: AppText.bodyMedium('Biometric Login'),
                subtitle: AppText.bodySmall('Use fingerprint or face ID'),
                value: controller.biometricEnabled.value,
                onChanged: controller.isLoading.value
                    ? null // Disable the switch when loading
                    : (value) {
                        // Don't await here - let the controller handle the state
                        controller.toggleBiometric(value);
                      },
                activeThumbColor: RubyColors.primary2,
              ),
            ),

            // Dark Mode Toggle
            Obx(
              () => SwitchListTile(
                title: AppText.bodyMedium('Dark Mode'),
                subtitle: AppText.bodySmall('Switch to dark theme'),
                value: controller.darkModeEnabled.value,
                onChanged: controller.toggleDarkMode,
                activeThumbColor: RubyColors.primary2,
              ),
            ),

            // // Auto Backup Toggle
            // Obx(
            //   () => SwitchListTile(
            //     title: const Text('Auto Backup'),
            //     subtitle: const Text('Automatically backup data'),
            //     value: controller.autoBackupEnabled.value,
            //     onChanged: controller.toggleAutoBackup,
            //     activeThumbColor: RubyColors.primary2,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(ProfileController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading4('Account Actions'),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: RubyColors.primary2,
              ),
              title: AppText.bodyMedium('Personal Information'),
              subtitle: AppText.bodySmall('Edit your personal details'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.navigateToPersonalInfo,
            ),

            ListTile(
              leading: const Icon(
                Icons.lock_outline,
                color: RubyColors.primary2,
              ),
              title: AppText.bodyMedium('Change PIN'),
              subtitle: AppText.bodySmall('Update your security PIN'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.changePin,
            ),

            ListTile(
              leading: const Icon(Icons.security, color: RubyColors.orange),
              title: AppText.bodyMedium('Security Settings'),
              subtitle: AppText.bodySmall('Manage account security'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.navigateToSecurity,
            ),

            ListTile(
              leading: const Icon(Icons.privacy_tip, color: RubyColors.green),
              title: AppText.bodyMedium('Privacy Settings'),
              subtitle: AppText.bodySmall('Control your privacy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.navigateToPrivacy,
            ),

            ListTile(
              leading: const Icon(Icons.help_outline, color: RubyColors.purple),
              title: AppText.bodyMedium('Help & Support'),
              subtitle: AppText.bodySmall('Get help and support'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.navigateToHelp,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: RubyColors.red),
              title: AppText.bodyMedium('Logout'),
              subtitle: AppText.bodySmall('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.logout,
            ),

            ListTile(
              leading: const Icon(Icons.delete_forever, color: RubyColors.red),
              title: AppText.bodyMedium('Delete Account'),
              subtitle: AppText.bodySmall('Permanently delete your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
