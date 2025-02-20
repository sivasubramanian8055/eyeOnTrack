import 'package:crypoexchange/App/helper/app_strings.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF6CCFF6), Color(0xFF59CBF7)],
            // stops: [0.7, 0.3],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        ),
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('$APP_NAME', style: GoogleFonts.faunaOne(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ), textAlign: TextAlign.center,),
        ),
      )
    ],);
  }
}
