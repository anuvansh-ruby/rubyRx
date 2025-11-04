import 'package:flutter/material.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback? onHomePressed;
  final VoidCallback? onPrescriptionPressed;

  // Color parameters
  final Color? backgroundColor;
  final Color? homeIconColor;
  final Color? prescriptionIconColor;
  final Color? homeTextColor;
  final Color? prescriptionTextColor;
  final Color? dividerColor;

  // Size parameters
  final double? width;
  final double? height;
  final double? iconSize;
  final double? fontSize;
  final double? borderRadius;
  final double? dividerWidth;
  final double? spaceBetweenIconAndText;

  // Content parameters
  final IconData? homeIcon;
  final IconData? prescriptionIcon;
  final String? homeText;
  final String? prescriptionText;
  final double? paddingOuter;

  const CustomFloatingActionButton({
    super.key,
    this.onHomePressed,
    this.onPrescriptionPressed,
    // Color defaults
    this.backgroundColor,
    this.homeIconColor,
    this.prescriptionIconColor,
    this.homeTextColor,
    this.prescriptionTextColor,
    this.dividerColor,
    // Size defaults
    this.width,
    this.height,
    this.iconSize,
    this.fontSize,
    this.borderRadius,
    this.dividerWidth,
    this.spaceBetweenIconAndText,
    // Content defaults
    this.homeIcon,
    this.prescriptionIcon,
    this.homeText,
    this.prescriptionText,
    this.paddingOuter,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final adaptiveBackgroundColor =
        backgroundColor ??
        (isDarkMode ? RubyColors.darkContainerBackground : RubyColors.white);
    final adaptiveDividerColor =
        dividerColor ?? (isDarkMode ? Colors.white24 : RubyColors.grey);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingOuter ?? 8.0),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 90,
        decoration: BoxDecoration(
          color: adaptiveBackgroundColor,
          borderRadius: BorderRadius.circular(borderRadius ?? 30),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.black : RubyColors.black).withOpacity(
                0.1,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Home button
            Expanded(
              child: Material(
                color: RubyColors.transparent,
                child: InkWell(
                  onTap: onHomePressed,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius ?? 30),
                    bottomLeft: Radius.circular(borderRadius ?? 30),
                  ),
                  child: SizedBox(
                    height: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          homeIcon ?? Icons.home_rounded,
                          size: iconSize ?? 22,
                          color: homeIconColor ?? RubyColors.primary2,
                        ),
                        SizedBox(height: spaceBetweenIconAndText ?? 4),
                        AppText.caption(
                          homeText ?? 'Home',
                          color: homeTextColor ?? RubyColors.primary2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Divider
            Container(
              width: dividerWidth ?? 1,
              height: (height ?? 60) * 0.6,
              color: adaptiveDividerColor,
            ),

            // Prescription Manager button
            Expanded(
              child: Material(
                color: RubyColors.transparent,
                child: InkWell(
                  onTap: onPrescriptionPressed,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(borderRadius ?? 30),
                    bottomRight: Radius.circular(borderRadius ?? 30),
                  ),
                  child: SizedBox(
                    height: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          prescriptionIcon ?? Icons.receipt_long_rounded,
                          size: iconSize ?? 22,
                          color: prescriptionIconColor ?? RubyColors.primary2,
                        ),
                        SizedBox(height: spaceBetweenIconAndText ?? 4),
                        AppText.caption(
                          prescriptionText ?? 'Prescription\nManager',
                          color: prescriptionTextColor ?? RubyColors.primary2,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
