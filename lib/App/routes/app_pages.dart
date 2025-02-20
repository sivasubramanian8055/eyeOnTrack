import 'package:crypoexchange/App/modules/controllers/login_controller.dart';
import 'package:get/get.dart';
import '../modules/bindings/view_binding.dart';
import '../modules/views/home_view.dart';
import '../modules/views/login_view.dart';
import '../modules/views/splash_view.dart';
part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () =>  HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),

  ];
}


