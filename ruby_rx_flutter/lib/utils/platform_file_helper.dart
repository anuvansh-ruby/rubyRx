import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

/// Cross-platform file helper that works on both web and mobile
class PlatformFileHelper {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Validate image file from XFile
  static Future<String?> validateImageFile(XFile imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        return 'File is empty or corrupted';
      }
      if (fileSize > 10 * 1024 * 1024) {
        return 'File size exceeds 10MB limit';
      }

      // PRIORITY 1: Check MIME type first (most reliable for mobile/camera images)
      const allowedMimeTypes = [
        'image/jpeg',
        'image/jpg',
        'image/png',
        'image/gif',
        'image/bmp',
        'image/webp',
        'image/tiff',
        'image/tif',
      ];

      if (imageFile.mimeType != null && imageFile.mimeType!.isNotEmpty) {
        // MIME type is available - use it as primary validation
        if (!imageFile.mimeType!.startsWith('image/')) {
          return 'Selected file is not a valid image';
        }

        // Additional check: ensure it's an allowed image type
        final mimeType = imageFile.mimeType!.toLowerCase();
        final isAllowedMimeType = allowedMimeTypes.any(
          (type) => mimeType == type,
        );

        if (!isAllowedMimeType) {
          // Still allow it if it's any image/* type (more permissive)
          if (!mimeType.startsWith('image/')) {
            return 'Unsupported image format. Please use common formats like JPG, PNG, etc.';
          }
        }

        // MIME type validation passed
        return null;
      }

      // PRIORITY 2: Fallback to file extension check if MIME type not available
      final extension = imageFile.path.split('.').last.toLowerCase();
      const allowedExtensions = [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
        'tiff',
        'tif',
      ];

      if (!allowedExtensions.contains(extension)) {
        // More permissive: if path doesn't have extension but name does, check name
        final fileName = imageFile.name.toLowerCase();
        final hasValidExtension = allowedExtensions.any(
          (ext) => fileName.endsWith('.$ext'),
        );

        if (!hasValidExtension) {
          return 'Invalid file format. Please use: ${allowedExtensions.join(', ')}';
        }
      }

      return null; // No validation errors
    } catch (e) {
      return 'Error validating file: $e';
    }
  }

  /// Create MultipartFile from XFile (works on both web and mobile)
  static Future<MultipartFile> createMultipartFile(XFile imageFile) async {
    try {
      if (isWeb) {
        // For web, read as bytes
        final bytes = await imageFile.readAsBytes();
        return MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
          contentType: imageFile.mimeType != null
              ? DioMediaType.parse(imageFile.mimeType!)
              : null,
        );
      } else {
        // For mobile, use file path
        return await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
          contentType: imageFile.mimeType != null
              ? DioMediaType.parse(imageFile.mimeType!)
              : null,
        );
      }
    } catch (e) {
      throw Exception('Failed to create multipart file: $e');
    }
  }

  /// Get file size in a cross-platform way
  static Future<int> getFileSize(XFile imageFile) async {
    try {
      return await imageFile.length();
    } catch (e) {
      throw Exception('Failed to get file size: $e');
    }
  }

  /// Get file bytes in a cross-platform way
  static Future<Uint8List> getFileBytes(XFile imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read file bytes: $e');
    }
  }

  /// Get a platform-specific error message for file operations
  static String getPlatformSpecificErrorMessage(
    String operation,
    dynamic error,
  ) {
    if (isWeb) {
      return 'Web error during $operation: ${error.toString()}. '
          'Please try selecting the image again or use a different browser.';
    } else {
      return 'Mobile error during $operation: ${error.toString()}. '
          'Please check file permissions and try again.';
    }
  }

  /// Check if the platform supports file system operations
  static bool get supportsFileSystemOperations => !isWeb;

  /// Get a safe file name for the platform
  static String getSafeFileName(XFile imageFile) {
    try {
      final name = imageFile.name;
      if (name.isNotEmpty) {
        return name;
      }

      // Fallback: extract from path
      final pathSegments = imageFile.path.split('/');
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }

      // Final fallback: generate a name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.mimeType?.split('/').last ?? 'jpg';
      return 'prescription_$timestamp.$extension';
    } catch (e) {
      // Emergency fallback
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'prescription_$timestamp.jpg';
    }
  }

  /// Get safe PDF file name
  static String getSafePdfFileName(int prescriptionId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'prescription_${prescriptionId}_$timestamp.pdf';
  }

  /// Validate PDF data
  static String? validatePdfData(Uint8List pdfBytes) {
    try {
      // Check if data is empty
      if (pdfBytes.isEmpty) {
        return 'PDF data is empty';
      }

      // Check minimum PDF size (should be at least a few hundred bytes)
      if (pdfBytes.length < 100) {
        return 'PDF data is too small to be valid';
      }

      // Check PDF magic number (PDF files start with %PDF-)
      final header = String.fromCharCodes(pdfBytes.take(5));
      if (header != '%PDF-') {
        return 'Invalid PDF format';
      }

      return null; // Valid PDF
    } catch (e) {
      return 'Error validating PDF: $e';
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}

/// Extension for DioMediaType to handle null safety
extension DioMediaTypeHelper on DioMediaType {
  static DioMediaType? parse(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return null;

    try {
      final parts = mimeType.split('/');
      if (parts.length == 2) {
        return DioMediaType(parts[0], parts[1]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
