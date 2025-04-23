import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'App/helper/app_strings.dart';

class AppController extends GetxController {
  final currentPosition = Rxn<Position>();
  final initialLatLon = Rxn<LatLng>();
  final travelZoom = 18.0;
  final normalZoom = 12.0;
  final normalBearing = 0.0;
  final normalTilt = 60.0;

  final soundAlert = true.obs;
  final wakeLock = true.obs;
  final speedAlert = true.obs;
  final radarRadius = 5.0.obs;

  @override
  void onInit() {
    super.onInit();
    _determinePosition().then((value) {
      // log('${value?.latitude}, ${value?.longitude}');
    });
    _getAppSettings();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // await OpenSettings.openLocationSourceSetting();
      // return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    currentPosition.value = await Geolocator.getCurrentPosition();
    // currentLatLng.value = LatLng(currentPosition.value?.latitude??0.0, currentPosition.value?.longitude??0.0);
    listenCurrentValues();
    return currentPosition.value;
  }

  void listenCurrentValues() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((event) {
      currentPosition.value = event;
    });
  }

  _getAppSettings() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    soundAlert.value = preferences.getBool(KEY_SOUND) ?? true;
    // notificationAlert.value = preferences.getBool(KEY_NOTIF)??true;
    speedAlert.value = preferences.getBool(KEY_SPEED) ?? true;
    radarRadius.value = preferences.getDouble(KEY_RADIUS) ?? 3.0;
    wakeLock.value = preferences.getBool(KEY_WAKELOCK) ?? true;

    soundAlert.listen((value) {
      preferences.setBool(KEY_SOUND, value);
    });

    // notificationAlert.listen((value) {
    //   preferences.setBool(KEY_NOTIF, value);
    // });

    wakeLock.listen((value) {
      preferences.setBool(KEY_WAKELOCK, value);

      // Wakelock.toggle(enable: value);
    });

    speedAlert.listen((value) {
      preferences.setBool(KEY_SPEED, value);
    });

    radarRadius.listen((value) {
      preferences.setDouble(KEY_RADIUS, value);
    });
  }

  @override
  void onClose() {
    super.onClose();
  }
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.put<AppController>(AppController());
  }
}
