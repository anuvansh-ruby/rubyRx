import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import '../../controllers/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  final double? size;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const ThemeToggleButton({
    super.key,
    this.size = 24.0,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Get or create ThemeController instance
    final ThemeController themeController = Get.put(ThemeController());

    return Obx(() {
      final isDark = themeController.isDarkMode;

      return Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => themeController.toggleTheme(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).brightness == Brightness.dark
                  ? RubyColors.white.withOpacity(0.1)
                  : RubyColors.black.withOpacity(0.05),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: Icon(
                isDark ? Bootstrap.sun : Bootstrap.moon,
                key: ValueKey(isDark),
                size: size,
                color:
                    iconColor ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? RubyColors.orange
                        : RubyColors.primary2),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class ThemeToggleIconButton extends StatelessWidget {
  final double? size;
  final Color? iconColor;
  final VoidCallback? onPressed;

  const ThemeToggleIconButton({
    super.key,
    this.size = 24.0,
    this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get or create ThemeController instance
    final ThemeController themeController = Get.put(ThemeController());

    return Obx(() {
      final isDark = themeController.isDarkMode;

      return IconButton(
        onPressed: onPressed ?? () => themeController.toggleTheme(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return RotationTransition(turns: animation, child: child);
          },
          child: Icon(
            isDark ? Bootstrap.sun : Bootstrap.moon,
            key: ValueKey(isDark),
            size: size,
            color:
                iconColor ??
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.yellow[300]
                    : Colors.indigo[700]),
          ),
        ),
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      );
    });
  }
}
