import 'package:get/get.dart';
import '../controllers/prescription_controller.dart';
import '../controllers/prescription_detail_controller.dart';

class PrescriptionBinding extends Bindings {
  @override
  void dependencies() {
    // Services are already initialized in main.dart via ServicesBinding
    // Just initialize the controllers which will use the existing services
    Get.lazyPut<PrescriptionController>(() => PrescriptionController());
    Get.lazyPut<PrescriptionDetailController>(
      () => PrescriptionDetailController(),
    );
  }
}
