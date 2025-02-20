import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../App/helper/app_paths.dart';
import '../App/models/near_places_model.dart';
import '../app_controller.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  AppController appController = Get.find<AppController>();

  final String _apiKey = 'AIzaSyCy6TbAdJKairdnqz6Wvh3qcv1rypGW-Wo';
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  List<dynamic> _places = [];

  @override
  void initState() {
    super.initState();
    _getNearbyPlaces();
  }

  Future<void> _getNearbyPlaces() async {
    LatLng? lng = LatLng(appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.longitude ?? 0.0);

    print('API_INITIATED');
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lng.latitude},${lng.longitude}&radius=1500&type=restaurant&key=$_apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("NEAR_PLACES_ALL_DATA=>${data['results']}");

      if (data['results'] != null) {
        print("NEAR_PLACES=>${data['results'].length}");
        setState(() {
          _markers.clear();
          _places = data['results'];
          for (var result in data['results']) {
            _markers.add(
              Marker(
                markerId: MarkerId(result['place_id']),
                position: LatLng(
                  result['geometry']['location']['lat'],
                  result['geometry']['location']['lng'],
                ),
                infoWindow: InfoWindow(
                  title: result['name'],
                  snippet: result['vicinity'],
                ),
              ),
            );
          }
        });
      } else {
        print("No results found");
      }
    } else {
      throw Exception('Failed to load nearby places');
    }
    initiateApi();
  }

  List<Results> Places = [];

  initiateApi() {
    LatLng? lng = LatLng(appController.currentPosition.value?.latitude ?? 0.0,
        appController.currentPosition.value?.longitude ?? 0.0);
    nearPlaceApi(position: lng).then((onValue) {
      if (onValue.status) {
        setState(() {
          NearPlaceModel myModel = onValue.data;
          Places = myModel.results!;
          print("place_api_response${Places.length}");
        });
      } else {
        print("GOOGLE_PLACE_API_EXCEPTION=>${onValue.message}");
        EasyLoading.showToast(onValue.message.toString());
      }
    });
  }

  String extractImageUrl(String photoReference) {
    String url =
        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=500&photoreference=$photoReference&key=$_apiKey';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Places'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  appController.currentPosition.value?.latitude ?? 0.0,
                  appController.currentPosition.value?.longitude ?? 0.0),
              zoom: 14.0,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                      spreadRadius: 5.0,
                    ),
                  ],
                ),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: Places.length,
                  itemBuilder: (BuildContext context, int index) {
                    var place = Places[index];
                    return placeCard(
                        place); /*ListTile(
                      leading:SizedBox(height: 50,width: 50,
                          child: ImageView(photoUrl: place.icon.toString(),)),


                      // Image.network(
                      //   extractImageUrl(place.photos!.first.photoReference.toString()),
                      //   width: 50,
                      //   height: 50,
                      //   fit: BoxFit.cover,
                      // ),

                      title: Text(place.name.toString()),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.vicinity.toString()),
                          if (place.rating != null)
                            Text('Rating: ${place.rating}'),
                          if (place.userRatingsTotal != null)
                            Text('Total Ratings: ${place.userRatingsTotal}'),
                        ],
                      ),
                      onTap: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(
                              place.geometry?.location?.lat,
                              place.geometry?.location?.lng,
                          */ /*    place['geometry']['location']['lat'],
                              place['geometry']['location']['lng'],*/ /*
                            ),
                          ),
                        );
                      },
                    );*/
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  placeCard(Results place) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1.5,
                blurRadius: 2.5)
          ]),
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1.5,
                            blurRadius: 2.5)
                      ]),
                  child: ImageView(
                    photoUrl: place.icon.toString(),
                  )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  myText(
                      title: place.name.toString(),
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                  if (place.rating != null)
                    Row(
                      children: [
                        myText(
                            title: 'Rating: ${place.rating} ',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black45),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 13,
                        )
                      ],
                    ),
                ],
              )
            ],
          ),
          SizedBox(height: 5),
          SizedBox(
            height: 250,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                // width: MediaQuery.of(context).size.width,
                child: ImageView(
                  photoUrl: extractImageUrl(
                      place.photos!.first.photoReference.toString()),
                  boxFit: BoxFit.cover,
                )),
          ),
          myText(
                  title: '${place.vicinity}',
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 14)
              .paddingOnly(left: 15, top: 5, right: 5),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}
