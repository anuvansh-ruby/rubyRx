import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/components/floating_actions.dart';
import 'package:ruby_rx_flutter/common/components/notification_card.dart';
import '../controllers/home_controller.dart';
import '../common/components/gradient_background.dart';
import '../common/components/app_navigation_bar.dart';
import '../common/widgets/app_text.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Notification cards at the top
              NotificationCardsList(
                controller: controller.notificationController,
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Navigation Header
                      AppNavigationBar.home(
                        title: 'Ruby RX',
                        onProfilePressed: controller.navigateToProfile,
                      ),

                      const SizedBox(height: 20),

                      // Instructions Section
                      _buildInstructionsSection(context),

                      const SizedBox(height: 40),

                      // Drug Wallet Section
                      _buildDrugWalletSection(context, controller),

                      const SizedBox(height: 40),

                      // Action Section Title
                      _buildActionSectionTitle(context),

                      const SizedBox(height: 24),

                      // Main Action Buttons
                      _buildActionButtons(context, controller),

                      const SizedBox(height: 40),

                      // Additional Info Section
                      _buildAdditionalInfo(context),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        onHomePressed: () {
          print('Home Pressed');
        },
        onPrescriptionPressed: () {
          Get.toNamed('/prescription-manager');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Instructions Section
  Widget _buildInstructionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RubyColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RubyColors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Instruction Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [RubyColors.primary1, RubyColors.primary2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: RubyColors.primary1.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'lib/assets/ruby_rx_logo_real.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          AppText.heading2(
            'Welcome to Ruby RX',
            color: RubyColors.getTextColor(context, primary: true),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          AppText.subtitle1(
            'Your digital prescription companion',
            color: RubyColors.getTextColor(context).withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Benefits Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBenefitItem(
                context,
                Icons.security,
                'Secure',
                'HIPAA compliant\nstorage',
                RubyColors.primary1,
              ),
              _buildBenefitItem(
                context,
                Icons.access_time,
                'Fast',
                'Quick processing',
                RubyColors.primary1,
              ),
              _buildBenefitItem(
                context,
                Icons.sync,
                'Synced',
                'Multi-device\naccess',
                RubyColors.primary1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action Section Title
  Widget _buildActionSectionTitle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RubyColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RubyColors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularActionButton(
                context: context,
                title: 'Add\nPrescription',
                description: 'Scan or upload\nprescription\nimage',
                icon: Icons.add_photo_alternate,
                color: RubyColors.primary1,
                isLoading: false,
                onTap: () {
                  _showPrescriptionOptionsBottomSheet(context);
                },
              ),
              _buildCircularActionButton(
                context: context,
                title: 'Sync\nRuby',
                description: 'Sync your\ndata with\nRuby AI',
                icon: Icons.sync,
                color: RubyColors.purple,
                isLoading: false,
                onTap: () {
                  final controller = Get.find<HomeController>();
                  // TODO: Implement sync functionality
                  controller.notificationController.showInfo(
                    'Sync Ruby',
                    'Syncing your data with Ruby AI...',
                  );
                },
              ),
              _buildCircularActionButton(
                context: context,
                title: 'Create\nManually',
                description: 'Manually\nenter\nprescription\ndetails',
                icon: Icons.edit_note,
                color: RubyColors.green,
                isLoading: false,
                onTap: () {
                  Get.toNamed('/manual-entry');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show bottom sheet with prescription options
  void _showPrescriptionOptionsBottomSheet(BuildContext context) {
    final controller = Get.find<HomeController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: RubyColors.getCardBackgroundColor(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RubyColors.getTextColor(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: AppText.heading3(
                    'Add Prescription',
                    color: RubyColors.getTextColor(context, primary: true),
                  ),
                ),

                // Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Scan with Camera option
                      _buildBottomSheetOption(
                        context: context,
                        icon: Icons.camera_alt,
                        title: 'Scan with Camera',
                        description: 'Use camera to scan physical prescription',
                        color: RubyColors.primary1,
                        onTap: () {
                          Navigator.pop(context);
                          controller.scanPrescriptionWithCamera();
                        },
                      ),

                      const SizedBox(height: 12),

                      // Upload from Gallery option
                      _buildBottomSheetOption(
                        context: context,
                        icon: Icons.photo_library,
                        title: 'Upload from Gallery',
                        description: 'Choose prescription image from gallery',
                        color: RubyColors.primary2,
                        onTap: () {
                          Navigator.pop(context);
                          controller.uploadPrescriptionFromGallery();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bottom sheet option item
  Widget _buildBottomSheetOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: RubyColors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.subtitle1(
                      title,
                      color: RubyColors.getTextColor(context, primary: true),
                    ),
                    const SizedBox(height: 4),
                    AppText.caption(
                      description,
                      color: RubyColors.getTextColor(context).withOpacity(0.7),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Action Buttons Section - keeping for backward compatibility but will be empty
  Widget _buildActionButtons(BuildContext context, HomeController controller) {
    return const SizedBox.shrink();
  }

  // Drug Wallet Section
  Widget _buildDrugWalletSection(
    BuildContext context,
    HomeController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [RubyColors.purple, RubyColors.purple.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RubyColors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.toNamed('/drug-wallet'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RubyColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: RubyColors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.heading4('Drug Wallet', color: RubyColors.white),
                      const SizedBox(height: 4),
                      AppText.bodyMedium(
                        'View all your medicines from all prescriptions',
                        color: RubyColors.white.withOpacity(0.9),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: RubyColors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Additional Info Section
  Widget _buildAdditionalInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RubyColors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RubyColors.blue.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, color: RubyColors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.captionBold('Healthcare Tip', color: RubyColors.blue),
                const SizedBox(height: 4),
                AppText.caption(
                  'Always consult your healthcare provider before making any changes to your medication.',
                  color: RubyColors.blue.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for benefit items
  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          AppText.subtitle2(
            title,
            color: RubyColors.getTextColor(context, primary: true),
          ),
          const SizedBox(height: 4),
          AppText.caption(
            description,
            color: RubyColors.getTextColor(context).withOpacity(0.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method for circular action buttons
  Widget _buildCircularActionButton({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: RubyColors.white, size: 32),
            ),
            const SizedBox(height: 16),
            AppText.subtitle2(
              title,
              color: RubyColors.getTextColor(context, primary: true),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText.caption(
              description,
              color: RubyColors.getTextColor(context).withOpacity(0.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
