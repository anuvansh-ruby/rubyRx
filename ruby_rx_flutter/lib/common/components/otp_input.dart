import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/components/app_button.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';

class OTPInput extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final int length;
  final double fieldWidth;
  final double fieldHeight;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool showVerifyButton;
  final String? verifyButtonText;
  final bool autoFocus;

  const OTPInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = 4,
    this.fieldWidth = 60,
    this.fieldHeight = 60,
    this.primaryColor = RubyColors.otpPrimaryColor,
    this.backgroundColor = RubyColors.otpBackgroundColor,
    this.textColor = RubyColors.black,
    this.borderColor = RubyColors.otpBorderColor,
    this.borderRadius = 12,
    this.textStyle,
    this.showVerifyButton = true,
    this.verifyButtonText = 'Verify',
    this.autoFocus = true,
  });

  @override
  State<OTPInput> createState() => _OTPInputState();
}

class _OTPInputState extends State<OTPInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentOTP = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // Auto focus first field
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _updateOTP() {
    setState(() {
      _currentOTP = _controllers.map((controller) => controller.text).join();

      // Call onChanged callback
      widget.onChanged?.call(_currentOTP);

      // Call onCompleted if all fields are filled
      if (_currentOTP.length == widget.length) {
        widget.onCompleted(_currentOTP);
      }
    });
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Handle paste operation - take only the first character
      value = value[0];
      _controllers[index].text = value;
    }

    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, remove focus
        _focusNodes[index].unfocus();
      }
    }
    _updateOTP();
  }

  void clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _currentOTP = '';
    });
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.length, (index) {
            return Container(
              width: widget.fieldWidth,
              height: widget.fieldHeight,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _focusNodes[index].hasFocus
                      ? widget.primaryColor
                      : widget.borderColor,
                  width: _focusNodes[index].hasFocus ? 2.0 : 1.5,
                ),
              ),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_controllers[index].text.isNotEmpty) {
                        // Clear current field
                        _controllers[index].clear();
                        _updateOTP();
                      } else if (index > 0) {
                        // Move to previous field and clear it
                        _focusNodes[index - 1].requestFocus();
                        _controllers[index - 1].clear();
                        _updateOTP();
                      }
                    }
                  }
                },
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style:
                      widget.textStyle ??
                      TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor,
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  onChanged: (value) => _onChanged(value, index),
                  onTap: () {
                    // Select all text when tapped
                    _controllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controllers[index].text.length,
                    );
                  },
                ),
              ),
            );
          }),
        ),

        // Verify Button (optional)
        if (widget.showVerifyButton) ...[
          const SizedBox(height: 32),
          AppButton(
            onPressed: () => widget.onCompleted(_currentOTP),
            label: 'Verify',
          ),
        ],
      ],
    );
  }
}

// Extension to add clear functionality
extension OTPInputExtension on GlobalKey<_OTPInputState> {
  void clearOTP() {
    currentState?.clearOTP();
  }
}

// Simple usage example
class OTPInputExample extends StatefulWidget {
  const OTPInputExample({super.key});

  @override
  State<OTPInputExample> createState() => _OTPInputExampleState();
}

class _OTPInputExampleState extends State<OTPInputExample> {
  final GlobalKey<_OTPInputState> _otpKey = GlobalKey<_OTPInputState>();
  String _enteredOTP = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.heading5('OTP Verification'),
        backgroundColor: RubyColors.otpPrimaryColor,
        foregroundColor: RubyColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.heading5(
              'Enter the 4-digit verification code',
              color: RubyColors.black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText.bodyMedium(
              'We sent a code to your registered mobile number',
              color: RubyColors.grey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // OTP Input Widget
            OTPInput(
              key: _otpKey,
              length: 4,
              onCompleted: (otp) {
                print('OTP Completed: $otp');
              },
              onChanged: (otp) {
                setState(() {
                  _enteredOTP = otp;
                });
                print('OTP Changed: $otp');
              },
              primaryColor: RubyColors.otpPrimaryColor,
              fieldWidth: 65,
              fieldHeight: 65,
            ),

            const SizedBox(height: 24),

            // Current OTP Display
            if (_enteredOTP.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: RubyColors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText.bodyMedium(
                  'Current: $_enteredOTP',
                  color: RubyColors.grey,
                ),
              ),

            const SizedBox(height: 32),

            // Clear Button
            TextButton(
              onPressed: () {
                _otpKey.clearOTP();
                setState(() {
                  _enteredOTP = '';
                });
              },
              child: AppText.bodyLarge(
                'Clear OTP',
                color: RubyColors.otpPrimaryColor,
              ),
            ),

            const SizedBox(height: 16),

            // Resend Code Button
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText.bodyMedium('Verification code resent'),
                    backgroundColor: RubyColors.otpBlueColor,
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: AppText.bodyMedium('Resend Code'),
              style: TextButton.styleFrom(
                foregroundColor: RubyColors.otpPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
