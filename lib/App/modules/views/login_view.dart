
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../data/auth_data.dart';
import '../../helper/app_paths.dart';
import '../../helper/app_strings.dart';
import '../../models/user_model.dart';
import '../../routes/app_pages.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        exit(0);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60,),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    AppLogo,
                    fit: BoxFit.cover,
                    height: 150,
                    width: 150,
                  ),
                ),
                const SizedBox(height: 20,),
                myText(
                    title: "LOGIN",
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                   // color: ColorConstants.APPPRIMARYCOLOR
                ),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    emailIDUI(context),
                    // const SizedBox(height: 16),
                    // passWordUI(context),
                    const SizedBox(height: 25),
                    loginButton(),
                    geustLoginBiutton( context),

                  ],
                ).paddingOnly(left: 20, right: 20, top: 10),

              ],
            ).paddingOnly(top: 50),
          )),
    );
  }
loginButton()=>GestureDetector(
  onTap: () =>controller.initiateLogin(),
  child: Center(
    child: Container(
      width: 150,
      padding: const EdgeInsets.symmetric( vertical: 12.0, horizontal: 24.0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2.8,blurRadius: 1.8
            )
          ]
      ),
      child: const Center(
        child: Text(
          'Proceed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ).paddingOnly(top: 20),
);
  geustLoginBiutton(BuildContext context)=>GestureDetector(
    onTap: () =>controller.initiateLogin(),
    child: Center(
      child: Container(
        height: 40,
        width: 120,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2.8,blurRadius: 1.8
              )
            ]
        ),
        child:  Center(
          child: myText(title: 'Guest Login', color: Theme.of(context).primaryColor,fontSize: 12,fontWeight: FontWeight.w600),
        ),
      ),
    ).paddingOnly(top: 20),
  );
  emailIDUI(BuildContext context) => Column(
    children: [
      Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
            controller: controller.mobileController,
            decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(5),
                border: InputBorder.none,
                labelText: "Mobile",
              //  labelStyle:
              //  TextStyle(color: ColorConstants.APPPRIMARYBLACKCOLOR),
                hintText: "Enter Mobile Number",
              //  hintStyle:
              //  TextStyle(color: ColorConstants.APPPRIMARYBLACKCOLOR)),
          ),
        ),
      ),)
    ],
  );
  passWordUI(BuildContext context) => Column(
    children: [
      Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            keyboardType: TextInputType.visiblePassword,
            controller: controller.passController,
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(5),
                labelText: "Password",
              //  labelStyle: TextStyle(color: ColorConstants.APPPRIMARYBLACKCOLOR),
                hintText: "Enter Password",
              //  hintStyle: TextStyle(color: ColorConstants.APPPRIMARYBLACKCOLOR)),
          ),
        ),
      )),
    ],
  );
}

