import 'package:crypoexchange/App/modules/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_paths.dart';

class HazardDialog extends StatelessWidget {
  final data;
  const HazardDialog({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 2.5,
                    spreadRadius: 3.2)
              ]),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.transparent,
                  ),
                  myText(
                      title: data['message'].toString(),
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                  InkWell(
                    onTap: () {
                      if (Get.find<HomeController>().isFixed.value) {
                        Get.find<HomeController>().previewCamera(4);
                        Get.back();
                      } else {
                        Get.back();
                      }
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade400,
                      child: const Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              if (data['message'].toString() == 'Construction Work Ahead' ||
                  data['message'].toString() == 'Pedestrian Crossing Ahead')
                Image.asset(
                  'assets/constructionIMG.jpeg',
                  height: 200,
                  width: 200,
                )
              else
                Image.asset(
                  "assets/alert.png",
                  height: 60,
                  width: 60,
                ),
              const SizedBox(
                height: 8,
              ),
              myText(
                  title: data['locality'].toString(),
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
              if (data['for_saftey_msm'] != '')
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey.withOpacity(0.1),
                      border: Border.all(
                          width: 0.8, color: Colors.black.withOpacity(0.3))),
                  child: myText(
                      title: data['for_saftey_msm'].toString(),
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 8),
              // New: Add a row with Redirect and Dismiss buttons.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Get.find<HomeController>().redirectToSafeRoute();
                      Get.back();
                    },
                    child: const Text("Redirect"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text("Dismiss"),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}

String assetImgUrl(String title) {
  switch (title) {
    case 'CONSTRUCTION':
      return 'assets/ic_construction.png';
    case 'ACCIDENT':
      return 'assets/ic_accident.png';
    case 'VEHICLEREPAIR':
      return 'assets/ic_veh_repair.png';
    case 'PARK':
      return 'assets/ic_park.png';
    case 'HOSPITAL':
      return 'assets/ic_hospital.png';
    default:
      return '';
  }
}

class ConstructionFollowHazardRewordDialog extends StatelessWidget {
  final data;
  const ConstructionFollowHazardRewordDialog({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 2.5,
                    spreadRadius: 3.2)
              ]),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HomeController hController = Get.find<HomeController>();
                        Get.back();
                        hController.selectedPolylineInfo.value.clear();
                        hController.destinationDisKM.value = '';
                        hController.walkingTime.value = 'Calculating...';
                        hController.isInitDirectionEnable = true;
                        hController.LiveDistenceTimeData.value = null;
                        hController.notShowConstructionReword.value = true;

                        hController.initDirectionService();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Theme.of(context).primaryColor),
                        child: myText(
                            title: 'Track',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      )),
                  myText(
                      title: 'Reward',
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                  InkWell(
                    onTap: () {
                      if (Get.find<HomeController>().isFixed.value) {
                        Get.find<HomeController>().previewCamera(4);
                        Get.back();
                      } else {
                        Get.back();
                      }
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade400,
                      child: const Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Image.asset(
                /*assetImgUrl(data['title'].toString())*/ "assets/coin.png",
                height: 60,
                width: 60,
              ),
              const SizedBox(
                height: 8,
              ),
              myText(
                  title:
                      "Hey! you just followed the construction safety sign. You have Earned 5 points.",
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
              const SizedBox(
                height: 5,
              )
            ],
          ),
        )
      ],
    );
  }
}
