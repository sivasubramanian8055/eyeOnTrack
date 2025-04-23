import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:cloud_firestore_platform_interface/src/geo_point.dart';
import 'package:crypoexchange/App/modules/views/camera_view.dart';
import 'package:crypoexchange/App/modules/views/journey_history_view.dart';
import 'package:crypoexchange/App/modules/views/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:flutter_tts/flutter_tts.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_places_flutter/model/place_details.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location_geocoder/location_geocoder.dart' as loc;
import 'package:material_speed_dial/material_speed_dial.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../app_controller.dart';
import '../../data/auth_data.dart';
import '../../helper/app_paths.dart';
import '../../helper/app_strings.dart';
import '../../helper/hazard_dialog.dart';
import '../../helper/instruction_dialog.dart';
import '../../helper/route_follow_dialog.dart';
import '../../helper/step_manager.dart';
import '../../models/common_model.dart';
import '../../models/near_places_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeController extends GetxController {
  // Remove dialogCameraApproved and add checkAwareness instead.
  // This value should be loaded from Firestore preferences.
  RxBool checkAwareness = false.obs;
  RxBool notifyRewards = false.obs;
  Rxn LiveDistenceTimeData = Rxn();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  dynamic
      overpassData; // to store the parsed Overpass API response once fetched
  List<LatLng> crossingsAlongRoute = [];

  final isFixed = false.obs;
  final notShowConstructionReword = false.obs;
  initFromLoad() {
    Future.delayed(const Duration(seconds: 3), () {
      isJourneyStarted.value = true;
      pickUpLatLng.value = startLatLong;
      destLatLng.value = endLatLong; // main line hai
      previewCamera(4);
      pickupController.text =
          'Goldberg Computer Science Building, 6050 University Ave, Halifax, NS B3H 1W5, Canada';
      dropController.text =
          'Scotiabank Centre, 1800 Argyle St, Halifax, NS B3J 2V9, Canada';
      _updateNavigation();
      EasyLoading.dismiss();
    });
  }

  final isCurrentInstructionIndex = 0.obs;

  gethazard() {
    getuserHazardModel().then((onValue) {
      if (onValue!.isNotEmpty) {
        hazardListHistory = onValue;
        print("SAVED_HAZARD_HISTORY_LIST=>${hazardListHistory}");
      }
    });
  }

  bool _overpassCalled = false;

  // Pedometer fields
  late StreamSubscription<StepCount> _pedometerSubscription;
  final RxInt stepCount = 0.obs; // Holds the current step count.
  int journeyStartStepCount = 0; // Recorded when a journey starts.

  // Add a reactive list to record the journey path.
  RxList<LatLng> recordedJourney = <LatLng>[].obs;

  // Add new reactive DateTime variables to store journey start and end times.
  Rxn<DateTime> journeyStartTime = Rxn<DateTime>();
  Rxn<DateTime> journeyEndTime = Rxn<DateTime>();

  // NEW: To prevent multiple triggers for the same crossing
  LatLng? lastTriggeredCrossing;

  // This method initializes the pedometer subscription.
  void initializePedometer() async {
    bool granted = await _checkActivityRecognitionPermission();
    if (!granted) {
      print(
          "Activity recognition permission not granted. Pedometer will not work.");
      return;
    }
    print("Initializing pedometer...");
    _pedometerSubscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        // Update the reactive step count.
        stepCount.value = event.steps;
        print("Step Count Event Received: ${event.steps}");
      },
      onError: (error) {
        print("Pedometer Error: $error");
      },
    );
  }

  Future<bool> _checkActivityRecognitionPermission() async {
    bool granted = await Permission.activityRecognition.isGranted;
    if (!granted) {
      granted = (await Permission.activityRecognition.request()) ==
          PermissionStatus.granted;
    }
    return granted;
  }

  Future<bool> _checkNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    } else {
      // Request permission.
      PermissionStatus status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        // Optionally inform the user and offer to open app settings.
        Get.snackbar(
          "Permission Required",
          "Please enable notification permissions in settings to receive rewards notifications.",
          snackPosition: SnackPosition.BOTTOM,
        );
        openAppSettings();
        return false;
      }
      return true;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Load the stored user preferences (including checkAwareness) from Firestore.
    _loadUserPreferences();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    // Initialize pedometer early
    initializePedometer();
    gethazard();
    geo = const GeoFirePoint(GeoPoint(0.0, 0.0));
    topPosition.value = -500;
    initializeIcons();
    appController.currentPosition.listen((position) async {
      _updateNavigation();
      LatLng curP =
          LatLng(position?.latitude ?? 0.0, position?.longitude ?? 0.0);

      // Trigger fetchOverpassData only once when current position is available
      if (!_overpassCalled && position != null) {
        _overpassCalled = true;
        fetchOverpassData();
      }
      // Moving Time And Distence
      if (isJourneyStarted.value) {
        recordedJourneyMode.value = isSelectedGoTo.value;
        var data = await getDistance(curP, destLatLng.value!,
            isSelectedGoTo.value == 0 ? 'driving' : 'walking');
        if (data != null && data['status'].toString() == 'OK') {
          List rowDat = data['rows'];
          List elementDat = rowDat.first['elements'];
          LiveDistenceTimeData.value = elementDat.first;
          print("Get_LIVE_DISTENE${LiveDistenceTimeData.value}");
        }
      }
      print("SELECTED_ROUTES=>${selectedRoute.value}");
      if (selectedRoute.value != null) {
        double minVal = double.maxFinite;
        int mIndex = 0;
        int index = 0;

        selectedRoute.value!.path.forEach((element) {
          index++;
          double mDist = calculateDistance(curP, element);
          if (minVal > mDist) {
            minVal = mDist;
            mIndex = index;
          }
        });

        const double deviationThreshold = 0.10; // in meters

        if (minVal > deviationThreshold) {
          print("in");
          // User is off the calculated path.
          if (isJourneyStarted.value) {
            print(
                "User has deviated from the polyline, recalculating shortest route from current location...");

            // Clear previous polylines
            ployLines.clear();

            // Use current position as the new origin
            LatLng currentLocation = curP;
            LatLng destination = selectedRoute.value!.path.last;

            // Request a new route from current location to destination
            final request = DirectionsRequest(
              origin:
                  "${currentLocation.latitude},${currentLocation.longitude}",
              destination: "${destination.latitude},${destination.longitude}",
              alternatives: false, // choose the shortest route
              travelMode: isSelectedGoTo.value == 0
                  ? TravelMode.driving
                  : TravelMode.walking,
              unitSystem: UnitSystem.imperial,
            );
            directionsService.route(request,
                (DirectionsResult response, DirectionsStatus? status) async {
              if (status == DirectionsStatus.ok &&
                  response.routes != null &&
                  response.routes!.isNotEmpty) {
                // Use the first (shortest) route from the response
                DirectionsRoute newRoute = response.routes!.first;
                List<LatLng> newRoutePoints = convertToLatLng(
                    newRoute, decodePoly(newRoute.overviewPolyline!.points!));

                // Add the new route polyline to the map
                addPolyLines(newRoutePoints, 0,
                    movingMode:
                        isSelectedGoTo.value == 0 ? 'driving' : 'walking');
                if (isSelectedGoTo.value != 0) {
                  extractCrossingsAlongRoute();
                }
                // Recalculate and update distance, time, and step instructions
                var distanceTimeInfo = await getDistanceUsingDirections(
                  newRoutePoints,
                  isSelectedGoTo.value == 0 ? 'driving' : 'walking',
                );
                if (distanceTimeInfo != null) {
                  polylineInfo[PolylineId('polyline:0')] = distanceTimeInfo;
                  selectedPolylineInfo.addAll({
                    "Distance": "${distanceTimeInfo['distance']['text']}",
                    "Time": "${distanceTimeInfo['duration']['text']}",
                    "Instructions": distanceTimeInfo['steps']
                  });
                  print(
                      "UPDATED_POLYLINE_INFO => ${selectedPolylineInfo.value}");
                }
              } else {
                print("Error generating new route: $status");
              }
            });
          }
        } else {
          // The user is following the calculated path; update the current instruction index.
          List instructions = selectedPolylineInfo.value['Instructions'];
          List steps = instructions.first['steps'];
          double minDistToInstruction = double.maxFinite;
          int currentInstructionIndex = -1;

          for (int i = 0; i < steps.length; i++) {
            LatLng stepLocation = LatLng(
              steps[i]['end_location']['lat'],
              steps[i]['end_location']['lng'],
            );
            double distanceToInstruction =
                calculateDistance(curP, stepLocation);
            if (distanceToInstruction < minDistToInstruction) {
              minDistToInstruction = distanceToInstruction;
              currentInstructionIndex = i;
            }
          }
          isCurrentInstructionIndex.value = currentInstructionIndex;
        }
      }
      if (isJourneyStarted.value) {
        recordedJourney.add(curP);
      }
    });

    isJourneyStarted.listen((val) {
      if (!val) {
        instruction.value = null;
        destLatLng.value = null;
        // markers.clear();
        ployLines.clear();
        currentIndex = 0;
      } else {
        //?
        //startSimulation();
      }
    });
    showNotification.listen((val) {
      topPosition.value = val ? 100 : -500;
      if (!val) {
        String geoHash =
            hInfoPoint.value?.hazardPoint['position']['geohash'] ?? '';
        notificationStatus[geoHash] = false;
      }
    });

    destLatLng.listen((dest) {
      if (dest == null) return;
      isMapInitialized.value = false;
      EasyLoading.show();
      selectedStep = 0;
      markers.clear();
      LatLng latLngCurrent = LatLng(
          appController.currentPosition.value?.latitude ?? 0.0,
          appController.currentPosition.value?.longitude ?? 0.0);
      double distance = calculateDistance(latLngCurrent, dest);
      radius = BehaviorSubject<double>.seeded(distance);
      _readAllMarkers();
      final id = MarkerId(Pointers.DESTINATION.toString());
      String title = dropController.text.split(',').first;
      // THIS IS DESTINATION MARKER

      markers[id] = Marker(
        markerId: id,
        position: dest,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: title,
          snippet: dropController.text,
        ),
      );
      // Trigger getDistanceUsingDirections for the selected route
      if (selectedRoute.value != null && selectedRoute.value!.path.isNotEmpty) {
        String mode = isSelectedGoTo.value == 0 ? 'driving' : 'walking';
        getDistanceUsingDirections(selectedRoute.value!.path, mode)
            .then((info) {
          if (info != null) {
            polylineInfo[PolylineId('polyline:0')] = info;
            selectedPolylineInfo.value = {
              "Distance": "${info['distance']['text']}",
              "Time": "${info['duration']['text']}",
              "Instructions": info['steps']
            };
            // Immediately show the instructions
            _showDistanceTimeInfo(PolylineId('polyline:0'));
          }
          EasyLoading.dismiss();
        });
      } else {
        EasyLoading.dismiss();
      }
      //  _getNearbyPlaces();
    });
    pickUpLiner();
  }

  Polyline createRoutePolyline(List<LatLng> points, int index,
      {bool isSelected = false, String movingMode = 'driving'}) {
    PolylineId polylineId = PolylineId('polyline:$index');
    Color polyColor = isSelected
        ? Colors.blueAccent
        : const Color.fromARGB(255, 97, 98, 101).withOpacity(0.4);
    return Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      visible: true,
      endCap: Cap.roundCap,
      jointType: JointType.mitered,
      width: 10,
      geodesic: true,
      points: points,
      patterns: isSelectedGoTo.value == 0
          ? []
          : [PatternItem.dot, PatternItem.gap(10)],
      zIndex: index,
      color: polyColor,
      onTap: () async {
        if (!isJourneyStarted.value) {
          selectedRoute.value = listRouteSummery[index];
          updateRoutePolylines();
          // Try to get polyline info. If not available, wait for its retrieval.
          var info = polylineInfo[polylineId];
          print("POLYLINE_ID=>$polylineId");
          if (info == null) {
            info = await getDistanceUsingDirections(points, movingMode);
            if (info != null) {
              polylineInfo[polylineId] = info;
            }
          }
          if (info != null) {
            selectedPolylineInfo.value = {
              "Distance": "${info['distance']['text']}",
              "Time": "${info['duration']['text']}",
              "Instructions": info['steps']
            };
          }
        }
        _showDistanceTimeInfo(polylineId);
      },
    );
  }

  // New function to load the checkAwareness preference from Firestore.
  Future<void> _loadUserPreferences() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userLoginModel!.id)
          .get();
      if (docSnapshot.exists) {
        final Map<String, dynamic>? prefs =
            (docSnapshot.data() ?? {})['preferences'] as Map<String, dynamic>?;
        if (prefs != null) {
          checkAwareness.value = prefs['checkAwareness'] ?? false;
          notifyRewards.value = prefs['notifyRewards'] ?? false;
        }
      }
    } catch (e) {
      debugPrint("Error loading user preferences: $e");
    }
    if (notifyRewards.value) {
      bool granted = await _checkNotificationPermission();
      if (!granted) {
        // If permission is not granted, you might want to prompt the user here.
        // For example, show a snackbar (already done inside _checkNotificationPermission) or log the issue.
        debugPrint("Notification permission was not granted.");
      } else {
        debugPrint("Notification permission granted.");
      }
    }
  }

  @override
  void onClose() {
    _pedometerSubscription.cancel();
    pickupFocus.dispose();
    dropFocus.dispose();
    super.onClose();
    super.onClose();
  }

  pickUpLiner() {
    pickUpLatLng.listen((pick) {
      if (pick == null) return;
      if (destLatLng.value == null) return;
      isMapInitialized.value = false;
      EasyLoading.show();
      selectedStep = 0;
      markers.clear();
      LatLng latLngPickLocation =
          LatLng(pick.latitude ?? 0.0, pick.longitude ?? 0.0);
      LatLng latLngDropLocation = LatLng(destLatLng.value!.latitude ?? 0.0,
          destLatLng.value!.longitude ?? 0.0);
      double distance =
          calculateDistance(latLngPickLocation, latLngDropLocation);
      print("HAZARD_sHowing_Radius=>$distance");
      radius = BehaviorSubject<double>.seeded(distance);
      _readAllMarkers();
      final id = MarkerId(Pointers.DESTINATION.toString());
      final pickId = MarkerId('STARTLOCATION');
      String title = dropController.text.split(',').first;
      // THIS IS DESTINATION MARKER
      markers[id] = Marker(
        markerId: id,
        position: latLngDropLocation,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: title,
          snippet: dropController.text,
        ),
      );
    });
    configureTts();
  }

  FlutterTts flutterTts = FlutterTts();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  double minDistance = double.infinity;
  double minDistance1 = double.infinity;
  final hazardDistance = '0.0'.obs;
  double minRadarRadius = -1.1;
  double measureDistance = double.maxFinite;
  final hInfoPoint = Rxn<HazardSorted>();
  final showNotification = false.obs;
  final instruction = Rxn<String>();
  final isJourneyStarted = false.obs;
  final isCameraActive = false.obs;
  VoidCallback? onTriggerRewardFromCamera;
  final isJourneyEnded = false.obs;
  final isReachedDest = false.obs;
  int selectedStep = 0;
  int currentIndex = 0;
  final notificationStatus = <String, bool>{};
  int currentHazardIndex = 0;
  final directionResponse = Rxn<DirectionsResult>();
  final directionsService = DirectionsService();
  RxInt recordedJourneyMode = 0.obs;
  final speed = '0.0KM/H'.obs;
  BehaviorSubject<double> radius = BehaviorSubject<double>.seeded(6.0);
  final isMapInitialized = false.obs;
  final destLatLng = Rxn<LatLng>();
  final pickUpLatLng = Rxn<LatLng>();
  late GeoFirePoint geo;
  final selectedRoute = Rxn<RouteSummery>();
  final topPosition = 50.0.obs;
  final RxInt totalAwarenessChecks = 0.obs;
  final RxInt successfulAwarenessChecks = 0.obs; // both left and right
  final RxInt partialAwarenessChecks = 0.obs; // one side only
  final RxInt failedAwarenessChecks = 0.obs;
  final RxInt totalRewardsEarned = 0.obs;
  TextEditingController pickupController = TextEditingController();
  TextEditingController dropController = TextEditingController();
  AppController appController = Get.find<AppController>();
  final apiKey = 'AIzaSyCy6TbAdJKairdnqz6Wvh3qcv1rypGW-Wo';
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  final ployLines = <Polyline>{}.obs;
  GoogleMapController? googleMapController;
  final markers = <MarkerId, Marker>{}.obs;
  final mTravelZoom = 18.0.obs;
  final zoomLevelChanges = false.obs;
  final currentZoomLevel = 12.1.obs;
  late Stream<List<DocumentSnapshot>> stream;
  bool isInitDirectionEnable = true;
  List<DocumentSnapshot> documentList = [];
  final listRouteSummery = <RouteSummery>[];
  final hazardPoints = <Map<String, dynamic>>[];
  final hazardPointSorted = <HazardSorted>[];
  final icVehicleRepair = BitmapDescriptor.defaultMarker.obs;
  final icAccident = BitmapDescriptor.defaultMarker.obs;
  final icConstruction = BitmapDescriptor.defaultMarker.obs;
  final icFartControl = BitmapDescriptor.defaultMarker.obs;
  final icHospitalControl = BitmapDescriptor.defaultMarker.obs;
  final icParkControl = BitmapDescriptor.defaultMarker.obs;
  final icCrossing = BitmapDescriptor.defaultMarker.obs;
  final icStartLocation = BitmapDescriptor.defaultMarker.obs;
  final icOther = BitmapDescriptor.defaultMarker.obs;
  final icNavigation = BitmapDescriptor.defaultMarker.obs;
  final icNavigationSmall = BitmapDescriptor.defaultMarker.obs;
  final icNavigationLarge = BitmapDescriptor.defaultMarker.obs;
  final icNavigationMedium = BitmapDescriptor.defaultMarker.obs;
  final destinationDisKM = ''.obs;
  final FocusNode pickupFocus = FocusNode();
  final FocusNode dropFocus = FocusNode();
  final isSelectedPolyLineIndex = 0.obs;

  void closeKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  final polylineInfo = {}.obs; // Store distance and time info for each polyline
  final selectedPolylineInfo =
      {}.obs; // Store distance and time info for each polyline
  void addPolyLines(List<LatLng> points, int index,
      {bool isSelected = false, String movingMode = 'driving'}) async {
    PolylineId polylineId = PolylineId('polyline:$index');
    double totalDistanceInKm = calculateDistance(points.first, points.last);

    // Get distance & time info (if available)
    var distanceTimeInfo = await getDistanceUsingDirections(points, movingMode);
    if (distanceTimeInfo != null) {
      polylineInfo[polylineId] = distanceTimeInfo;
      if (isSelected) {
        selectedPolylineInfo.clear();
        selectedPolylineInfo.addAll({
          "Distance": "${distanceTimeInfo['distance']['text']}",
          "Time": "${distanceTimeInfo['duration']['text']}",
          "Instructions": distanceTimeInfo['steps']
        });
      }
    }

    // Set polyline color based on whether it is selected.
    Color polyColor =
        isSelected ? Colors.blueAccent : const Color.fromARGB(255, 97, 98, 101);

    Polyline polyline = Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      visible: true,
      endCap: Cap.roundCap,
      jointType: JointType.mitered,
      width: 10,
      geodesic: true,
      points: points,
      patterns: isSelectedGoTo.value == 0
          ? []
          : [PatternItem.dot, PatternItem.gap(10)],
      zIndex: index,
      color: polyColor,
      onTap: () {
        // If journey is not started, allow tapping to change the selected route.
        if (!isJourneyStarted.value) {
          selectedRoute.value = listRouteSummery[index];
          updateRoutePolylines();
        }
        _showDistanceTimeInfo(polylineId);
      },
    );

    ployLines.add(polyline);
  }

  void updateRoutePolylines() {
    // Build a new set for the route polylines only
    Set<Polyline> newRoutePolylines = {};

    if (isJourneyStarted.value) {
      if (selectedRoute.value != null) {
        // When journey is started, show only the selected route.
        newRoutePolylines.add(createRoutePolyline(selectedRoute.value!.path, 0,
            isSelected: true));
      }
    } else {
      // Otherwise, show all alternative routes.
      for (int i = 0; i < listRouteSummery.length; i++) {
        print("LIST_ROUTE_SUMMERY=>${i}=>${listRouteSummery[i]}");
        bool isSelected = (selectedRoute.value == listRouteSummery[i]);
        newRoutePolylines.add(createRoutePolyline(listRouteSummery[i].path, i,
            isSelected: isSelected,
            movingMode: isSelectedGoTo.value == 0 ? 'driving' : 'walking'));
      }
    }

    // Remove only those polylines that are from the route alternatives.
    // This assumes all your route polylines have an id with prefix "polyline:".
    ployLines.removeWhere((p) => p.polylineId.value.startsWith("polyline:"));

    // Then add the new routes (selected + alternate).
    ployLines.addAll(newRoutePolylines);

    // Update hazard markers based on the currently selected route [or union of all route bounds if needed].
    if (selectedRoute.value != null) {
      updateMarkersForRoute(selectedRoute.value!.path);
    }
  }

  void updateMarkersForRoute(List<LatLng> routePoints) {
    // Remove previous hazard and crossing markers.
    markers.removeWhere((markerId, marker) =>
        marker.infoWindow.title == "Pedestrian Crossing Along Route" ||
        (marker.infoWindow.title != null &&
            marker.infoWindow.title!.toLowerCase().contains("hazard")));

    // Update hazard markers from the document list if available.
    if (documentList.isNotEmpty) {
      const double hazardThresholdKm = 0.05;
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        final GeoPoint gp = data['position']['geopoint'];
        LatLng hazardLoc = LatLng(gp.latitude, gp.longitude);
        bool isNearRoute = false;
        for (int i = 0; i < routePoints.length - 1; i++) {
          double d = distancePointToSegment(
              hazardLoc, routePoints[i], routePoints[i + 1]);
          if (d < hazardThresholdKm) {
            isNearRoute = true;
            break;
          }
        }
        if (isNearRoute) {
          _addMarkerOnMap(hazardLoc, getIconFromString(data['title']), "");
        }
      }
    }

    // Also update pedestrian crossing markers.
    extractCrossingsAlongRoute(routePoints);
    sortHazardPoints();
  }

  Future<void> handleCameraReward(BuildContext context,
      {required bool lookedLeft, required bool lookedRight}) async {
    print("in");
    print("LOOKED_LEFT=>${lookedLeft}, LOOKED_RIGHT=>${lookedRight}");
    totalAwarenessChecks.value++;
    if (lookedLeft && lookedRight) {
      successfulAwarenessChecks.value++;
    } else if (lookedLeft || lookedRight) {
      partialAwarenessChecks.value++;
    } else {
      failedAwarenessChecks.value++;
    }
    int reward = 0;
    String rewardMessage = "";
    if (lookedLeft && lookedRight) {
      reward = 10;
      rewardMessage = "Reward Earned: 10 points (looked both left and right)";
    } else if (lookedLeft) {
      reward = 5;
      rewardMessage = "Reward Earned: 5 points (Left only)";
    } else if (lookedRight) {
      reward = 5;
      rewardMessage = "Reward Earned: 5 points (Right only)";
    } else {
      rewardMessage = "No reward earned";
    }
    totalRewardsEarned.value += reward;

    // If notifyRewards is true, show a push notification instead of dialogs.
    if (notifyRewards.value) {
      await _showRewardNotification(rewardMessage);
    } else {
      // Show a dialog saying "Calculating rewards..."
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            title: Text("Reward"),
            content: Text("Calculating rewards..."),
          );
        },
      );
      // Simulate reward processing delay.
      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pop(); // Dismiss the calculating dialog.
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Reward"),
            content: Text(rewardMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              )
            ],
          );
        },
      );
    }
  }

  // Helper method to show a local push notification with the reward message.
  Future<void> _showRewardNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reward_channel_id',
      'Rewards',
      channelDescription: 'Notification channel for reward messages',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Reward Earned',
      message,
      platformChannelSpecifics,
    );
  }

  void _showDistanceTimeInfo(PolylineId polylineId) {
    print("SELECTED_POLYLINE_ID=>${polylineId}");
    var info = polylineInfo[polylineId];
    if (info != null) {
      print(
          "SELECTED_POLYLINE_DETAILS=>Distance: ${info['distance']['text']}, Time: ${info['duration']['text']}");
      EasyLoading.showToast(
          'Distance: ${info['distance']['text']}, Time: ${info['duration']['text']}');

      selectedPolylineInfo.addAll({
        "Distance": "${info['distance']['text']}",
        "Time": "${info['duration']['text']}",
        "Instructions": info['steps'], // Ensure steps are correctly assigned
      });

      List instructions = selectedPolylineInfo['Instructions'];
      print("INSTRUCTIONS FOR SELECTED POLYLINE:");
      for (var instruction in instructions) {
        print(
            'ONTAP_POLY_LIN_INFPRMATION=>${instruction}'); // Print each instruction for debugging
      }
      print("SELECTED_POLY_LINE_INFORMATION=>${instructions.length}");
    }
  }

  void _handlePolylineTap(int selectedIndex) {
    isSelectedPolyLineIndex.value = selectedIndex;
    final updatedPolylines = ployLines.map((polyline) {
      final newColor = polyline.polylineId.value == 'polyline:$selectedIndex'
          ? Colors.blueAccent
          : const Color.fromARGB(255, 97, 98, 101);
      return polyline.copyWith(colorParam: newColor);
    }).toSet();
    ployLines.clear();
    ployLines.addAll(updatedPolylines);
  }

  final key = GlobalKey<SpeedDialState>();
  bool documentRead = true;

  void _addMarkerOnMap(LatLng latLng, Pointers type, String? Title) {
    final id =
        MarkerId(latLng.latitude.toString() + latLng.longitude.toString());
    markers[id] = Marker(
      markerId: id,
      position: latLng,
      icon: getIcon(type),
      infoWindow: InfoWindow(
        title: Title ?? type.toString(),
        snippet: 'address',
      ),
    );
    //BitmapDescriptor.defaultMarker
  }

  _readAllMarkers() {
    GeoFirePoint center = GeoFirePoint(GeoPoint(
        appController.currentPosition.value!.latitude ?? 0.0,
        appController.currentPosition.value!.longitude ?? 0.0));
    stream = radius.switchMap((rad) {
      GeoPoint geopointFrom(Map<String, dynamic> data) =>
          (data['position'])['geopoint'];
      final collectionReference =
          FirebaseFirestore.instance.collection('locator');
      return GeoCollectionReference<Map<String, dynamic>>(collectionReference)
          .subscribeWithin(
        center: center,
        radiusInKm: rad,
        field: 'position',
        strictMode: true,
        geopointFrom: geopointFrom,
      );
    });
    stream.listen(
      (List<DocumentSnapshot> documentList) {
        // if (!documentRead) return;
        _updatePath(documentList);
        this.documentList = documentList;
        initDirectionService();
        Timer(const Duration(seconds: 10), () => isInitDirectionEnable = true);
        EasyLoading.dismiss();
        isMapInitialized.value = true;
      },
    );
  }

  _updatePath(List<DocumentSnapshot> documentList) {
    hazardPoints.clear();
    for (var document in documentList) {
      final data = document.data() as Map<String, dynamic>;
      data['doc_id'] = document.id;
      hazardPoints.add(data);
      final GeoPoint point = data['position']['geopoint'];

      _addMarkerOnMap(LatLng(point.latitude, point.longitude),
          getIconFromString(data['title']), '');
    }
  }

  initDirectionService() async {
    if (!isInitDirectionEnable) return;
    if (destLatLng.value == null) return;
    isInitDirectionEnable = false;

    // Clear previous route summaries and overlays.
    listRouteSummery.clear();
    ployLines.clear();
    selectedPolylineInfo.clear();
    markers.clear();

    // Reset additional state as needed.
    notificationStatus.clear();
    currentHazardIndex = 0;
    selectedStep = 0;
    currentIndex = 0;

    String pickUpLocation =
        '${pickUpLatLng.value?.latitude},${pickUpLatLng.value?.longitude}';
    String currentLocation =
        '${appController.currentPosition.value?.latitude},${appController.currentPosition.value?.longitude}';

    final request = DirectionsRequest(
      origin: pickUpLatLng.value == null ? currentLocation : pickUpLocation,
      unitSystem: UnitSystem.imperial,
      destination:
          '${destLatLng.value?.latitude},${destLatLng.value?.longitude}',
      alternatives: true,
      travelMode:
          isSelectedGoTo.value == 0 ? TravelMode.driving : TravelMode.walking,
    );

    directionsService.route(request,
        (DirectionsResult response, DirectionsStatus? status) async {
      if (status == DirectionsStatus.ok &&
          response.routes != null &&
          response.routes!.isNotEmpty) {
        directionResponse.value = response;
        listRouteSummery.clear();
        for (int i = 0; i < response.routes!.length; i++) {
          print("ROUTE_SUMMERY=>${i}=>${response.routes![i]}");
          DirectionsRoute route = response.routes!.elementAt(i);
          List<LatLng> routePoints = convertToLatLng(
              route, decodePoly(route.overviewPolyline!.points!));
          listRouteSummery.add(RouteSummery(
              route: route,
              hazardPoint: {},
              minDist: routePoints.length,
              path: routePoints));
        }
        // Select a default route, for example the first one.
        selectedRoute.value = listRouteSummery.first;

        // Update all route polylines (blue for selected, lighter blue for alternate)
        updateRoutePolylines();

        if (selectedRoute.value != null) {
          if (destLatLng.value != null &&
              selectedRoute.value!.path.isNotEmpty) {
            String mode = isSelectedGoTo.value == 0 ? 'driving' : 'walking';
            getDistanceUsingDirections(selectedRoute.value!.path, mode)
                .then((info) {
              if (info != null) {
                polylineInfo[PolylineId('polyline:0')] = info;
                selectedPolylineInfo.value = {
                  "Distance": "${info['distance']['text']}",
                  "Time": "${info['duration']['text']}",
                  "Instructions": info['steps']
                };
                _showDistanceTimeInfo(PolylineId('polyline:0'));
              }
            });
          }
        }

        // Destination marker and other markers can be added normally.
        final id = MarkerId(Pointers.DESTINATION.toString());
        markers[id] = Marker(
          markerId: id,
          position: destLatLng.value!,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: dropController.text.split(',').first,
            snippet: dropController.text,
          ),
        );
        if (isSelectedGoTo.value != 0) {
          extractCrossingsAlongRoute();
        }
      } else {
        log('Direction service failed: $status');
      }
    });
  }

  Future<BitmapDescriptor> _getCustomIcon() async {
    return BitmapDescriptor.fromBytes(await getBytesFromAsset(
        'assets/ic_current.png', 36)); // Size of the icon
  }

  List<LatLng> convertToLatLng(DirectionsRoute route, List points) {
    List<LatLng> result = <LatLng>[];
    Map<String, dynamic> hazards = {};
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        double lat = points[i - 1];
        double lon = points[i];
        result.add(LatLng(lat, lon));
        for (int i = 0; i < hazardPoints.length; i++) {
          var data = hazardPoints.elementAt(i);

          final GeoPoint element = data['position']['geopoint'];

          LatLng latLng1 = LatLng(lat, lon);
          LatLng latLng2 = LatLng(element.latitude, element.longitude);
          double distance = calculateDistance(latLng2, latLng1);

          // final Timestamp mTime =
          //     data['time'] ?? DateTime.now().millisecondsSinceEpoch / 1000;
          // final bool isPermanent = data['is_permanent'] ?? false;
          // final int stillThere = data['still_there'] ?? 0;
          // final int cleared = data['cleared'] ?? 0;
          // DateTime dateTime = DateTime.now();
          // print('mTime => ${mTime.seconds}, dateTime => ${dateTime.second}');
          // int diffTime =
          //     dateTime.millisecondsSinceEpoch ~/ 1000 - mTime.seconds;

          if (distance < 0.2) {
            hazards[data['position']['geohash']] = data;
          }
        }
      }
    }
    print("HAZARD_POINTS=>${hazards}");
    listRouteSummery.add(RouteSummery(
        route: route,
        hazardPoint: hazards,
        minDist: hazards.length,
        path: result));
    return result;
  }

  // for remove hazard auto matic
  _removeMarker(data) {
    String docId = data['doc_id'];
    FirebaseFirestore.instance.collection('locator').doc(docId).delete();
  }

  _sortHzPoints() {
    List<HazardSorted> temp = [];
    LatLng latLngCurrent = LatLng(
        appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.latitude ?? 0.0);
    for (var element in hazardPointSorted) {
      final GeoPoint point = element.hazardPoint['position']['geopoint'];
      double distance = calculateDistance(
          isFixed.value ? startLatLong : latLngCurrent,
          LatLng(point.latitude, point.longitude));
      element.distance = distance;
      temp.add(element);
    }
    hazardPointSorted.clear();
    hazardPointSorted.addAll(temp);
    hazardPointSorted.sort((a, b) => a.distance.compareTo(b.distance));
  }

  void sortHazardPoints() {
    hazardPointSorted.clear();
    LatLng latLngCurrent = LatLng(
        appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.latitude ?? 0.0);
    selectedRoute.value?.hazardPoint.forEach((key, data) {
      final GeoPoint point = data['position']['geopoint'];
      final String geohash = data['position']['geohash'];
      double distance = calculateDistance(
          isFixed.value ? startLatLong : latLngCurrent,
          LatLng(point.latitude, point.longitude));
      hazardPointSorted
          .add(HazardSorted(hazardPoint: data, distance: distance));
      notificationStatus[geohash] = notificationStatus[geohash] ?? true;
    });

    hazardPointSorted.sort((a, b) => a.distance.compareTo(b.distance));
  }

  final walkingTime = 'Calculating...'.obs;

  _updateNavigation() async {
    LatLng? lng = isFixed.value
        ? startLatLong
        : LatLng(appController.currentPosition.value?.latitude ?? 0.0,
            appController.currentPosition.value?.longitude ?? 0.0);

    StepDetails stepDetails =
        countSteps(selectedRoute.value?.route, lng, selectedStep);
    selectedStep = stepDetails.stepCount;
    LatLng lngDest =
        stepDetails.lastPoint ?? destLatLng.value ?? const LatLng(0.0, 0.0);
    if (stepDetails.instruction != null) {
      instruction.value = stepDetails.instruction;
      final document = parse(instruction.value);
      final String parsedString =
          parse(document.body?.text).documentElement?.text ?? '';
      // only instruction alert
      speakText(parsedString);
      showRouteDialogAndCoin(parsedString);
    }
    GoogleMapController mContr = await mapController.future;
    mContr
        .getScreenCoordinate(LatLng(
            appController.currentPosition.value?.latitude ?? 0.0,
            appController.currentPosition.value?.longitude ?? 0.0))
        .then((value) {
      log('Current =========>>  $value');
    });
    if (!zoomLevelChanges.value) {
      double bearing = Geolocator.bearingBetween(
          lng.latitude ?? 0.0,
          lng.longitude ?? 0.0,
          lngDest.latitude ?? 0.0,
          lngDest.longitude ?? 0.0);
      // your location is empty then this method working
      if (pickUpLatLng.value == null) {
        googleMapController
            ?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          bearing: bearing,
          target: lng,
          tilt: appController.normalTilt,
          zoom: mTravelZoom.value,
        )));
      }
    }
    // if (kDebugMode) {
    //   print('mTravelZoom.value ========>  ${mTravelZoom.value}');
    if (!isFixed.value) {
      if (isJourneyStarted.value) {
        const id = MarkerId('currentPath');
        markers[id] = Marker(
          markerId: id,
          position: lng,
          // icon: icNavigation.value,
          icon: _getNavigationLogo(),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: dropController.text,
          ),
        );
      }
    }

    // }

    _updateHazardInfo();
    _updateDestinationInfo();
    // Only when in walking mode
    if (isSelectedGoTo.value != 0) {
      const double cameraActivationThreshold = 0.02; // e.g. 30 meters
      LatLng currentPos = LatLng(
          appController.currentPosition.value?.latitude ?? 0.0,
          appController.currentPosition.value?.longitude ?? 0.0);

      // Find the nearest crossing along the route.
      LatLng? nearestCrossing;
      double minDist = double.maxFinite;
      for (LatLng crossing in crossingsAlongRoute) {
        double d = calculateDistance(currentPos, crossing);
        if (d < minDist) {
          minDist = d;
          nearestCrossing = crossing;
        }
      }

      // Reset trigger if no crossing is nearby.
      if (nearestCrossing == null || minDist >= cameraActivationThreshold) {
        lastTriggeredCrossing = null;
      }

      // Trigger camera preview only if conditions are met and not already triggered for the same crossing.
      if (checkAwareness.value &&
          nearestCrossing != null &&
          minDist < cameraActivationThreshold &&
          (lastTriggeredCrossing == null ||
              calculateDistance(nearestCrossing, lastTriggeredCrossing!) >
                  cameraActivationThreshold) &&
          !isCameraActive.value) {
        print("Activating camera preview...");
        isCameraActive.value = true;
        lastTriggeredCrossing = nearestCrossing;
        Timer(const Duration(seconds: 10), () {
          isCameraActive.value = false;
          if (onTriggerRewardFromCamera != null) {
            onTriggerRewardFromCamera!();
          }
        });
      } else {
        print("Camera preview not activated; conditions not met.");
      }
    }
  }

  Future<void> configureTts() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
  }

  void speakText(String text) async {
    await flutterTts.speak(text);
  }

  void stopSpeaking() async {
    await flutterTts.stop();
  }

  _getNavigationLogo() {
    if (currentZoomLevel.value < 12) {
      return icNavigationSmall.value;
    } else if (currentZoomLevel.value >= 12 && currentZoomLevel.value < 14) {
      return icNavigationMedium.value;
    } else if (currentZoomLevel.value >= 14 && currentZoomLevel.value < 16) {
      return icNavigation.value;
    } else {
      return icNavigationLarge.value;
    }
  }

  _updateHazardInfo() {
    if (hazardPointSorted.isEmpty) {
      showNotification.value = false;
      return;
    }
    _sortHzPoints();

    HazardSorted hazardSorted = hazardPointSorted.first;
    final GeoPoint point = hazardSorted.hazardPoint['position']['geopoint'];
    final String geoHash = hazardSorted.hazardPoint['position']['geohash'];
    LatLng hLng = LatLng(point.latitude, point.longitude);
    LatLng cLng = /*isFixed.value?startLatLong:*/ LatLng(
        appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.longitude ?? 0.0);
    double distance = calculateDistance(cLng, hLng);
    print("DISTENCE_FOR_HAZARD=>${distance}");
    // log('${hazardPointSorted.length}, $currentHazardIndex, $distance, ${notificationStatus[geoHash]}, ${showNotification.value}');
    if (distance < 0.06 &&
        (notificationStatus[geoHash] ?? true) &&
        !showNotification.value) {
      hInfoPoint.value = hazardSorted;
      hInfoPoint.value?.distance = distance;
      measureDistance = distance;
      notificationStatus[geoHash] = false;
      currentHazardIndex += 1;
      showNotification.value = true;
      String message =
          '${hInfoPoint.value?.hazardPoint['message']}$hazardDistance, at ${hInfoPoint.value?.hazardPoint['locality'].toString().split(',').first ?? ''}';
      message = message.replaceFirst('KM', 'Kilo meter');
      /////// custum added hazard dialog and voice alert
      speakText(message);
      print('HAZARD_TEXT_SPEECH=>$message');
      _showHazardDialogAndAddCoin(hInfoPoint.value?.hazardPoint);
    }

    if (hInfoPoint.value != null) {
      final GeoPoint point =
          hInfoPoint.value?.hazardPoint['position']['geopoint'];
      LatLng hLng = LatLng(point.latitude, point.longitude);
      LatLng cLng = LatLng(appController.currentPosition.value?.latitude ?? 0.0,
          appController.currentPosition.value?.longitude ?? 0.0);
      double distance = calculateDistance(cLng, hLng);
      hInfoPoint.value?.distance = distance;
      hazardDistance.value = distance >= 1
          ? '${distance.toStringAsFixed(2)} KM'
          : '${(distance * 1000).toStringAsFixed(0)}Meter';
      log('minRadarRadius $minRadarRadius, distance $distance, ${minRadarRadius - distance}');
      print("Distence_${hazardDistance.value}");
      if (distance < 0.06) {
        showNotification.value = false;
        hazardPointSorted.remove(hazardSorted);
        notificationStatus[geoHash] = false;
      }
    }
  }

  _updateDestinationInfo() {
    //  var geocoder =  google.maps.Geocoder();
    LatLng cLng = LatLng(appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.longitude ?? 0.0);
    LatLng pickUpLng = LatLng(pickUpLatLng.value?.latitude ?? 0.0,
        pickUpLatLng.value?.longitude ?? 0.0);
    LatLng startDes = pickUpLatLng.value == null ? cLng : pickUpLng;
    if (destLatLng.value != null) {
      double destDistance = calculateDistance(startDes, destLatLng.value!);
      print("DISTANCE_IS_HERE => ${destinationDisKM.value}");
      if (destDistance < 0.5) {
        isJourneyEnded.value = true;
      }

      if (destDistance < 0.05) {
        isReachedDest.value = true;
      }
    }
  }

  recenterCamera() {
    LatLng currentLocation = LatLng(
        appController.currentPosition.value!.latitude,
        appController.currentPosition.value!.longitude);
    mTravelZoom.value = appController.travelZoom;
    zoomLevelChanges.value = false;
    googleMapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: currentLocation,
            bearing: 0,
            tilt: appController.normalTilt,
            zoom: appController.travelZoom)));
  }

  previewCamera(int zoom) {
    LatLng pickUpLocation = LatLng(pickUpLatLng.value!.latitude ?? 00,
        pickUpLatLng.value!.longitude ?? 00);
    mTravelZoom.value = appController.travelZoom;
    zoomLevelChanges.value = false;
    googleMapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: isFixed.value ? startLatLong : pickUpLocation,
            bearing: 0,
            tilt: appController.normalTilt,
            zoom: appController.travelZoom - zoom)));
  }

  clearRoute() async {
    if (isJourneyStarted.value) {
      endJourney();
      if (isSelectedGoTo.value != 0) {
        Get.dialog(
          Status_view(
            totalAwarenessChecks: totalAwarenessChecks.value,
            successfulAwarenessChecks: successfulAwarenessChecks.value,
            partialAwarenessChecks: partialAwarenessChecks.value,
            failedAwarenessChecks: failedAwarenessChecks.value,
            totalJourneySteps: stepCount.value - journeyStartStepCount,
            totalRewardsEarned: totalRewardsEarned.value,
          ),
        );
        totalAwarenessChecks.value = 0;
        successfulAwarenessChecks.value = 0;
        partialAwarenessChecks.value = 0;
        failedAwarenessChecks.value = 0;
        totalRewardsEarned.value = 0;
      }
    }

    notShowConstructionReword.value = false;
    isMapInitialized.value = false;
    isReachedDest.value = false;
    stopSpeaking();
    print('isInitDirectionEnable_Walking_Tab=>${isInitDirectionEnable}');
    LiveDistenceTimeData.value = null;
    isInitDirectionEnable = true;
    isSelectedGoTo.value = 0;
    print(
        'Selected_Walking_Tab=>${isSelectedGoTo.value}----$isInitDirectionEnable');
    isJourneyStarted.value = false;
    isFixed.value = false;
    destLatLng.value = null;
    pickUpLatLng.value = null;
    isJourneyEnded.value = false;
    dropController.text = '';
    pickupController.text = '';
    notificationStatus.clear();
    markers.clear();
    directionResponse.value = null;
    ployLines.clear();
    minDistance = double.infinity;
    minDistance1 = double.infinity;
    listRouteSummery.clear();
    hazardPoints.clear();
    hazardPointSorted.clear();
    hazardDistance.value = '0.0';
    EasyLoading.showToast('Journey Ended');
  }

//for newww

  double percent = 0.0;
  final isDragged = false.obs;
  checkStateDragged() {
    if (percent > 0.5) {
      isDragged.value = true;
    } else {
      isDragged.value = false;
    }
  }

  final isSelectedGoTo = 0.obs;

  void onSeletctGoTo(int position) {
    selectedPolylineInfo.value.clear();
    destinationDisKM.value = '';
    walkingTime.value = 'Calculating...';
    isSelectedGoTo.value = position;
    isInitDirectionEnable = true;
    LiveDistenceTimeData.value = null;
    // _updateNavigation();
    initDirectionService();

    print('TRAVELED_MODE_CHANGED=>${isSelectedGoTo.value}');
  }

  RxList<Results> PlacesList = <Results>[].obs;

  _getNearbyPlaces() {
    LatLng? lng = LatLng(appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.longitude ?? 0.0);
    nearPlaceApi(position: lng).then((onValue) {
      if (onValue.status) {
        NearPlaceModel myModel = onValue.data;
        PlacesList.value = myModel.results!;
        print("place_api_response${PlacesList.value.length}");
      } else {
        print("GOOGLE_PLACE_API_EXCEPTION=>${onValue.message}");
        EasyLoading.showToast(onValue.message.toString());
      }
    });
  }

  _getObstacleMessage(Pointers type) {
    switch (type) {
      case Pointers.OTHER:
        return 'Some Obstacle Ahead';
      case Pointers.VEHICLEREPAIR:
        return 'Vehicle repair service ahead';
      case Pointers.CONSTRUCTION:
        return 'Construction Work Ahead';
      case Pointers.ACCIDENT:
        return 'Accident Ahead';
      case Pointers.HOSPITAL:
        return 'Hospital Ahead';
      case Pointers.PARK:
        return 'Park Ahead';
      case Pointers.FARTCONTROL:
        return 'Speed Camera Ahead';
      default:
        return 'Some Obstacle Ahead';
    }
  }

  _getSeftyMessage(Pointers type) {
    switch (type) {
      case Pointers.OTHER:
        return 'Some Obstacle Ahead';
      case Pointers.VEHICLEREPAIR:
        return 'Vehicle repair service ahead';
      case Pointers.CONSTRUCTION:
        return 'Follow marked paths or detours, wear appropriate footwear, and be aware of uneven surfaces or other hazards';
      case Pointers.ACCIDENT:
        return '';
      case Pointers.HOSPITAL:
        return ' Be aware that a hospital is nearby. Drive cautiously, as there may be increased pedestrian and ambulance activity. If you are a pedestrian, follow the signs for the hospital entrance, and be extra cautious of vehicles entering or exiting the area';
      case Pointers.PARK:
        return 'Park Ahead';
      case Pointers.FARTCONTROL:
        return 'Speed Camera Ahead';
      default:
        return 'Some Obstacle Ahead';
    }
  }

  addPoint(Pointers type) {
    documentRead = false;
    Timer(const Duration(seconds: 30), () => documentRead = true);

    switch (type) {
      case Pointers.OTHER:
        return addOCommonPoint(
            text: 'Adding Other reason',
            icon: 'menu_hz',
            color: const Color(0xFF31706B));
      // return addOtherPoint();

      case Pointers.VEHICLEREPAIR:
        return addOCommonPoint(
            text: 'Adding Vehicle repair',
            icon: 'service',
            color: const Color(0xFF31706B));

      case Pointers.ACCIDENT:
        return addOCommonPoint(
            text: 'Adding Accident',
            icon: 'accident',
            color: const Color(0xFF4B4D84));

      case Pointers.CONSTRUCTION:
        return addOCommonPoint(
            text: 'Adding Construction site',
            icon: 'obstacle',
            color: const Color(0xFFD1C24A));

      case Pointers.HOSPITAL:
        return addOCommonPoint(
            text: 'Adding Hospital Area',
            icon: 'hospital',
            color: const Color(0xFF1590F6));

      case Pointers.PARK:
        return addOCommonPoint(
            text: 'Adding Park Area',
            icon: 'park',
            color: const Color(0xFF12D92C));

      case Pointers.FARTCONTROL:
        return addOCommonPoint(
            text: 'Adding Fart control',
            icon: 'camera',
            color: const Color(0xFFB03329));
      default:
        return addOCommonPoint(
            text: 'Adding Other reason',
            icon: 'menu_hz',
            color: const Color(0xFF31706B));
    }
  }

  List<Widget> addOCommonPoint({text, icon, color}) {
    List<Widget> list = [];

    list.add(Stack(
      alignment: Alignment.center,
      children: [
        //  CircularProgress(size: 26.w, ),

        Container(
          padding: EdgeInsets.all(4),
          margin: EdgeInsets.all(4),
          width: 50,
          height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: Image.asset(
            'assets/$icon.png',
          ),
        )
      ],
    ));

    list.add(Text(
      text,
      style: GoogleFonts.sansita(fontSize: 18),
    ));

    return list;
  }

  getIcon(Pointers type) {
    switch (type) {
      case Pointers.OTHER:
        return icOther.value;
      case Pointers.VEHICLEREPAIR:
        return icVehicleRepair.value;
      case Pointers.ACCIDENT:
        return icAccident.value;
      case Pointers.CONSTRUCTION:
        return icConstruction.value;
      case Pointers.FARTCONTROL:
        return icFartControl.value;
      case Pointers.HOSPITAL:
        return icHospitalControl.value;
      case Pointers.PARK:
        return icParkControl.value;
      case Pointers.CROSSING:
        return icCrossing.value;
      case Pointers.DESTINATION:
        return BitmapDescriptor.defaultMarker;
      case Pointers.STARTLOCATION:
        return icStartLocation.value;
      default:
        return icOther.value;
    }
  }

  initializeIcons() async {
    icNavigationLarge.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_nav_arrow.png', 96));
    icNavigation.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_nav_arrow.png', 72));
    icNavigationMedium.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_nav_arrow.png', 48));
    icNavigationSmall.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_nav_arrow.png', 36));

    icVehicleRepair.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_veh_repair.png', 72));
    icConstruction.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_construction.png', 72));
    icAccident.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_accident.png', 72));

    icFartControl.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_fart_control.png', 72));

    icHospitalControl.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_hospital.png', 72));
    icCrossing.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_crossing.png', 72));
    icParkControl.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_park.png', 72));

    icOther.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_other.png', 72));
    icStartLocation.value = BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/ic_current.png', 72));
  }

  Future<void> addObstaclePoint(BuildContext context, Pointers type) async {
    showModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  IconButton(
                      onPressed: () {
                        //  Get.back();
                      },
                      icon: const Icon(Icons.close))
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: addPoint(type),
              ),
              SizedBox(
                height: 5,
              )
            ],
          );
        });

    final loc.LocatitonGeocoder geocoder = loc.LocatitonGeocoder(apiKey);
    LatLng pickUpLocation = LatLng(pickUpLatLng.value?.latitude ?? 0.0,
        pickUpLatLng.value?.longitude ?? 0.0);
    LatLng currentLocation = LatLng(
        appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.longitude ?? 0.0);

    LatLng? position = /*LatLng(28.564548,77.385951); */
        pickUpLatLng.value == null ? currentLocation : pickUpLocation;

    List<loc.Address> addresses = await geocoder.findAddressesFromCoordinates(
        loc.Coordinates(position.latitude, position.longitude));
    GeoFirePoint geo = GeoFirePoint(
        GeoPoint(position.latitude ?? 0.0, position.longitude ?? 0.0));
    FirebaseFirestore.instance.collection('locator').doc().set({
      'title': type.name,
      'time': DateTime.now(),
      'still_there': 0,
      'cleared': 0,
      'is_permanent': false,
      'message': /*'Pedestrian Crossing Ahead' ,*/
          _getObstacleMessage(type),
      'locality': addresses.first.addressLine,
      'position': geo.data,
      'for_saftey_msm': _getSeftyMessage(type)
    }).then(
      (value) {
        _addMarkerOnMap(
            LatLng(position.latitude ?? 0.0, position.longitude ?? 0.0),
            type,
            '');
        Get.back();
        EasyLoading.showToast(addresses.first.addressLine.toString());
      },
    );
  }

  void redirectToSafeRoute() async {
    // Ensure that destination is set.
    if (destLatLng.value == null) {
      EasyLoading.showToast("Destination not available");
      return;
    }

    // Use current location if pickUpLatLng is null.
    String originLocation = "";
    if (pickUpLatLng.value == null) {
      if (appController.currentPosition.value == null) {
        EasyLoading.showToast("Current location not available");
        return;
      }
      originLocation =
          '${appController.currentPosition.value!.latitude},${appController.currentPosition.value!.longitude}';
    } else {
      originLocation =
          '${pickUpLatLng.value!.latitude},${pickUpLatLng.value!.longitude}';
    }
    String destinationLocation =
        '${destLatLng.value!.latitude},${destLatLng.value!.longitude}';

    // Ensure we have hazard info available.
    if (hInfoPoint.value == null) {
      EasyLoading.showToast("No hazard info available");
      return;
    }
    var hazardData = hInfoPoint.value!.hazardPoint;
    if (hazardData == null ||
        hazardData['position'] == null ||
        hazardData['position']['geopoint'] == null) {
      EasyLoading.showToast("Incomplete hazard info");
      return;
    }
    final GeoPoint hazardGeo = hazardData['position']['geopoint'];
    LatLng hazardLatLng = LatLng(hazardGeo.latitude, hazardGeo.longitude);

    // Define three candidate waypoints relative to the hazard:
    // left: shift west; right: shift east; back: shift south.
    const double offset = 0.8; // roughly a few hundred meters offset
    LatLng waypointLeft =
        LatLng(hazardLatLng.latitude, hazardLatLng.longitude - offset);
    LatLng waypointRight =
        LatLng(hazardLatLng.latitude, hazardLatLng.longitude + offset);
    LatLng waypointBack =
        LatLng(hazardLatLng.latitude - offset, hazardLatLng.longitude);

    String mode = isSelectedGoTo.value == 0 ? 'driving' : 'walking';
    const double hazardSafetyBuffer =
        0.05; // route segments closer than ~50 meters are not allowed

    // Helper: Snap a waypoint to a road (currently dummy implementation).
    Future<LatLng> snapToRoad(LatLng point) async {
      // TODO: Integrate with the Google Roads API.
      return point;
    }

    // Helper: Get a route for a candidate (or snapped) waypoint making sure none of its segments come near the hazard.
    Future<Map<String, dynamic>?> getRouteForWaypoint(LatLng waypoint) {
      Completer<Map<String, dynamic>?> completer = Completer();
      final request = DirectionsRequest(
        origin: originLocation,
        destination: destinationLocation,
        waypoints: [
          DirectionsWaypoint(
              location: '${waypoint.latitude},${waypoint.longitude}')
        ],
        alternatives: false,
        travelMode:
            isSelectedGoTo.value == 0 ? TravelMode.driving : TravelMode.walking,
        unitSystem: UnitSystem.imperial,
      );
      directionsService.route(request,
          (DirectionsResult response, DirectionsStatus? status) async {
        if (status == DirectionsStatus.ok &&
            response.routes != null &&
            response.routes!.isNotEmpty) {
          DirectionsRoute newRoute = response.routes!.first;
          List<LatLng> newRoutePoints = convertToLatLng(
              newRoute, decodePoly(newRoute.overviewPolyline!.points!));

          // Check every segment of the route for hazardous proximity.
          bool routeHasHazard = false;
          for (int i = 0; i < newRoutePoints.length - 1; i++) {
            double d = distancePointToSegment(
                hazardLatLng, newRoutePoints[i], newRoutePoints[i + 1]);
            if (d < hazardSafetyBuffer) {
              routeHasHazard = true;
              break;
            }
          }
          if (routeHasHazard) {
            // Snap the waypoint so it falls on a road.
            LatLng snappedWaypoint = await snapToRoad(waypoint);
            final snapRequest = DirectionsRequest(
              origin: originLocation,
              destination: destinationLocation,
              waypoints: [
                DirectionsWaypoint(
                    location:
                        '${snappedWaypoint.latitude},${snappedWaypoint.longitude}')
              ],
              alternatives: false,
              travelMode: isSelectedGoTo.value == 0
                  ? TravelMode.driving
                  : TravelMode.walking,
              unitSystem: UnitSystem.imperial,
            );
            directionsService.route(snapRequest, (DirectionsResult snapResponse,
                DirectionsStatus? snapStatus) async {
              if (snapStatus == DirectionsStatus.ok &&
                  snapResponse.routes != null &&
                  snapResponse.routes!.isNotEmpty) {
                DirectionsRoute snappedRoute = snapResponse.routes!.first;
                List<LatLng> snappedRoutePoints = convertToLatLng(snappedRoute,
                    decodePoly(snappedRoute.overviewPolyline!.points!));
                // Re-check the snapped route against the hazard.
                bool snappedRouteHasHazard = false;
                for (int i = 0; i < snappedRoutePoints.length - 1; i++) {
                  double d = distancePointToSegment(hazardLatLng,
                      snappedRoutePoints[i], snappedRoutePoints[i + 1]);
                  if (d < hazardSafetyBuffer) {
                    snappedRouteHasHazard = true;
                    break;
                  }
                }
                // Regardless of a minor violation in snapped route, show it.
                var snapInfo =
                    await getDistanceUsingDirections(snappedRoutePoints, mode);
                completer.complete({
                  "route": snappedRoute,
                  "points": snappedRoutePoints,
                  "info": snapInfo,
                  "distance": snapInfo?['distance']['value'] ?? double.infinity,
                });
              } else {
                // If snapping fails, show the original route even though it may have a hazard.
                var info =
                    await getDistanceUsingDirections(newRoutePoints, mode);
                completer.complete({
                  "route": newRoute,
                  "points": newRoutePoints,
                  "info": info,
                  "distance": info?['distance']['value'] ?? double.infinity,
                });
              }
            });
          }
          var info = await getDistanceUsingDirections(newRoutePoints, mode);
          if (info != null &&
              info['distance'] != null &&
              info['distance']['value'] != null) {
            completer.complete({
              "route": newRoute,
              "points": newRoutePoints,
              "info": info,
              "distance": info['distance']['value'],
            });
          } else {
            completer.complete({
              "route": newRoute,
              "points": newRoutePoints,
              "info": {},
              "distance": double.infinity,
            });
          }
        } else {
          completer.complete(null);
        }
      });
      return completer.future;
    }

    // Try three candidate waypoints concurrently.
    var results = await Future.wait([
      getRouteForWaypoint(waypointLeft),
      getRouteForWaypoint(waypointRight),
      getRouteForWaypoint(waypointBack),
    ]);

    // Use whichever candidate yields a valid route.
    var validResults = results.where((res) => res != null).toList();
    if (validResults.isEmpty) {
      // As fallback, try using the left waypoint even if not ideal.
      var fallback = await getRouteForWaypoint(waypointLeft);
      if (fallback == null) return;
      validResults.add(fallback);
    }
    validResults.sort((a, b) => a!["distance"].compareTo(b!["distance"]));
    var bestResult = validResults.first!;

    // Update selected route.
    selectedRoute.value = RouteSummery(
      route: bestResult["route"],
      hazardPoint: {}, // Safe route assumed to have no hazards.
      minDist: bestResult["points"].length,
      path: bestResult["points"],
    );
    updateRoutePolylines();

    // Update displayed distance, time, and instruction info.
    polylineInfo[PolylineId('polyline:0')] = bestResult["info"];
    selectedPolylineInfo.value = {
      "Distance": "${bestResult["info"]['distance']['text']}",
      "Time": "${bestResult["info"]['duration']['text']}",
      "Instructions": bestResult["info"]['steps']
    };
    _showDistanceTimeInfo(PolylineId('polyline:0'));
  }

  _showHazardDialogAndAddCoin(data) {
    if (data['message'].toString() == 'Construction Work Ahead') {
      if (!notShowConstructionReword.value) {
        Get.dialog(barrierColor: Colors.transparent, HazardDialog(data: data));
      }
    } else {
      Get.dialog(barrierColor: Colors.transparent, HazardDialog(data: data));
    }

    if (userLoginModel!.loginType.toString() == 'auth') {
      // if (data['message'].toString() == 'Construction Work Ahead') {
      //   Future.delayed(const Duration(seconds: 5), () {
      //     if (!notShowConstructionReword.value) {
      //       Get.back();
      //       Get.dialog(
      //           barrierColor: Colors.transparent,
      //           ConstructionFollowHazardRewordDialog(data: data));
      //       addLeaderboardReword(data);
      //     }
      //     notShowConstructionReword.value = false;
      //   });
      // } else if (data['message'].toString() == 'Pedestrian Crossing Ahead') {
      //   Get.to(() => const CameraView());
      //   Future.delayed(const Duration(seconds: 5), () {
      //     Get.back();
      //     Get.dialog(
      //         barrierColor: Colors.transparent,
      //         const RouteFollowRewordDialog());
      //     addLeaderboardReword(data);
      //   });
      // }
      // for all type hazard dash bord coins
      addDashboardReword(data);
    } else {
      List<Map<String, dynamic>> newHazards = [];
      if (hazardListHistory.isEmpty) {
        newHazards = [
          {
            "id": 0,
            "title": data['message'],
            "locality": data['locality'],
            "time": DateTime.now().toLocal().toString(),
            "coin": 5,
          },
        ];
      } else {
        for (var data in hazardListHistory) {
          newHazards.add(data);
        }
        Map<String, dynamic> newhaz = {
          "id": 0,
          "title": data['message'],
          "locality": data['locality'],
          "time": DateTime.now().toLocal().toString(),
          "coin": 5,
        };
        newHazards.add(newhaz);

        print("NEW_HAZARD_ADDED_SUCCESS_LENGTH${newHazards.length}");
        print("NEW_HAZARD_ADDED_SUCCESS${newHazards}");
      }

      setuserHazardModelFromPF(newHazards).whenComplete(() {
        getuserHazardModel().then((onValue) {
          hazardListHistory = onValue!;
          print('AHSGDDGSasasaGGHJG${hazardListHistory.length}');
        });
      });
    }
  }

  showRouteDialogAndCoin(data) {
    Get.dialog(barrierColor: Colors.transparent, InstructionDialog(data: data));
    if (userLoginModel!.loginType.toString() == 'auth') {
      if (data.contains('cross')) {
        Get.back();
        Get.to(() => CameraView(
              data: data,
            ));
      }
    }
  }

  Future<void> addDashboardReword(data) async {
    dynamic time = DateTime.now().millisecondsSinceEpoch.toString();
    var hashMap = {
      "id": time,
      "title": data['message'],
      "locality": data['locality'],
      "time": DateTime.now().toLocal().toString(),
      "coin": 5,
    };
    await firestore
        .collection('users')
        .doc(userLoginModel?.id.toString())
        .collection('reword')
        .doc(time)
        .set(hashMap);
  }

  Future<bool> leaderExists(String id) async {
    return (await firestore.collection('leaderboard').doc(id).get()).exists;
  }

  Future<void> addLeaderboardReword(data) async {
    if (await leaderExists(userLoginModel!.id.toString())) {
      var data = await firestore
          .collection('leaderboard')
          .doc(userLoginModel!.id.toString())
          .get();
      Map<String, dynamic>? leaderData = data.data();
      int points = leaderData?['coin'];
      await firestore
          .collection('leaderboard')
          .doc(userLoginModel!.id.toString())
          .update({
        'coin': points + 5,
        'time': DateTime.now().toLocal().toString(),
        'locality': leaderData?['locality'].toString()
      });
    } else {
      var hashMap = {
        "id": userLoginModel?.id.toString(),
        "title": data['message'],
        "locality": data['locality'],
        "time": DateTime.now().toLocal().toString(),
        "coin": 5,
      };
      await firestore
          .collection('leaderboard')
          .doc(userLoginModel?.id.toString())
          .set(hashMap);
    }
  }

  Future<void> fetchOverpassData() async {
    print("in dev");
    final currentPos = appController.currentPosition.value;
    if (currentPos == null) {
      print("User position not available yet.");
      return;
    }

    double lat = currentPos.latitude;
    double lng = currentPos.longitude;
    double delta = 0.225; // roughly a 50km x 50km bounding box
    double north = lat + delta;
    double south = lat - delta;
    double east = lng + delta;
    double west = lng - delta;

    String query = """
  [out:json];
  node["highway"="crossing"]($south,$west,$north,$east);
  out;
  """;

    print("Generated bounding box covering roughly 50km:");
    print("North: $north, South: $south, East: $east, West: $west");

    try {
      final response = await http.post(
        Uri.parse("https://overpass-api.de/api/interpreter"),
        body: query,
      );
      if (response.statusCode == 200) {
        print("Overpass API response: ${response.body}");
        // Save the response for later filtering.
        overpassData = jsonDecode(response.body);
        // (Optionally, you might mark all crossings here if needed.)
      } else {
        print(
            "Error from Overpass API: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Exception during Overpass API call: $e");
    }
  }

  void extractCrossingsAlongRoute([List<LatLng>? routePoints]) {
    // Clear previous pedestrian crossing markers.
    markers.removeWhere((markerId, marker) =>
        marker.infoWindow.title == "Pedestrian Crossing Along Route");
    if (routePoints == null) {
      if (selectedRoute.value == null) {
        print("Route not available.");
        return;
      }
      routePoints = selectedRoute.value!.path;
    }
    if (overpassData == null) {
      print("Overpass data not available.");
      return;
    }

    List<LatLng> filteredCrossings = [];
    const double thresholdDistanceKm = 0.03; // e.g., 30 meters

    if (overpassData["elements"] != null) {
      for (var element in overpassData["elements"]) {
        double crossingLat = element["lat"];
        double crossingLon = element["lon"];
        LatLng crossingPoint = LatLng(crossingLat, crossingLon);

        // Compute the minimum distance from crossingPoint to any segment of the provided routePoints.
        double minDistanceToRoute = double.maxFinite;
        for (int i = 0; i < routePoints.length - 1; i++) {
          double d = distancePointToSegment(
              crossingPoint, routePoints[i], routePoints[i + 1]);
          if (d < minDistanceToRoute) {
            minDistanceToRoute = d;
          }
        }

        if (minDistanceToRoute < thresholdDistanceKm) {
          filteredCrossings.add(crossingPoint);
          String id = element["id"].toString();
          markers[MarkerId(id)] = Marker(
            markerId: MarkerId(id),
            position: crossingPoint,
            infoWindow: InfoWindow(title: "Pedestrian Crossing Along Route"),
            icon: getIcon(Pointers.CROSSING),
          );
        }
      }
    }
    crossingsAlongRoute = filteredCrossings;
    print(
        "Extracted ${crossingsAlongRoute.length} pedestrian crossing points along the polyline.");
    // update();
  }

  Future<String> getAddressFromLatLng(LatLng latlng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latlng.latitude, latlng.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
      return "${latlng.latitude}, ${latlng.longitude}";
    } catch (e) {
      print("Reverse geocoding error: $e");
      return "${latlng.latitude}, ${latlng.longitude}";
    }
  }

  Future<void> displayRecordedJourney({
    required List<LatLng> journeyPoints,
    required int mode,
    required String origin,
    required String destination,
  }) async {
    if (journeyPoints.isEmpty) {
      print("No recorded journey available.");
      return;
    }

    // Auto-populate the "from" and "to" fields.
    isSelectedGoTo.value = mode;
    pickUpLatLng.value = journeyPoints.first;
    destLatLng.value = journeyPoints.last;
    String originAddress = origin.trim();
    if (originAddress.isEmpty) {
      originAddress = await getAddressFromLatLng(journeyPoints.first);
    }

    // If destination (drop) is empty, use last point from journeyPoints and reverse geocode.
    String destinationAddress = destination.trim();
    if (destinationAddress.isEmpty) {
      destinationAddress = await getAddressFromLatLng(journeyPoints.last);
    }
    pickupController.text = originAddress;
    dropController.text = destinationAddress;

    // Clear previous polyline(s) then display the route.
    ployLines.clear();
    String movingMode = mode == 0 ? 'driving' : 'walking';
    addPolyLines(journeyPoints, 0, movingMode: movingMode);
    // Fetch and update distance, duration, and step instructions.
    var distanceTimeInfo =
        await getDistanceUsingDirections(journeyPoints, movingMode);
    if (distanceTimeInfo != null) {
      PolylineId polylineId = PolylineId('polyline:0');
      polylineInfo[polylineId] = distanceTimeInfo;
      selectedPolylineInfo.addAll({
        "Distance": "${distanceTimeInfo['distance']['text']}",
        "Time": "${distanceTimeInfo['duration']['text']}",
        "Instructions": distanceTimeInfo['steps']
      });
      print(
          "Updated instructions: ${selectedPolylineInfo.value['Instructions']}");
    }
  }

  void startJourney() {
    // Check if there is a selected route and if it contains hazards.
    print("Safe Routes: ${listRouteSummery.length}");
    if (selectedRoute.value != null &&
        selectedRoute.value!.hazardPoint.isNotEmpty) {
      // Prompt the user about the hazard on the selected route.
      Get.defaultDialog(
        barrierDismissible: false,
        title: 'Hazard Detected',
        middleText:
            'The path you have selected has hazards. Do you wish to proceed?',
        textConfirm: 'Proceed',
        textCancel: 'Select Safe Route',
        onConfirm: () {
          // Deduct 5 coins here if necessary.
          _continueStartJourney();
          Get.back();
        },
        onCancel: () {},
      );
      return;
    }
    // If no hazards are present or no safe alternative exists, continue.
    _continueStartJourney();
  }

  // Call this method to start a new journey.
  void _continueStartJourney() {
    recenterCamera();
    recordedJourney.clear(); // Clear any previously recorded route.
    isJourneyStarted.value = true;
    journeyStartStepCount = stepCount.value; // Record steps at start.
    journeyStartTime.value = DateTime.now();
    recordedJourneyMode.value = isSelectedGoTo.value; // Save the mode.
    print(
        "Journey started at ${journeyStartTime.value} with mode ${recordedJourneyMode.value}");
  }

  // When the journey ends, call endJourney()
  // which also calls storeJourneyHistory() to save the details.
  Future<void> endJourney() async {
    journeyEndTime.value = DateTime.now();
    print(
        "Journey ended at ${journeyEndTime.value}. Recorded ${recordedJourney.length} points.");
    await storeJourneyHistory();
  }

  // This method stores the journey history in Firestore under a subcollection "history"
  // of the current user document.
  Future<void> storeJourneyHistory() async {
    // Use journeyStartTime and journeyEndTime with a fallback
    print('in storer');
    DateTime startTime = journeyStartTime.value ?? DateTime.now();
    DateTime endTime = journeyEndTime.value ?? DateTime.now();

    // Build the history data to store.
    Map<String, dynamic> historyData = {
      'journeyDate': startTime.toIso8601String(),
      'journeyStartTime': startTime.toIso8601String(),
      'journeyEndTime': endTime.toIso8601String(),
      'journeyStartLocation': pickupController.text,
      'journeyEndLocation': dropController.text,
      'recordedJourney': recordedJourney
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'status': {
        'totalAwarenessChecks': totalAwarenessChecks.value,
        'successfulAwarenessChecks': successfulAwarenessChecks.value,
        'partialAwarenessChecks': partialAwarenessChecks.value,
        'failedAwarenessChecks': failedAwarenessChecks.value,
        'stepsTaken': stepCount.value - journeyStartStepCount,
        'totalRewardsEarned': totalRewardsEarned.value,
      },
      // Optionally, record the mode as a string.
      'mode': isSelectedGoTo.value,
    };

    // Use the current user ID to build the Firestore path.
    String userId = userLoginModel?.id.toString() ?? "unknownUser";
    // Use Firestore auto-ID for each journey history document.
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .add(historyData);
      print("Journey history stored successfully for user: $userId");
    } catch (e) {
      print("Error storing journey history: $e");
    }
  }

  void showJourneyHistory() {
    final String userId = userLoginModel?.id.toString() ?? "";
    Get.to(() => JourneyHistoryView(userId: userId));
  }
}

// This function approximates the distance (in kilometers) from point p to the segment ab using a planar projection.
double distancePointToSegment(LatLng p, LatLng a, LatLng b) {
  final rad = pi / 180; // conversion factor

  // Equirectangular approximation
  double x_p = p.longitude * cos(p.latitude * rad);
  double y_p = p.latitude;
  double x_a = a.longitude * cos(a.latitude * rad);
  double y_a = a.latitude;
  double x_b = b.longitude * cos(b.latitude * rad);
  double y_b = b.latitude;

  double A = x_p - x_a;
  double B = y_p - y_a;
  double C = x_b - x_a;
  double D = y_b - y_a;

  double dot = A * C + B * D;
  double lenSq = C * C + D * D;
  double param = (lenSq != 0) ? dot / lenSq : -1;

  double xx, yy;
  if (param < 0) {
    xx = x_a;
    yy = y_a;
  } else if (param > 1) {
    xx = x_b;
    yy = y_b;
  } else {
    xx = x_a + param * C;
    yy = y_a + param * D;
  }

  double dx = x_p - xx;
  double dy = y_p - yy;
  double distanceDegrees = sqrt(dx * dx + dy * dy);

  // Conversion factor (1 degree ≈ 111.32 km)
  return distanceDegrees * 111.32;
}
