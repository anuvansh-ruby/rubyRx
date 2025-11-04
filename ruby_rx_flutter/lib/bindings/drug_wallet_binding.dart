import 'package:get/get.dart';
import '../controllers/drug_wallet_controller.dart';
import '../services/drug_wallet_service.dart';

/// Drug Wallet Binding
/// Initializes dependencies for the drug wallet feature
class DrugWalletBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize service first
    Get.lazyPut<DrugWalletService>(() => DrugWalletService());

    // Initialize controller
    Get.lazyPut<DrugWalletController>(() => DrugWalletController());
  }
}
