import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../color_pallet/color_pallet.dart';
import '../widgets/app_text.dart';

/// Enhanced notification card system for displaying messages directly in pages
class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onDismiss;
  final bool dismissible;
  final Duration? autoHideDuration;
  final IconData? customIcon;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.onDismiss,
    this.dismissible = true,
    this.autoHideDuration,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getBackgroundColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getBorderColor(), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _getBorderColor().withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getIconBackgroundColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        customIcon ?? _getIcon(),
                        color: _getIconColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.heading5(
                            title,
                            color: RubyColors.getTextColor(
                              context,
                              primary: true,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AppText.bodyMedium(
                            message,
                            color: RubyColors.getTextColor(
                              context,
                            ).withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),

                    // Dismiss button
                    if (dismissible)
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: RubyColors.getTextColor(
                              context,
                            ).withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case NotificationType.success:
        return isDark
            ? Colors.green.shade900.withOpacity(0.3)
            : Colors.green.shade50;
      case NotificationType.error:
        return isDark
            ? Colors.red.shade900.withOpacity(0.3)
            : Colors.red.shade50;
      case NotificationType.warning:
        return isDark
            ? Colors.orange.shade900.withOpacity(0.3)
            : Colors.orange.shade50;
      case NotificationType.info:
        return isDark
            ? Colors.blue.shade900.withOpacity(0.3)
            : Colors.blue.shade50;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade300;
      case NotificationType.error:
        return Colors.red.shade300;
      case NotificationType.warning:
        return Colors.orange.shade300;
      case NotificationType.info:
        return Colors.blue.shade300;
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade100;
      case NotificationType.error:
        return Colors.red.shade100;
      case NotificationType.warning:
        return Colors.orange.shade100;
      case NotificationType.info:
        return Colors.blue.shade100;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.error:
        return Colors.red.shade600;
      case NotificationType.warning:
        return Colors.orange.shade600;
      case NotificationType.info:
        return Colors.blue.shade600;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }
}

/// Notification types for different message categories
enum NotificationType { success, error, warning, info }

/// Controller for managing notification cards display
class NotificationController extends GetxController {
  final RxList<NotificationCardData> _notifications =
      <NotificationCardData>[].obs;

  List<NotificationCardData> get notifications => _notifications;

  /// Show a notification card
  void showNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration? autoHideDuration = const Duration(seconds: 5),
    IconData? customIcon,
    bool dismissible = true,
  }) {
    final notification = NotificationCardData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      dismissible: dismissible,
      customIcon: customIcon,
    );

    _notifications.add(notification);

    // Auto-hide after duration
    if (autoHideDuration != null) {
      Future.delayed(autoHideDuration, () {
        hideNotification(notification.id);
      });
    }
  }

  /// Show success notification
  void showSuccess(String title, String message, {Duration? duration}) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.success,
      autoHideDuration: duration,
    );
  }

  /// Show error notification
  void showError(String title, String message, {Duration? duration}) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.error,
      autoHideDuration:
          duration ?? const Duration(seconds: 8), // Longer for errors
    );
  }

  /// Show warning notification
  void showWarning(String title, String message, {Duration? duration}) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.warning,
      autoHideDuration: duration,
    );
  }

  /// Show info notification
  void showInfo(String title, String message, {Duration? duration}) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.info,
      autoHideDuration: duration,
    );
  }

  /// Hide specific notification
  void hideNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }
}

/// Data class for notification card information
class NotificationCardData {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool dismissible;
  final IconData? customIcon;

  NotificationCardData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.dismissible = true,
    this.customIcon,
  });
}

/// Widget for displaying notification cards in a list
class NotificationCardsList extends StatelessWidget {
  final NotificationController controller;

  const NotificationCardsList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: controller.notifications.map((notification) {
          return NotificationCard(
            title: notification.title,
            message: notification.message,
            type: notification.type,
            dismissible: notification.dismissible,
            customIcon: notification.customIcon,
            onDismiss: () => controller.hideNotification(notification.id),
          );
        }).toList(),
      ),
    );
  }
}

/// Prescription-specific notification cards
class PrescriptionNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onActionPressed;
  final String? actionText;

  const PrescriptionNotificationCard({
    super.key,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.onDismiss,
    this.onActionPressed,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getBorderColor().withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPrescriptionIcon(),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.heading4(title, color: Colors.white),
                      const SizedBox(height: 4),
                      AppText.bodyMedium(message, color: Colors.white),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _getBorderColor(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: AppText.buttonMedium(
                    actionText!,
                    color: _getBorderColor(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (type) {
      case NotificationType.success:
        return [Colors.green.shade400, Colors.green.shade600];
      case NotificationType.error:
        return [Colors.red.shade400, Colors.red.shade600];
      case NotificationType.warning:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case NotificationType.info:
        return [RubyColors.primary1, RubyColors.primary2];
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.error:
        return Colors.red.shade600;
      case NotificationType.warning:
        return Colors.orange.shade600;
      case NotificationType.info:
        return RubyColors.primary2;
    }
  }

  IconData _getPrescriptionIcon() {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.medical_services;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }
}
