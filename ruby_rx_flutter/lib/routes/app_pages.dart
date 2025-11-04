import 'package:get/get.dart';
import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/tutorial_binding.dart';
import '../bindings/prescription_binding.dart';
import '../bindings/manual_entry_binding.dart';
import '../bindings/drug_wallet_binding.dart';
import '../views/splash_view.dart';
import '../views/tutorial_view.dart';
import '../views/login_view.dart';
import '../views/otp_verify_view.dart';
import '../views/register_view.dart';
import '../views/registration_form_view.dart';
import '../views/pin_entry_view.dart';
import '../views/setup_pin_view.dart';
import '../views/forgot_pin_view.dart';
import '../views/home_view.dart';
import '../views/profile_view.dart';
import '../views/personal_info_view.dart';
import '../views/prescription_manager_view.dart';
import '../views/prescription_detail_view.dart';
import '../views/manual_entry_view.dart';
import '../views/drug_wallet_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.tutorial,
      page: () => const TutorialView(),
      binding: TutorialBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.otpVerify,
      page: () => const OtpVerifyView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.registrationForm,
      page: () => const RegistrationFormView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.setupPin,
      page: () => const SetupPinView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.pinEntry,
      page: () => const PinEntryView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.forgotPin,
      page: () => const ForgotPinView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.personalInfo,
      page: () => const PersonalInfoView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.prescriptionManager,
      page: () => const PrescriptionManagerView(),
      binding: PrescriptionBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.prescriptionDetail,
      page: () => const PrescriptionDetailView(),
      binding: PrescriptionBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.manualEntry,
      page: () => const ManualEntryView(),
      binding: ManualEntryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.drugWallet,
      page: () => const DrugWalletView(),
      binding: DrugWalletBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
