import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/controllers/home_controller.dart';
import 'app_paths.dart';

class RouteFollowRewordDialog extends StatelessWidget {
  const RouteFollowRewordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return  Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding:const EdgeInsets.all(15),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow:  [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 2.5,spreadRadius: 3.2
                )
              ]

          ),
          child:   Column( children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CircleAvatar(radius: 18,backgroundColor: Colors.transparent,),
                myText(title:'Reward',fontWeight: FontWeight.bold,fontSize: 15),

                InkWell(
                  onTap: (){
                    if( Get.find<HomeController>().isFixed.value){
                      Get.find<HomeController>().previewCamera(4);
                      Get.back();
                    }else{
                      Get.back();
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade400,
                    child: const Icon(Icons.clear,color: Colors.white,size: 20,),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8,),
            Image.asset('assets/constructionIMG.jpeg',height: 200,width: 200,),
            const SizedBox(height: 8,),
            myText(title:"Hey! you just followed the crossing safety sign. You have Earned 5 points.",fontWeight: FontWeight.w500,fontSize: 14),
            const SizedBox(height: 5,)
          ],),
        )
      ],
    );
  }
}
