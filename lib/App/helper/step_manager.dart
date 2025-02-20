import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'app_paths.dart';

StepDetails countSteps(DirectionsRoute? route, LatLng lng ,int index){
  try{
    List<Step>? steps = route?.legs?.first.steps;
    if(steps!=null){
      Step step = steps.elementAt(index);
      List<LatLng> list = convertStepsToLatLng(decodePoly(step.polyline!.points!));
     // double firstPoint = calculateDistance(list.first, lng);
      double lastPoint = calculateDistance(list.last, lng);
      // print('firstPoint  = $firstPoint,  lastPoint => $lastPoint');
      int mIndex =  index;
      if((lastPoint<=0.1)&&index<(steps.length-1)){
        mIndex = mIndex+1;
        Step mStep = steps.elementAt(mIndex);
        return StepDetails(stepCount: mIndex, lastPoint: list.last, instruction: mStep.instructions??'');
      }else{
        return StepDetails(stepCount: mIndex, lastPoint: list.last);
      }
    }
  }catch(e){
    return StepDetails(stepCount: 0);
  }
  return StepDetails(stepCount: 0);
}

class StepDetails{
  final int stepCount;
  final LatLng? lastPoint;
  final String? instruction;
  StepDetails({required this.stepCount, this.lastPoint, this.instruction,});
}