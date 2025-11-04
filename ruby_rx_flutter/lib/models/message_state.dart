import 'package:flutter/material.dart';

enum MessageType { success, error, info }

class MessageState {
  final String? message;
  final MessageType? type;
  final ErrorType? errorType;
  final DateTime? timestamp;

  MessageState({this.message, this.type, this.errorType, this.timestamp});

  MessageState.success(String message)
    : message = message,
      type = MessageType.success,
      errorType = null,
      timestamp = DateTime.now();

  MessageState.error(String message, {ErrorType? errorType})
    : message = message,
      type = MessageType.error,
      errorType = errorType,
      timestamp = DateTime.now();

  MessageState.info(String message)
    : message = message,
      type = MessageType.info,
      errorType = null,
      timestamp = DateTime.now();

  static MessageState clear() {
    return MessageState(
      message: null,
      type: null,
      errorType: null,
      timestamp: null,
    );
  }

  bool get hasMessage => message != null && message!.isNotEmpty;

  Color get backgroundColor {
    switch (type) {
      case MessageType.success:
        return Colors.green.shade600;
      case MessageType.error:
        return _getErrorColor();
      case MessageType.info:
        return Colors.blue.shade600;
      case null:
        return Colors.grey.shade600;
    }
  }

  String get title {
    switch (type) {
      case MessageType.success:
        return 'Success';
      case MessageType.error:
        return _getErrorTitle();
      case MessageType.info:
        return 'Info';
      case null:
        return '';
    }
  }

  Color _getErrorColor() {
    switch (errorType) {
      case ErrorType.network:
        return Colors.orange.shade600;
      case ErrorType.validation:
        return Colors.amber.shade600;
      case ErrorType.authentication:
        return Colors.red.shade600;
      case ErrorType.server:
        return Colors.red.shade700;
      case ErrorType.timeout:
        return Colors.purple.shade600;
      case ErrorType.unknown:
      case null:
        return Colors.red.shade600;
    }
  }

  String _getErrorTitle() {
    switch (errorType) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.authentication:
        return 'Authentication Failed';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.unknown:
      case null:
        return 'Error';
    }
  }

  MessageState copyWith({
    String? message,
    MessageType? type,
    ErrorType? errorType,
    DateTime? timestamp,
  }) {
    return MessageState(
      message: message ?? this.message,
      type: type ?? this.type,
      errorType: errorType ?? this.errorType,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// Error type enumeration for better error categorization
enum ErrorType { network, validation, authentication, server, timeout, unknown }
