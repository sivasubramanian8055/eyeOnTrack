import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class MyThemes {
  static final lightTheme = ThemeData(
    scaffoldBackgroundColor:Colors.transparent,
    primaryColor: Colors.cyan,
    appBarTheme:const AppBarTheme(
      backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation:0,
        iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor:  Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      )
    ),
  );
}