import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';


AuthUserModel? userLoginModel;
List<dynamic> hazardListHistory = [];

Future<bool> setuserLoginModel(AuthUserModel? userLoginModel) async {
  final pref = await SharedPreferences.getInstance();
  String? data = userLoginModel != null ? authUserModelToJson(userLoginModel) : null;
  bool isFirst = await pref.setString('user', data ?? 'logout');
  return isFirst;
}

Future<AuthUserModel?> getuserLoginModel() async {
  final pref = await SharedPreferences.getInstance();
  String? data = pref.getString('user');
  if (data != null && data == 'logout') return null;
  userLoginModel = data != null ? authUserModelFromJson(data) : null;
  return userLoginModel;
}


Future<bool> setuserHazardModelFromPF(List<Map<String,dynamic>>hazardList) async {
  final pref = await SharedPreferences.getInstance();
  String? data = hazardList.isEmpty? null : json.encode(hazardList);
  print("SETHAZARD_LET_DATA=>${data}");
  bool isFirst = await pref.setString('userhazard', data ?? 'logout');
  return isFirst;
}

Future<List<dynamic>?>getuserHazardModel() async {
  final pref = await SharedPreferences.getInstance();
  String? data = pref.getString('userhazard');
  print("KJDJKASDJKDGJSH$data");
  if (data != null && data == 'logout') return null;
  hazardListHistory = json.decode(data!)??[];
   return hazardListHistory;
}

