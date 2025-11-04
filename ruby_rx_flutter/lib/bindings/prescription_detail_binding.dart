import 'package:get/get.dart';
import '../controllers/prescription_detail_controller.dart';
import '../services/prescription_manager_service.dart';

class PrescriptionDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize the prescription manager service if not already initialized
    if (!Get.isRegistered<PrescriptionManagerService>()) {
      Get.put<PrescriptionManagerService>(PrescriptionManagerService());
    }

    // Initialize the detail controller
    Get.lazyPut<PrescriptionDetailController>(
      () => PrescriptionDetailController(),
    );
  }
}
