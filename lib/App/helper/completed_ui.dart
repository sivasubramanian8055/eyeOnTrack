import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/controllers/home_controller.dart';
import 'app_paths.dart';

class CompletedUI extends GetView<HomeController>  {
  const CompletedUI({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isReachedDest.value?SafeArea(
      child: Card(
        margin: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16,),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Your have reached at your destination', style: TextStyle(fontSize: 20), textAlign: TextAlign.center,),
              ),
      
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(color: Colors.green, width: double.infinity, height: 2,),
              ),
      
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(controller.dropController.text, style: const TextStyle(fontSize: 17), textAlign: TextAlign.center,),
              ),
      
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: myButton(
                    onPressed: (){
                    controller.clearRoute();
                  }, child:  myText(title: 'End Now',color: Colors.white,fontSize: 13.5,fontWeight: FontWeight.w500),
                    color: Colors.red,
                    radius: 10
                    
                    ),
                ),
              )
      
            ],),
        ),
      ),
    ):const SizedBox());
  }
}
