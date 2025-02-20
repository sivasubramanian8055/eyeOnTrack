
import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));
String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  String userName;
  String mobileNumber;
  String password;

  UserModel({
    required this.mobileNumber,
    required this.password,
    required this.userName,
  });

  // Factory constructor to create an instance from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    mobileNumber: json["number"],
    password: json["password"],
    userName: json["name"],
   // hazardList:json["hazard_list"].map((item) => HazardDatum.fromJson(item)).toList(),
  );

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() => {
    "number": mobileNumber,
    "password": password,
    "name": userName,
  //  "hazard_list": hazardList,
  };
}

// AUTH USER MODEL


AuthUserModel authUserModelFromJson(String str) => AuthUserModel.fromJson(json.decode(str));
String authUserModelToJson(AuthUserModel data) => json.encode(data.toJson());

class AuthUserModel {
  String id;
  String mobileNumber;
  String time;
  String loginType;

  AuthUserModel({
    required this.mobileNumber,
    required this.id,
    required this.loginType,
    required this.time,
  });

  // Factory constructor to create an instance from JSON
  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
    mobileNumber: json["mobile"],
    time: json["time"],
    id: json["id"],
    loginType: json["loginType"],
  );

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() => {
    "mobile": mobileNumber,
    "time": time,
    "id": id,
    "loginType": loginType,
  };
}


////////////////////
HazardDatum hazardDatumModelFromJson(String str) => HazardDatum.fromJson(json.decode(str));
String hazardDatumModelToJson(HazardDatum data) => json.encode(data.toJson());
class HazardDatum {
  String id;
  String description;

  HazardDatum({
    required this.id,
    required this.description,
  });

  factory HazardDatum.fromJson(Map<String, dynamic> json) => HazardDatum(
    id: json["id"],
    description: json["description"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "description": description,
  };
}