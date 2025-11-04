import 'package:flutter/material.dart';
import '../color_pallet/color_pallet.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  RubyColors.darkBackgroundTop, // Dark background top
                  RubyColors.darkBackgroundBottom, // Dark background bottom
                ]
              : [
                  RubyColors.background, // Light background top
                  RubyColors.white, // Light background bottom
                ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
