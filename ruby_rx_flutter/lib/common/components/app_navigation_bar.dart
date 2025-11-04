import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../color_pallet/color_pallet.dart';
import '../widgets/app_text.dart';
import 'theme_toggle_button.dart';

class AppNavigationBar extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final bool showThemeToggle;
  final bool showProfileIcon;
  final VoidCallback? onBackPressed;
  final VoidCallback? onProfilePressed;
  final List<Widget>? actions;
  final bool isDark;
  final bool isGradient;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;

  const AppNavigationBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showThemeToggle = true,
    this.showProfileIcon = false,
    this.onBackPressed,
    this.onProfilePressed,
    this.actions,
    this.isDark = false,
    this.isGradient = false,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
  });

  // Factory constructors for common patterns
  factory AppNavigationBar.home({
    String title = 'Welcome',
    VoidCallback? onProfilePressed,
  }) {
    return AppNavigationBar(
      title: title,
      showBackButton: false,
      showThemeToggle: true,
      showProfileIcon: true,
      onProfilePressed: onProfilePressed,
    );
  }

  factory AppNavigationBar.profile({
    String title = 'Profile',
    VoidCallback? onBackPressed,
  }) {
    return AppNavigationBar(
      title: title,
      showBackButton: true,
      showThemeToggle: true,
      showProfileIcon: true,
      onBackPressed: onBackPressed,
    );
  }

  factory AppNavigationBar.gradientHeader({
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    return AppNavigationBar(
      title: title,
      showBackButton: true,
      showThemeToggle: false,
      showProfileIcon: false,
      isGradient: true,
      onBackPressed: onBackPressed,
      actions: actions,
    );
  }

  factory AppNavigationBar.simple({
    required String title,
    VoidCallback? onBackPressed,
  }) {
    return AppNavigationBar(
      title: title,
      showBackButton: true,
      showThemeToggle: false,
      showProfileIcon: false,
      onBackPressed: onBackPressed,
    );
  }

  factory AppNavigationBar.auth({required String title}) {
    return AppNavigationBar(
      title: title,
      showBackButton: true,
      showThemeToggle: false,
      showProfileIcon: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveTitleColor =
        titleColor ??
        (isDark || isGradient
            ? RubyColors.white
            : RubyColors.getTextColor(context, primary: true));
    final Color effectiveIconColor =
        iconColor ??
        (isDark || isGradient
            ? RubyColors.white
            : RubyColors.getIconColor(context));

    Widget navigationContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Back Button
          if (showBackButton)
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: effectiveIconColor),
              onPressed: onBackPressed ?? () => Get.back(),
            )
          else
            // Logo and Title Section (when no back button)
            Expanded(
              child: Row(
                children: [
                  // Ruby RX Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [RubyColors.primary1, RubyColors.primary2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: RubyColors.primary1.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        'lib/assets/ruby_rx_logo_real.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // App Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.heading4('Ruby RX', color: effectiveTitleColor),
                        AppText.caption(
                          'Your Digital Prescription Manager',
                          color: effectiveTitleColor.withOpacity(0.7),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Title for pages with back button
          if (showBackButton)
            Expanded(
              child: AppText.heading3(
                title,
                color: effectiveTitleColor,
                textAlign: TextAlign.center,
              ),
            ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom actions
              if (actions != null) ...actions!,

              // Theme Toggle
              if (showThemeToggle)
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(color: effectiveIconColor),
                  ),
                  child: const ThemeToggleIconButton(),
                ),

              // Profile Icon
              if (showProfileIcon)
                IconButton(
                  icon: Icon(Icons.person_outline, color: effectiveIconColor),
                  onPressed: onProfilePressed ?? () => Get.toNamed('/profile'),
                ),

              // Padding to balance the layout
              if (!showThemeToggle &&
                  !showProfileIcon &&
                  (actions?.isEmpty ?? true))
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );

    if (isGradient) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [RubyColors.primary2, RubyColors.primary1],
          ),
        ),
        child: navigationContent,
      );
    } else if (backgroundColor != null) {
      return Container(color: backgroundColor, child: navigationContent);
    } else {
      return navigationContent;
    }
  }
}
