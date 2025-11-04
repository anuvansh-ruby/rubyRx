import 'package:flutter/material.dart';
import '../widgets/app_text.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool isVisible;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onDismiss,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: AppText.bodyMedium(message, color: Colors.red.shade700),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: Colors.red.shade600, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}

class SuccessDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool isVisible;

  const SuccessDisplay({
    super.key,
    required this.message,
    this.onDismiss,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText.bodyMedium(message, color: Colors.green.shade700),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: Colors.green.shade600, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}
