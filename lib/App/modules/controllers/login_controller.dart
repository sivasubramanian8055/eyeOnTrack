import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../data/auth_data.dart';
import '../../models/user_model.dart';
import '../../routes/app_pages.dart';

class LoginController extends GetxController{
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController mobileController = TextEditingController();
TextEditingController passController = TextEditingController();
  dynamic time = DateTime.now().millisecondsSinceEpoch.toString();


   Future<bool> userExists(String id) async {
    return( await firestore.collection('users').doc(id).get()).exists;
  }


     Future<DocumentSnapshot<Map<String, dynamic>>> userExistsData(String id) async {
    return await firestore.collection('users').doc(id).get();
  }


  Future<AuthUserModel?> createUserOnFireBase() async {
    try {
      var mUser = AuthUserModel(mobileNumber:  mobileController.text.toString().trim(), id:  mobileController.text.toString().trim(), time: time.toString(), loginType: 'auth');
      await firestore.collection('users').doc(mobileController.text.toString().trim()).set(mUser.toJson());
      print("User created successfully.");
      return mUser;
    } catch (e) {
      print("Error creating user: $e");
      return null;
    }
  }



  initiateLogin() async {
    if(mobileController.text.isEmpty){
      EasyLoading.showToast("Please Enter Mobile Number");
    }else{
      if (await userExists(mobileController.text.toString().trim())){
        EasyLoading.show();
        var documentSnapshot = await userExistsData(mobileController.text.toString().trim());
        Map<String, dynamic>? userData = documentSnapshot.data();
        AuthUserModel myModel =  AuthUserModel.fromJson(userData!);
        setuserLoginModel(myModel).whenComplete((){
          getuserLoginModel().then((onValue){
            userLoginModel = onValue;
            mobileController.clear();
            passController.clear();
            EasyLoading.dismiss();
            EasyLoading.showToast('Login Success');
            Get.toNamed(Routes.HOME);
          });
        });
      }else{
        EasyLoading.show();
        createUserOnFireBase().then((data){
          if(data!=null){
            setuserLoginModel(data).whenComplete((){
              getuserLoginModel().then((onValue){
                userLoginModel = onValue;
                mobileController.clear();
                passController.clear();
                EasyLoading.dismiss();
                EasyLoading.showToast('Register Success');
                Get.toNamed(Routes.HOME);
              });
            });
          }else{
            EasyLoading.dismiss();
            EasyLoading.showToast('Something vent wong');
          }
        });

      }
    }

  }




  initiateGuestLogin(){
    EasyLoading.show();
    Future.delayed(const Duration(seconds: 2),(){
      AuthUserModel myModel = AuthUserModel(mobileNumber:  '00000000', id:  '0000000000', time: time.toString(), loginType: 'guest');
      setuserLoginModel(myModel).whenComplete((){
        getuserLoginModel().then((onValue){
          userLoginModel = onValue;
          mobileController.clear();
          passController.clear();
          EasyLoading.dismiss();
          Get.toNamed(Routes.HOME);
        });
      });
    });
  }



}


class LoginBinding extends Bindings{


  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.put<LoginController>(LoginController());
  }

}