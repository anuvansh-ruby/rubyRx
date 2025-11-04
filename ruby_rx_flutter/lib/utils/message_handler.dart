import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/message_state.dart';
import '../common/color_pallet/color_pallet.dart';

class MessageHandler {
  /// Shows a snackbar based on the message state
  static void showMessage(MessageState messageState) {
    if (!messageState.hasMessage) return;

    // Use post frame callback to ensure overlay is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.context != null && Get.isRegistered<GetMaterialApp>()) {
          Get.snackbar(
            messageState.title,
            messageState.message!,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: messageState.backgroundColor,
            colorText: RubyColors.white,
            duration: Duration(
              seconds: messageState.type == MessageType.error ? 4 : 3,
            ),
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            isDismissible: true,
            dismissDirection: DismissDirection.horizontal,
            forwardAnimationCurve: Curves.easeOutBack,
          );
        }
      } catch (e) {
        // Silently handle any overlay errors
        print('Error showing snackbar: $e');
      }
    });
  }

  /// Shows a success message
  static void showSuccess(String message) {
    showMessage(MessageState.success(message));
  }

  /// Shows an error message
  static void showError(String message, {ErrorType? errorType}) {
    showMessage(MessageState.error(message, errorType: errorType));
  }

  /// Shows an info message
  static void showInfo(String message) {
    showMessage(MessageState.info(message));
  }
}

/// A widget that listens to message state changes and shows snackbars accordingly
class MessageListener extends StatefulWidget {
  final Rx<MessageState> messageState;
  final VoidCallback? onMessageShown;
  final Widget child;

  const MessageListener({
    super.key,
    required this.messageState,
    required this.child,
    this.onMessageShown,
  });

  @override
  State<MessageListener> createState() => _MessageListenerState();
}

class _MessageListenerState extends State<MessageListener> {
  MessageState? _lastShownMessage;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentMessage = widget.messageState.value;

      // Show message if there's a new one and it's different from the last shown message
      if (currentMessage.hasMessage &&
          currentMessage.timestamp != _lastShownMessage?.timestamp) {
        // Schedule the snackbar to show after build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            MessageHandler.showMessage(currentMessage);
            _lastShownMessage = currentMessage;
            widget.onMessageShown?.call();
          }
        });
      }

      return widget.child;
    });
  }
}
