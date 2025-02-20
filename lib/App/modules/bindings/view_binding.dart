import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/splash_controller.dart';


class HomeBinding extends Bindings{
  @override
  void dependencies()=>Get.put<HomeController>(HomeController());
}
class SplashBinding extends Bindings{
  @override
  void dependencies()=>Get.put<SplashController>(SplashController());
}