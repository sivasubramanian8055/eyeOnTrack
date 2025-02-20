import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'App/helper/app_paths.dart';
import 'App/helper/app_strings.dart';
import 'App/routes/app_pages.dart';
import 'app_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'app_theme.dart';
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: APP_NAME,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: MyThemes.lightTheme,
      initialBinding: AppBinding(),
      builder: EasyLoading.init(),
    );
  }
}
