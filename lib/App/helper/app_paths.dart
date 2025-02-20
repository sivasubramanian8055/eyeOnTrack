import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:crypoexchange/App/models/near_places_model.dart';
import 'package:crypoexchange/App/modules/controllers/home_controller.dart';
import 'package:crypoexchange/app_controller.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'app_strings.dart';
import 'package:http/http.dart' as http;

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

const apiKey = 'AIzaSyCy6TbAdJKairdnqz6Wvh3qcv1rypGW-Wo';
LatLng startLatLong = const LatLng(44.63747499999999,
    -63.5872374); //6050 University Ave, Halifax, NS B3H 1W5, Canada
LatLng endLatLong = const LatLng(
    44.6484525, -63.5761469); //1800 Argyle St, Halifax, NS B3J 2V9, Canada
// nearest place = 44.63766620858004, -63.58561982657208
// near place = 44.66045208014445, -63.64652753788306
// near place = 44.638104, -63.585499 University Ave

Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
      .buffer
      .asUint8List();
}

// !DECODE POLY
List decodePoly(String poly) {
  var list = poly.codeUnits;
  var lList = [];
  int index = 0;
  int len = poly.length;
  int c = 0;
  // repeating until all attributes are decoded
  do {
    var shift = 0;
    int result = 0;

    // for decoding value of one attribute
    do {
      c = list[index] - 63;
      result |= (c & 0x1F) << (shift * 5);
      index++;
      shift++;
    } while (c >= 32);
    /* if value is negative then bitwise not the value */
    if (result & 1 == 1) {
      result = ~result;
    }
    var result1 = (result >> 1) * 0.00001;
    lList.add(result1);
  } while (index < len);

  /*adding to previous value as done in encoding */
  for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

  // print(lList.toString());

  return lList;
}

double calculateDistance(LatLng lng1, LatLng lng2) {
  double lat1 = lng1.latitude;
  double lon1 = lng1.longitude;
  double lat2 = lng2.latitude;
  double lon2 = lng2.longitude;
  double mDist = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  print("DISTENCE_HAI_BHAYA=>${mDist / 1000}");
  return mDist / 1000;
}

double calculateDistance1(LatLng start, LatLng end) {
  const double earthRadius = 6371.0; // Radius of the Earth in kilometers
  // Convet coordinates to radians

  var p =
      0.017453292519943295; //conversion factor from radians to decimal degrees, exactly math.pi/180 - https://gis.stackexchange.com/a/211669
  final double lat1 = start.latitude * p;
  final double lon1 = start.longitude * p;
  final double lat2 = end.latitude * p;
  final double lon2 = end.longitude * p;

  // Calculate the differences between the coordinates
  final double dLat = lat2 - lat1;
  final double dLon = lon2 - lon1;

  // Apply the Haversine formula
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final double distance = earthRadius * c;

  return distance; // Distance in kilometers, add "*1000" to get meters
}

//
// const request = {
//   origins: [origin1, origin2],
//   destinations: [destinationA, destinationB],
//   travelMode: google.maps.TravelMode.DRIVING,
//   unitSystem: google.maps.UnitSystem.METRIC,
//   avoidHighways: false,
//   avoidTolls: false,
// };

Future<dynamic> getDistance(LatLng lng1, LatLng lng2, String movingMode) async {
  print("fdkjdklfgjdfklj${lng2}");
  print("fdkjdklfgfhgghgghghgtgjdfklj${lng1}");
  double startLatitude = lng1.latitude;
  double startLongitude = lng1.longitude;
  double endLatitude = lng2.latitude;
  double endLongitude = lng2.longitude;
  String Url2 =
      'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${startLatitude},'
      '${startLongitude}&destinations=${endLatitude},${endLongitude}&mode=$movingMode&language=en-US&key=$apiKey';
  print("url_for_distence_and_time=$Url2");
  try {
    var response = await http.get(Uri.parse(Url2));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data;
    } else {
      return null;
    }
  } catch (e) {
    print(e);
    return null;
  }
}

List testingInstructionList = [];

Future<dynamic> getDistanceUsingDirections(
    List<LatLng> polylinePoints, String movingMode) async {
  testingInstructionList.clear();
  const int maxWaypoints = 25;
  num totalDistanceValue = 0;
  num totalDurationValue = 0;
  List _instructionList = [];
  String startImageUrl = '';
  var totalDistance = '';
  var totalDuration = '';

  HomeController hController = Get.find<HomeController>();
  AppController appController = Get.find<AppController>();

  LatLng currentLocation = LatLng(
      appController.currentPosition.value?.latitude ?? 0.0,
      appController.currentPosition.value?.longitude ?? 0.0);
  LatLng pickUpLocation = LatLng(
      hController.pickUpLatLng.value?.latitude ?? 0.0,
      hController.pickUpLatLng.value?.longitude ?? 0.0);

  LatLng startLocation =
      hController.pickUpLatLng.value == null ? currentLocation : pickUpLocation;
  LatLng? endLocation =
      hController.isFixed.value ? endLatLong : hController.destLatLng.value;

  // Check if the total distance is less than a certain threshold (e.g., 1 km)
  double totalDistanceInKm = calculateDistance(startLocation, endLocation!);

  List<List<LatLng>> waypointChunks = [];
  bool notSendWp = false;

  if (totalDistanceInKm < 1) {
    // EasyLoading.showToast('1111111111111111111111111');
    notSendWp = true;
    waypointChunks.clear();
    // For very short distances, only add a single chunk with start and end
    waypointChunks.add([startLocation, endLocation]);
  } else {
    // Split polylinePoints into chunks if necessary
    for (int i = 0; i < polylinePoints.length; i += maxWaypoints) {
      waypointChunks.add(polylinePoints.sublist(
          i,
          i + maxWaypoints > polylinePoints.length
              ? polylinePoints.length
              : i + maxWaypoints));
    }
  }

  DateTime now = DateTime.now();
  int timestamp = now.millisecondsSinceEpoch ~/ 1000;

  try {
    print("fkgjdflkgjlfk${waypointChunks}");
    for (List<LatLng> chunk in waypointChunks) {
      String waypoints = chunk
          .map((point) => '${point.latitude},${point.longitude}')
          .join('|');
      print("fkgjdflkgaaaaajlfk${waypoints}");

      String url =
          Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': '${startLocation.latitude},${startLocation.longitude}',
        'destination': '${endLocation.latitude},${endLocation.longitude}',
        'mode': movingMode,
        'language': 'en-US',
        'waypoints': notSendWp ? '' : waypoints,
        'departure_time': timestamp.toString(),
        'key': apiKey,
      }).toString();

      print("MY_POLYLINE_RESPONSE_URLS=>$url");

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var route = data['routes'][0];
        var leg = route['legs'][0];

        testingInstructionList.addAll(leg['steps']);

        _instructionList = route['legs'];
        startImageUrl = await _getPlaceImageUrl(
            startLocation.latitude, startLocation.longitude);
        totalDistanceValue += leg['distance']['value'];
        totalDurationValue += leg['duration']['value'];
        totalDistance = leg['distance']['text'];
        totalDuration = leg['duration']['text'];
        print("INSTRUCTION_LIST_LENGTH => ${testingInstructionList.length}");
      } else {
        return null;
      }
    }
  } catch (e) {
    print(e);
    return null;
  }

  return {
    'distance': {'text': totalDistance, 'value': totalDistanceValue},
    'duration': {'text': totalDuration, 'value': totalDurationValue},
    'steps': _instructionList,
  };
}

// Utility to format distance
String _formatDistance(num distance) {
  if (distance < 1000) {
    return '${distance.toStringAsFixed(0)} m';
  } else {
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }
}

// Utility to format duration
String _formatDuration(num duration) {
  if (duration < 60) {
    return '${duration.toStringAsFixed(0)} sec';
  } else if (duration < 3600) {
    return '${(duration / 60).toStringAsFixed(0)} min';
  } else {
    return '${(duration / 3600).toStringAsFixed(1)} hours';
  }
}

// Function to get a place image URL using Google Places API
Future<String> _getPlaceImageUrl(double latitude, double longitude) async {
  String placeId = await _getPlaceId(
      latitude, longitude); // Get place ID from latitude and longitude
  if (placeId.isNotEmpty) {
    String url =
        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$placeId&key=$apiKey';
    return url;
  }
  return '';
}

// Function to get the place ID from latitude and longitude
Future<String> _getPlaceId(double latitude, double longitude) async {
  String url =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=500&key=$apiKey';
  var response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (data['results'].isNotEmpty) {
      return data['results'][0]['photos'][0]['photo_reference'];
    }
  }
  return '';
}

bool onLine(LatLng A, LatLng B, LatLng C) {
  double m1 = (C.latitude - A.latitude) / (C.longitude - A.longitude);
  double m2 = (C.latitude - B.latitude) / (C.longitude - B.longitude);
  return m1 == m2;
}

List<LatLng> convertStepsToLatLng(List points) {
  List<LatLng> result = <LatLng>[];
  for (int i = 0; i < points.length; i++) {
    if (i % 2 != 0) {
      double lat = points[i - 1];
      double lon = points[i];
      result.add(LatLng(lat, lon));
    }
  }
  return result;
}

getIconFromString(String type) {
  switch (type) {
    case 'OTHER':
      return Pointers.OTHER; //icVehicleRepair.value;
    case 'VEHICLEREPAIR':
      return Pointers.VEHICLEREPAIR;
    case 'ACCIDENT':
      return Pointers.ACCIDENT;
    case 'CONSTRUCTION':
      return Pointers.CONSTRUCTION;
    case 'FARTCONTROL':
      return Pointers.HOSPITAL;
    case 'HOSPITAL':
      return Pointers.PARK;
    case 'PARK':
      return Pointers.FARTCONTROL;
    case 'DESTINATION':
      return Pointers.DESTINATION;
    case 'STARTLOCATION':
      return Pointers.STARTLOCATION;
    default:
      return Pointers.OTHER;
  }
}

getIconView(String type) {
  switch (type) {
    case 'OTHER':
      return 'menu_hz';
    case 'HOSPITAL':
      return 'hospital';
    case 'PARK':
      return 'park';
    case 'ACCIDENT':
      return 'accident';
    case 'CONSTRUCTION':
      return 'obstacle';
    case 'VEHICLEREPAIR':
      return 'service';
    case 'FARTCONTROL':
      return 'camera';
    default:
      return 'service';
  }
}

Text myText(
    {required String title,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight}) {
  return Text(
    title,
    style: GoogleFonts.inter(
        textStyle: TextStyle(
            color: color, fontSize: fontSize, fontWeight: fontWeight)),
  );
}

ElevatedButton myButton(
    {required void Function()? onPressed,
    required Widget? child,
    Color? color,
    EdgeInsets? padding,
    double? radius}) {
  return ElevatedButton(
    onPressed: onPressed,
    child: child,
    style: ButtonStyle(
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          padding ?? const EdgeInsets.all(10.0)),
      backgroundColor: WidgetStateProperty.all(color),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? 20),
        ),
      ),
    ),
  );
}

String _key = 'AIzaSyCy6TbAdJKairdnqz6Wvh3qcv1rypGW-Wo';

InputDecoration placeInputDecoration(
        {required String hintText, Color? hintTextColor}) =>
    InputDecoration(
      contentPadding: const EdgeInsets.only(left: 10, top: 15, right: 10),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
          color: hintTextColor ?? Colors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w500),
    );

class ImageView extends StatelessWidget {
  final String photoUrl;
  final Alignment? alignment;
  final BoxFit boxFit;
  const ImageView(
      {Key? key,
      required this.photoUrl,
      this.alignment,
      this.boxFit = BoxFit.fill})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FancyShimmerImage(
      alignment: alignment,
      imageUrl: photoUrl,
      boxFit: boxFit,
      shimmerBaseColor: Colors.black.withOpacity(0.2),
      shimmerHighlightColor: Colors.black.withOpacity(0.5),
      shimmerBackColor: Colors.black.withOpacity(0.7),
      errorWidget: const Icon(Icons.error_outlined, color: Colors.red),
    );
  }
}

Future<ApiManager> nearPlaceApi({required LatLng position}) async {
  final String url =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=1500&type=restaurant&key=$_key';
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("NEAR_PLACES_ALL_DATA=>${data['results']}");
      NearPlaceModel myModel = nearPlaceModelFromJson(response.body);
      return ApiManager(
          status: true, message: response.statusCode.toString(), data: myModel);
    } else {
      return ApiManager(status: false, message: response.statusCode.toString());
    }
  } catch (e) {
    return ApiManager(status: false, message: e.toString());
  }
}

class ApiManager {
  bool status;
  String message;
  dynamic data;
  ApiManager({required this.status, required this.message, this.data});
}
