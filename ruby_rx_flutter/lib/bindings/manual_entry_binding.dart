import 'package:get/get.dart';
import '../controllers/manual_entry_controller.dart';
import '../services/prescription_api_service.dart';

class ManualEntryBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure API service is available
    Get.put<PrescriptionApiService>(PrescriptionApiService());

    // Create manual entry controller
    Get.put<ManualEntryController>(ManualEntryController());
  }
}
