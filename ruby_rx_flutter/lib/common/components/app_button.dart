import 'package:flutter/material.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import '../widgets/app_text.dart';

class AppButton extends StatelessWidget {
  final Function()? onPressed;
  final String label;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final Color? textColor;
  final double? borderRadius;
  final double? padding;
  final bool? isDisabled;
  final Color? disabledColor;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.fontSize,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.isDisabled,
    this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 50,
      padding: EdgeInsets.all(padding ?? 0),
      child: ElevatedButton(
        onPressed: isDisabled == true ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            isDisabled == true
                ? (disabledColor ?? RubyColors.primary2Disabled)
                : color ?? RubyColors.primary2,
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 10.0),
              side: borderColor != null
                  ? BorderSide(color: borderColor!)
                  : BorderSide.none,
            ),
          ),
        ),
        child: AppText.buttonLarge(label, color: textColor ?? RubyColors.white),
      ),
    );
  }
}
