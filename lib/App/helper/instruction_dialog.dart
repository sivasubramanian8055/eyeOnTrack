import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import '../modules/controllers/home_controller.dart';
import 'app_paths.dart';

class InstructionDialog extends StatelessWidget {
  final  data;
  const InstructionDialog({super.key, this.data});

  IconData _getIconForInstruction(String instruction) {
    if (instruction.contains('left')) {
      return Icons.turn_left;
    } else if (instruction.contains('right')) {
      return Icons.turn_right;
    } else if (instruction.contains('Roundabout')) {
      return Icons.roundabout_left;
    } else if (instruction.contains('merge')) {
      return Icons.merge;
    } else if (instruction.contains('straight')) {
      return Icons.straight;
    } else if (instruction.contains('U-turn')) {
      return Icons.rotate_left;
    }else if (instruction.contains('Roundabout') || instruction.contains('Enter the roundabout')) {
      return Icons.sync; // Roundabout-like icon
    }  else if (instruction.contains('straight') || instruction.contains('Continue onto')) {
      return Icons.straight; // Continue straight ahead
    }else {
      return Icons.navigation; // Default icon
    }
  }



  @override
  Widget build(BuildContext context) {
    IconData iconData = _getIconForInstruction(data.toString());
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
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
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
              ),
            ),
            Icon(iconData,size: 25,),
            SizedBox(height: 15,),
            HtmlWidget(data.toString()),

            //
            //
            // const SizedBox(height: 8,),
            // Image.asset(/*assetImgUrl(data['title'].toString())*/"assets/alert.png",height: 60,width: 60,),
            // const SizedBox(height: 8,),
            //
            // myText(title: data['locality'].toString(),fontWeight: FontWeight.w500,fontSize: 14),
            // if(data['for_saftey_msm'] !='')
            //   Container(
            //     padding: const EdgeInsets.all(5),
            //     decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(5),
            //         color: Colors.grey.withOpacity(0.1),
            //         border: Border.all(width: 0.8,color: Colors.black.withOpacity(0.3))
            //     ),
            //     child: myText(title: data['for_saftey_msm'].toString(),color: Colors.black,fontSize: 13,fontWeight: FontWeight.w500),
            //
            //   ),


            const SizedBox(height: 5,)
          ],),
        )
      ],
    );
  }
}
