
import 'dart:ffi';

import 'package:crypoexchange/App/helper/app_paths.dart';
import 'package:crypoexchange/App/modules/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../main.dart';
import '../../data/auth_data.dart';
import '../../helper/route_follow_dialog.dart';


class CameraView extends StatefulWidget {
  final data;
  const CameraView({super.key, this.data});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraController controller;
  HomeController hController = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    })
        .catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            EasyLoading.showToast('Camera Access Denied');
          // Handle access errors here.
            break;
          default:
          // Handle other errors here.
            break;
        }
      }
    });


    Future.delayed(const Duration(seconds: 5),() async {
      if(widget.data!=null){
        Get.dialog(barrierColor: Colors.transparent, const RouteFollowRewordDialog());
        addLeaderBoardReword();
        addDashboardReword(widget.data);
      }
    });
  }

  Future<void> addLeaderBoardReword()async{
    if(await hController.leaderExists(userLoginModel!.id.toString()))
    {
      var data = await hController.firestore.collection('leaderboard').doc(userLoginModel!.id.toString()).get();
      Map<String, dynamic>? leaderData = data.data();
      int points = leaderData?['coin'];
      await hController.firestore.collection('leaderboard').doc(userLoginModel!.id.toString()).update({
        'coin': points+5,
        'time': DateTime.now().toLocal().toString(),
      });
    }
    else{
      var hashMap =   {
        "id":userLoginModel?.id.toString(),
        "title":'Crossing Ahead',
        "locality":widget.data.toString(),
        "time": DateTime.now().toLocal().toString(),
        "coin":5,
      };
      await hController.firestore.collection('leaderboard').doc(userLoginModel?.id.toString()).set(hashMap);
    }

  }

  Future<void> addDashboardReword(data) async {
    dynamic time = DateTime.now().millisecondsSinceEpoch.toString();
    var hashMap =   {
      "id":time,
      "title":'Crossing Ahead',
      "locality":data.toString(),
      "time": DateTime.now().toLocal().toString(),
      "coin":5,
    };
    await hController.firestore
        .collection('users')
        .doc(userLoginModel?.id.toString())
        .collection('reword').doc(time).set(hashMap);
  }



  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container( child:  myText(title: 'Access Denied',color: Colors.white),);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body:  CameraPreview(controller),
    );
  }
  _appBar()=>Positioned(child: AppBar());

}