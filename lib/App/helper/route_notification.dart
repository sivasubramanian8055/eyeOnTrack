import 'package:flutter/material.dart';
//  import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import '../modules/controllers/home_controller.dart';

class RouteNotification extends GetView<HomeController> {
  const RouteNotification({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("HTML_CODEC=>${controller.instruction.value}");
    return Obx(() => controller.instruction.value==null?
        controller.isJourneyStarted.value?Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(heroTag: 'cancel_run',onPressed: () => controller.clearRoute(), child: const Icon(Icons.clear),),
            ))
        :const SizedBox()
        :Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          // alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(4, 4))]
      ),
          child: Row(children: [
            // const Icon(Icons.arrow_upward, size: 36, color: Colors.white,),
            const SizedBox(width: 16,),
          //  Expanded(child: Html(data: controller.instruction.value)),
            IconButton(onPressed: (){
              controller.clearRoute();
            }, icon: const Icon((Icons.cancel)))
          ],),
    )
    );
  }
}
