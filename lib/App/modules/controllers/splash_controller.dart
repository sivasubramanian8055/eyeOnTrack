import 'package:get/get.dart';

import '../../data/auth_data.dart';
import '../../routes/app_pages.dart';

class SplashController extends GetxController {
  //TODO: Implement SplashController

  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
    initiateApp();
  }

  void initiateApp() {
    Future.delayed(const Duration(seconds: 2), () {
      getuserLoginModel().then((value) {
        if (value != null) {
          userLoginModel = value;
          Get.toNamed(Routes.HOME);
        } else {
          Get.toNamed(Routes.LOGIN);
        }
      });
    });
  }
  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}
