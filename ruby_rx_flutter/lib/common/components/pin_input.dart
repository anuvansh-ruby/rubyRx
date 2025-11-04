import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';

class PINInput extends StatefulWidget {
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
  final bool obscureText;
  final Widget? verifyButtonIcon;
  final bool isLoading;

  const PINInput({
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
    this.verifyButtonText = 'Verify PIN',
    this.autoFocus = true,
    this.obscureText = true,
    this.verifyButtonIcon,
    this.isLoading = false,
  });

  @override
  State<PINInput> createState() => _PINInputState();
}

class _PINInputState extends State<PINInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentPIN = '';

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

  void _updatePIN() {
    setState(() {
      _currentPIN = _controllers.map((controller) => controller.text).join();

      // Call onChanged callback
      widget.onChanged?.call(_currentPIN);

      // Call onCompleted if all fields are filled
      if (_currentPIN.length == widget.length) {
        widget.onCompleted(_currentPIN);
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
    _updatePIN();
  }

  void clearPIN() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _currentPIN = '';
    });
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN Input Fields
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
                        _updatePIN();
                      } else if (index > 0) {
                        // Move to previous field and clear it
                        _focusNodes[index - 1].requestFocus();
                        _controllers[index - 1].clear();
                        _updatePIN();
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
                  obscureText: widget.obscureText,
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isLoading || _currentPIN.length != widget.length
                  ? null
                  : () => widget.onCompleted(_currentPIN),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.verifyButtonIcon != null) ...[
                          widget.verifyButtonIcon!,
                          const SizedBox(width: 8),
                        ],
                        AppText.bodyLarge(
                          widget.verifyButtonText ?? 'Verify PIN',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

// Extension to add clear functionality
extension PINInputExtension on GlobalKey<State<PINInput>> {
  void clearPIN() {
    final state = currentState;
    if (state is _PINInputState) {
      state.clearPIN();
    }
  }
}

// Simple usage example
class PINInputExample extends StatefulWidget {
  const PINInputExample({super.key});

  @override
  State<PINInputExample> createState() => _PINInputExampleState();
}

class _PINInputExampleState extends State<PINInputExample> {
  final GlobalKey<State<PINInput>> _pinKey = GlobalKey<State<PINInput>>();
  String _enteredPIN = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.heading5('PIN Verification'),
        backgroundColor: RubyColors.otpPrimaryColor,
        foregroundColor: RubyColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.heading5(
              'Enter your 4-digit PIN',
              color: RubyColors.black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText.bodyMedium(
              'Please enter your secure PIN to continue',
              color: RubyColors.grey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // PIN Input Widget
            PINInput(
              key: _pinKey,
              length: 4,
              isLoading: _isLoading,
              onCompleted: (pin) async {
                setState(() {
                  _isLoading = true;
                });

                // Simulate verification
                await Future.delayed(const Duration(seconds: 2));

                setState(() {
                  _isLoading = false;
                });

                // Handle PIN verification result here
                // Example: Navigate to next screen or show error
              },
              onChanged: (pin) {
                setState(() {
                  _enteredPIN = pin;
                });
                // Handle PIN change here
              },
              primaryColor: RubyColors.otpPrimaryColor,
              fieldWidth: 65,
              fieldHeight: 65,
              verifyButtonIcon: const Icon(Icons.lock, size: 18),
            ),

            const SizedBox(height: 24),

            // Current PIN Display (for testing - remove in production)
            if (_enteredPIN.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: RubyColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText.bodyMedium(
                  'Current: ${'*' * _enteredPIN.length}',
                  color: RubyColors.grey,
                ),
              ),

            const SizedBox(height: 32),

            // Clear Button
            TextButton(
              onPressed: () {
                _pinKey.clearPIN();
                setState(() {
                  _enteredPIN = '';
                });
              },
              child: AppText.bodyLarge(
                'Clear PIN',
                color: RubyColors.otpPrimaryColor,
              ),
            ),

            const SizedBox(height: 16),

            // Forgot PIN Button
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText.bodyMedium('Redirecting to PIN reset...'),
                    backgroundColor: RubyColors.otpBlueColor,
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: AppText.bodyMedium('Forgot PIN?'),
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
