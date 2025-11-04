import 'package:get/get.dart';
import '../data/services/api_client.dart';
import '../services/prescription_manager_service.dart';
import '../services/prescription_api_service.dart';

/// Bindings for common services used throughout the app
class ServicesBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize ApiClient first as other services depend on it
    Get.put<ApiClient>(ApiClient(), permanent: true);

    // Initialize prescription services
    Get.put<PrescriptionManagerService>(
      PrescriptionManagerService(),
      permanent: true,
    );
    Get.put<PrescriptionApiService>(PrescriptionApiService(), permanent: true);
  }
}
