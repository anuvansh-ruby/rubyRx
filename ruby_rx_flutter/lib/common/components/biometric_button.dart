import 'package:flutter/material.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';

class BiometricButton extends StatelessWidget {
  final bool hasBiometricStored;
  final VoidCallback? onPressed;
  final VoidCallback? onAddBiometric;
  final VoidCallback? onLoginWithBiometric;

  // Color parameters
  final Color? addBiometricButtonColor;
  final Color? addBiometricTextColor;
  final Color? addBiometricBorderColor;
  final Color? loginBiometricButtonColor;
  final Color? loginBiometricTextColor;
  final Color? loginBiometricBorderColor;
  final Color? iconColor;
  final Color? disabledColor;

  // Size parameters
  final double? fontSize;
  final double? iconSize;
  final double? borderRadius;
  final double? borderWidth;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final double? spaceBetweenIconAndText;

  // Content parameters
  final String? addBiometricText;
  final String? loginBiometricText;
  final IconData? addBiometricIcon;
  final IconData? loginBiometricIcon;
  final bool isLoading;

  const BiometricButton({
    super.key,
    required this.hasBiometricStored,
    this.onPressed,
    this.onAddBiometric,
    this.onLoginWithBiometric,
    // Color defaults
    this.addBiometricButtonColor,
    this.addBiometricTextColor,
    this.addBiometricBorderColor,
    this.loginBiometricButtonColor,
    this.loginBiometricTextColor,
    this.loginBiometricBorderColor,
    this.iconColor,
    this.disabledColor,
    // Size defaults
    this.fontSize,
    this.iconSize,
    this.borderRadius,
    this.borderWidth,
    this.padding,
    this.height,
    this.width,
    this.spaceBetweenIconAndText,
    // Content defaults
    this.addBiometricText,
    this.loginBiometricText,
    this.addBiometricIcon,
    this.loginBiometricIcon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAddMode = !hasBiometricStored;
    final VoidCallback? effectiveCallback = isLoading
        ? null
        : (onPressed ?? (isAddMode ? onAddBiometric : onLoginWithBiometric));

    final String buttonText = isAddMode
        ? (addBiometricText ?? 'Add Biometric')
        : (loginBiometricText ?? 'Login with Biometric');

    final IconData buttonIcon = isAddMode
        ? (addBiometricIcon ?? Icons.fingerprint_outlined)
        : (loginBiometricIcon ?? Icons.fingerprint);

    return SizedBox(
      height: height ?? 150,
      width: width,
      child: Material(
        color: RubyColors.transparent,
        child: InkWell(
          onTap: effectiveCallback,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      height: iconSize ?? 100,
                      width: iconSize ?? 100,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAddMode
                              ? (addBiometricTextColor ?? RubyColors.primary1)
                              : (loginBiometricTextColor ??
                                    RubyColors.primary1),
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        buttonIcon,
                        size: iconSize ?? 100,
                        color: effectiveCallback != null
                            ? (iconColor ??
                                  (isAddMode
                                      ? (addBiometricTextColor ??
                                            RubyColors.primary1)
                                      : (loginBiometricTextColor ??
                                            RubyColors.primary1)))
                            : RubyColors.grey,
                      ),
                      SizedBox(height: spaceBetweenIconAndText ?? 6),
                      AppText.bodySmall(
                        buttonText,
                        color: effectiveCallback != null
                            ? (isAddMode
                                  ? (addBiometricTextColor ??
                                        RubyColors.primary1)
                                  : (loginBiometricTextColor ??
                                        RubyColors.primary1))
                            : RubyColors.grey,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Example usage:
class ExampleUsage extends StatefulWidget {
  const ExampleUsage({super.key});

  @override
  _ExampleUsageState createState() => _ExampleUsageState();
}

class _ExampleUsageState extends State<ExampleUsage> {
  bool _hasBiometric1 = false;
  final bool _hasBiometric2 = true;
  bool _isLoading = false;

  void _toggleBiometric() {
    setState(() {
      _hasBiometric1 = !_hasBiometric1;
    });
  }

  void _simulateLoading() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.heading5('Biometric Button Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add Biometric state (transparent background)
            BiometricButton(
              hasBiometricStored: _hasBiometric1,
              height: 80,
              width: 120,
              borderRadius: 8,
              addBiometricTextColor: RubyColors.primary1,
              loginBiometricTextColor: RubyColors.primary1,
              iconSize: 32,
              fontSize: 12,
              spaceBetweenIconAndText: 8,
              onAddBiometric: () {
                print('Adding biometric...');
                _toggleBiometric();
              },
              onLoginWithBiometric: () {
                print('Logging in with biometric...');
              },
            ),
            const SizedBox(height: 16),

            // Login with Biometric state
            BiometricButton(
              hasBiometricStored: _hasBiometric2,
              onAddBiometric: () {
                print('Adding biometric...');
              },
              onLoginWithBiometric: () {
                print('Logging in with biometric...');
              },
            ),
            const SizedBox(height: 16),

            // Loading state
            BiometricButton(
              hasBiometricStored: true,
              isLoading: _isLoading,
              onLoginWithBiometric: () {
                _simulateLoading();
              },
            ),
            const SizedBox(height: 16),

            // Custom styled button
            BiometricButton(
              hasBiometricStored: false,
              addBiometricButtonColor: RubyColors.green,
              addBiometricTextColor: RubyColors.green,
              addBiometricBorderColor: RubyColors.green,
              addBiometricText: 'Setup Fingerprint',
              addBiometricIcon: Icons.fingerprint_outlined,
              fontSize: 16,
              iconSize: 24,
              borderRadius: 12,
              height: 56,
              spaceBetweenIconAndText: 12,
              onAddBiometric: () {
                print('Custom add biometric');
              },
            ),
            const SizedBox(height: 16),

            // Custom login button
            BiometricButton(
              hasBiometricStored: true,
              loginBiometricButtonColor: RubyColors.primary1,
              loginBiometricTextColor: RubyColors.white,
              loginBiometricText: 'Unlock with Touch ID',
              loginBiometricIcon: Icons.touch_app,
              fontSize: 16,
              iconSize: 24,
              borderRadius: 25,
              height: 56,
              onLoginWithBiometric: () {
                print('Custom login with biometric');
              },
            ),
            const SizedBox(height: 32),

            // Toggle button for demo
            ElevatedButton(
              onPressed: _toggleBiometric,
              child: AppText.bodyMedium('Toggle First Button State'),
            ),
          ],
        ),
      ),
    );
  }
}
