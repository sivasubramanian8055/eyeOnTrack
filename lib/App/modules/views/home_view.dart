import 'dart:io';
import 'package:crypoexchange/App/helper/camera_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:material_speed_dial/material_speed_dial.dart';
import '../../helper/app_paths.dart';
import '../../helper/app_strings.dart';
import '../../helper/completed_ui.dart';
import '../../helper/place_search_field.dart';
import '../../helper/profile_dialog.dart';
import '../controllers/home_controller.dart';
import 'camera_preview_draggable.dart';
import '../../helper/camera_helper.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.checkStateDragged();
    return WillPopScope(
      onWillPop: () async {
        exit(0);
      },
      child: Obx(
        () => controller.appController.currentPosition.value == null
            ? const Center(child: CircularProgressIndicator())
            : Scaffold(
                resizeToAvoidBottomInset: false,
                key: controller.scaffoldKey,
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    // Google Map as background.
                    Positioned.fill(
                      child: GoogleMap(
                        compassEnabled: false,
                        trafficEnabled: true,
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        indoorViewEnabled: true,
                        polylines: Set<Polyline>.of(controller.ployLines),
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            controller.appController.currentPosition.value
                                    ?.latitude ??
                                0.0,
                            controller.appController.currentPosition.value
                                    ?.longitude ??
                                0.0,
                          ),
                          bearing: controller.appController.normalBearing,
                          tilt: controller.appController.normalTilt,
                          zoom: controller.appController.normalZoom,
                        ),
                        markers: controller.markers.values.toSet(),
                        onMapCreated: (GoogleMapController mController) {
                          controller.mapController.complete(mController);
                          controller.mapController.future.then(
                            (value) => controller.googleMapController = value,
                          );
                        },
                        onCameraMove: (position) {
                          controller.currentZoomLevel.value = position.zoom;
                          controller.zoomLevelChanges.value =
                              controller.mTravelZoom.value != position.zoom;
                        },
                      ),
                    ),
                    // Top menu.
                    if (!controller.isJourneyStarted.value)
                      Positioned(
                        top: 5.0,
                        left: 0.0,
                        right: 0.0,
                        child: topMenu(context),
                      ),
                    // Bottom slider UI.
                    if (controller.isMapInitialized.value) _bottomSliderUI(),
                    // Other Floating Buttons.
                    if (!controller.isMapInitialized.value)
                      Positioned(
                        right: 10,
                        bottom: 100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton(
                              heroTag: 'Profile',
                              onPressed: () =>
                                  Get.dialog(const ProfileDialog()),
                              backgroundColor: Colors.white,
                              child:
                                  const Icon(Icons.person, color: Colors.blue),
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton(
                              heroTag: 'current',
                              onPressed: () => controller.recenterCamera(),
                              backgroundColor: Colors.white,
                              child: const Icon(
                                Icons.location_searching,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton(
                              heroTag: 'recordedJourney',
                              onPressed: () {
                                controller.showJourneyHistory();
                              },
                              backgroundColor: Colors.white,
                              child:
                                  const Icon(Icons.history, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    const Positioned(
                      top: 100,
                      left: 2.0,
                      right: 2.0,
                      child: CompletedUI(),
                    ),
                    // Draggable camera preview overlay (using our newly created widget).
                    if (controller.isCameraActive.value)
                      CameraPreviewDraggable(controller: controller),
                  ],
                ),
              ),
      ),
    );
  }

  topMenu(BuildContext context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.only(bottom: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.grey, blurRadius: 2, spreadRadius: 1.0),
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  const CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.green,
                    child: CircleAvatar(
                        radius: 2.8, backgroundColor: Colors.white),
                  ),
                  Column(
                    children: List.generate(
                        4,
                        (i) => Container(
                              margin: const EdgeInsets.all(2),
                              height: 6,
                              width: 2,
                              decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(5)),
                            )),
                  ),
                  Icon(
                    Icons.location_on_rounded,
                    color: Theme.of(context).primaryColor,
                  )
                ],
              ).paddingOnly(left: 10, bottom: 10, right: 10, top: 17),
              Expanded(
                  child: Container(
                // color: Colors.red,
                child: Column(
                  children: [
                    Container(
                      height: 43,
                      margin: const EdgeInsets.only(top: 10, right: 10),
                      child: PlaceSearchFieldView(
                        //focusNode: currentFocus,
                        readOnly: controller.isFixed.value,
                        boxDecoration: const BoxDecoration(),
                        textEditingController: controller.pickupController,
                        googleAPIKey: controller.apiKey,
                        inputDecoration: placeInputDecoration(
                            hintText: 'Your Location',
                            hintTextColor: Theme.of(context).primaryColor),
                        debounceTime: 800,
                        // countries: [ "in"],
                        isLatLngRequired: true,
                        getPlaceDetailWithLatLng: (Prediction prediction) {
                          controller.pickUpLatLng.value = LatLng(
                              double.parse(prediction.lat ?? '0.0'),
                              double.parse(prediction.lng ?? '0.0'));
                          print("PICKUP_PLACE_CLICKED_DATA=>" +
                              controller.pickUpLatLng.value!.latitude
                                  .toString());
                          controller.closeKeyboard();
                        },
                        itemClick: (Prediction prediction) {
                          controller.pickupController.text =
                              prediction.description!;
                          controller.pickupController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset: prediction.description?.length ?? 0));
                        },
                        onChanged: (String value) {
                          if (value.toString() == '') {
                            // controller.clearRoute();
                            print("PICK_UP_FIELD_VALUE_ERESED");
                          } else {
                            print("PICK_UP_FIELD_VALUE_FIELED");
                          }
                        },
                        clearData: () {},
                        //  clearData: () =>controller.clearRoute(),
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 43,
                      margin: EdgeInsets.only(top: 5, right: 10),
                      child: PlaceSearchFieldView(
                        readOnly: controller.isFixed.value,
                        onChanged: (String value) {
                          if (value.toString() == '') {
                            print("DROP_UP_FIELD_VALUE_ERESED");
                          } else {
                            print("DROP_UP_FIELD_VALUE_FIELED");
                          }
                        },
                        clearData: () /* => controller.clearRoute()*/ {},
                        boxDecoration: const BoxDecoration(),
                        textEditingController: controller.dropController,
                        googleAPIKey: controller.apiKey,
                        inputDecoration:
                            placeInputDecoration(hintText: 'Drop Location'),
                        debounceTime: 800, // default 600 ms,
                        // countries: ["in",],
                        isLatLngRequired:
                            true, // if you required coordinates from place detail
                        getPlaceDetailWithLatLng: (Prediction prediction) {
                          controller.closeKeyboard();
                          print(
                              "DROP_LOCATION=>Latitude=>${prediction.lat}Longitude=>${prediction.lng}");
                          controller.destLatLng.value = LatLng(
                              double.parse(prediction.lat ?? '0.0'),
                              double.parse(
                                  prediction.lng ?? '0.0')); // main line hai
                        },
                        itemClick: (Prediction postalCodeResponse) {
                          print("ITEM_CLICKED=>${postalCodeResponse}");
                          controller.dropController.text =
                              postalCodeResponse.description!;
                          controller.dropController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset:
                                      postalCodeResponse.description?.length ??
                                          0));
                          FocusManager.instance.primaryFocus?.unfocus();
                        }, // this callback is called when isLatLngRequired is true
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      );
  Pointers getRandomPoint() {
    int rnd = math.Random().nextInt(Pointers.values.length);
    return Pointers.values.elementAt(rnd);
  }

  floatingActionsForHazard(context) => SpeedDial(
        key: controller.key,
        invokeAfterClosing: true,
        expandedChild: const Icon(Icons.close),
        backgroundColor: Colors.white,
        expandedBackgroundColor: Colors.grey,
        expandedForegroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: Image.asset(
              'assets/service.png',
              width: 24,
            ),
            label: const Text(
              'Vehicle Repair',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF31706B),
            onPressed: () {
              //Get.to(Example());
              controller.addObstaclePoint(context, Pointers.VEHICLEREPAIR);
            },
          ),
          SpeedDialChild(
            child: Image.asset(
              'assets/accident.png',
              width: 24,
            ),
            label: const Text(
              'Accident',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF4B4D84),
            onPressed: () {
              controller.addObstaclePoint(context, Pointers.ACCIDENT);
            },
          ),

          SpeedDialChild(
            child: Image.asset(
              'assets/obstacle.png',
              width: 24,
            ),
            label: const Text(
              'Constructions',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFD1C24A),
            onPressed: () {
              controller.addObstaclePoint(context, Pointers.CONSTRUCTION);
            },
          ),

          SpeedDialChild(
            child: Image.asset(
              'assets/ic_hospital.png',
              width: 24,
            ),
            label: const Text(
              'Hospital',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            onPressed: () {
              controller.addObstaclePoint(context, Pointers.HOSPITAL);
            },
          ),

          SpeedDialChild(
            child: Image.asset(
              'assets/ic_park.png',
              width: 24,
            ),
            label: const Text(
              'Park',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            onPressed: () {
              controller.addObstaclePoint(context, Pointers.PARK);
            },
          ),
          //
          //
        ],
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      );

  _bottomSliderUI() {
    return Positioned.fill(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          controller.percent = 2 * notification.extent - 0.8;
          return true;
        },
        child: DraggableScrollableSheet(
          maxChildSize: 0.7,
          minChildSize: 0.4,
          initialChildSize: 0.4,
          builder: (BuildContext context, ScrollController scrollController) {
            return Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    alignment: Alignment.topRight,
                    child: FloatingActionButton(
                      heroTag: 'current',
                      onPressed: () {
                        controller.recenterCamera();
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.location_searching,
                          color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // This is adding hazard point button
                  /*     Container(
                    margin: const EdgeInsets.all(10),
                    child: floatingActionsForHazard(context),
                  ),
*/
                  Expanded(
                    child: Material(
                      elevation: 10.0,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20.0),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4.0),
                            Container(
                              height: 4.5,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 150.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: myText(
                                      title:
                                          controller.isSelectedGoTo.value == 0
                                              ? 'Drive'
                                              : 'Walk',
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                Row(
                                  children: [
                                    if (controller.pickUpLatLng.value == null)
                                      Obx(() => controller
                                              .isMapInitialized.value
                                          ? controller.isJourneyStarted.value
                                              ? const SizedBox()
                                              : Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 10),
                                                  height: 35,
                                                  child: myButton(
                                                      radius: 15,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10),
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      onPressed: () {
                                                        controller
                                                                .isJourneyStarted
                                                                .value =
                                                            !controller
                                                                .isJourneyStarted
                                                                .value;
                                                        controller
                                                            .startJourney();
                                                        controller
                                                            .recenterCamera();
                                                      },
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.navigation,
                                                            size: 16,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          myText(
                                                              title: 'Start',
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500),
                                                        ],
                                                      )),
                                                )
                                          : SizedBox())
                                    else
                                      Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        height: 35,
                                        child: myButton(
                                            radius: 15,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10),
                                            color:
                                                Theme.of(context).primaryColor,
                                            onPressed: () {
                                              //controller.isJourneyStarted.value = !controller.isJourneyStarted.value;
                                              controller.previewCamera(0);
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.navigation,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 5),
                                                myText(
                                                    title: 'Preview',
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ],
                                            )),
                                      ),
                                    if (!controller.isFixed.value)
                                      Container(
                                        margin: EdgeInsets.only(right: 10),
                                        height: 35,
                                        width: 35,
                                        child: myButton(
                                            padding: EdgeInsets.zero,
                                            radius: 30,
                                            color:
                                                Theme.of(context).primaryColor,
                                            onPressed: () =>
                                                controller.clearRoute(),
                                            child: Icon(
                                              Icons.clear,
                                              color: Colors.red,
                                            )),
                                      ),
                                    SizedBox(
                                      height: 35,
                                      width: 35,
                                      child: FloatingActionButton(
                                        heroTag: 'Profile',
                                        onPressed: () =>
                                            Get.dialog(const ProfileDialog()),
                                        backgroundColor: Colors.white,
                                        child: const Icon(Icons.person,
                                            color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            // tabs-----------
                            Row(
                              children: [
                                Expanded(
                                    child: InkWell(
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () => controller.onSeletctGoTo(0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.car_repair,
                                            color: controller
                                                        .isSelectedGoTo.value ==
                                                    0
                                                ? Theme.of(context).primaryColor
                                                : Colors.black,
                                          ),
                                          myText(
                                              title: 'Drive',
                                              color: controller.isSelectedGoTo
                                                          .value ==
                                                      0
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      Container(
                                        color:
                                            controller.isSelectedGoTo.value == 0
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey.shade400,
                                        height: 1.5,
                                      )
                                    ],
                                  ),
                                )),
                                Expanded(
                                    child: InkWell(
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () {
                                    controller.onSeletctGoTo(1);
                                    if (Platform.isAndroid) {
                                      CameraHelper.showAwarenessDialog(
                                          context, controller);
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.directions_walk_sharp,
                                            color: controller
                                                        .isSelectedGoTo.value ==
                                                    1
                                                ? Theme.of(context).primaryColor
                                                : Colors.black,
                                          ),
                                          myText(
                                              title: 'Walk',
                                              color: controller.isSelectedGoTo
                                                          .value ==
                                                      1
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      Container(
                                        color:
                                            controller.isSelectedGoTo.value == 1
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey.shade400,
                                        height: 1.5,
                                      )
                                    ],
                                  ),
                                )),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            //LiveDistenceTimeData.value
                            Obx(() => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (controller.isJourneyStarted.value &&
                                        controller.LiveDistenceTimeData.value !=
                                            null)
                                      Row(
                                        children: [
                                          myText(
                                              title:
                                                  "${controller.LiveDistenceTimeData.value['duration']['text']}" /*'${controller.walkingTime.value}'*/,
                                              color: Colors.amber,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 18),
                                          const SizedBox(width: 5),
                                          myText(
                                              title:
                                                  '(${controller.LiveDistenceTimeData.value['distance']['text']})',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black),
                                        ],
                                      )
                                    else
                                      controller.selectedPolylineInfo.value
                                              .isEmpty
                                          ? Align(
                                              alignment: Alignment.topLeft,
                                              child: myText(
                                                  title: 'Loading...',
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 18))
                                          : Row(
                                              children: [
                                                myText(
                                                    title:
                                                        "${controller.selectedPolylineInfo.value['Time']}" /*'${controller.walkingTime.value}'*/,
                                                    color: Colors.amber,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 18),
                                                const SizedBox(width: 5),
                                                myText(
                                                    title:
                                                        '(${controller.selectedPolylineInfo.value['Distance']})',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black),
                                              ],
                                            ),
                                  ],
                                )),

                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.zero,
                                scrollDirection: Axis.vertical,
                                physics: const ScrollPhysics(),
                                controller: scrollController,
                                child: Column(
                                  children: [
                                    Obx(() {
                                      if (controller.selectedPolylineInfo[
                                              'Instructions'] !=
                                          null) {
                                        List InsTRUC = controller
                                            .selectedPolylineInfo
                                            .value['Instructions'];
                                        List steps = InsTRUC.first['steps'];
                                        int currentInstructionIndex = controller
                                            .isCurrentInstructionIndex.value;

                                        return Column(children: [
                                          myText(
                                              title: controller
                                                  .isSelectedPolyLineIndex.value
                                                  .toString(),
                                              fontSize: 1),
                                          ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: steps.length,
                                              itemBuilder: (context, index) {
                                                var dataas = steps[index];
                                                IconData iconData =
                                                    _getIconForInstruction(dataas[
                                                            'html_instructions']
                                                        .toString());
                                                return index <
                                                        currentInstructionIndex
                                                    ? SizedBox()
                                                    : ListTile(
                                                        onTap: () {},
                                                        leading: Icon(iconData),
                                                        title: HtmlWidget(dataas[
                                                                'html_instructions']
                                                            .toString()),
                                                      );
                                              }),
                                        ]);
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.all(100.0),
                                          child: Center(
                                              child: CircularProgressIndicator(
                                                  color: Theme.of(context)
                                                      .primaryColor)),
                                        );
                                      }
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

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
    } else if (instruction.contains('Roundabout') ||
        instruction.contains('Enter the roundabout')) {
      return Icons.sync; // Roundabout-like icon
    } else if (instruction.contains('straight') ||
        instruction.contains('Continue onto')) {
      return Icons.straight; // Continue straight ahead
    } else {
      return Icons.navigation; // Default icon
    }
  }
}
