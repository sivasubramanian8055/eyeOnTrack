import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

// Import the Status_view widget
import 'status_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JourneyHistoryView extends StatelessWidget {
  final String userId;
  const JourneyHistoryView({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CollectionReference historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Journey History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            color: Colors.black,
            onPressed: () {
              Get.back(); // or Navigator.pop(context);
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef
            .orderBy("journeyStartTime", descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No journeys found."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // Fields stored in Firestore
              final String? journeyDateString = data['journeyDate'];
              final String startLocation =
                  data['journeyStartLocation'] ?? 'Unknown Start';
              final String endLocation =
                  data['journeyEndLocation'] ?? 'Unknown End';
              final String? journeyStartTimeStr = data['journeyStartTime'];
              final String? journeyEndTimeStr = data['journeyEndTime'];
              final String rideType = data['mode'] == 0 ? 'driving' : 'walking';

              // Stats fields (for the Status_view)
              final int totalAwarenessChecks =
                  data['totalAwarenessChecks'] ?? 0;
              final int successfulAwarenessChecks =
                  data['successfulAwarenessChecks'] ?? 0;
              final int partialAwarenessChecks =
                  data['partialAwarenessChecks'] ?? 0;
              final int failedAwarenessChecks =
                  data['failedAwarenessChecks'] ?? 0;
              final int totalJourneySteps = data['totalJourneySteps'] ?? 0;
              final int totalRewardsEarned = data['totalRewardsEarned'] ?? 0;

              // Parse journeyDate (if you want a fallback date)
              DateTime? journeyDate;
              if (journeyDateString != null && journeyDateString.isNotEmpty) {
                try {
                  journeyDate = DateTime.parse(journeyDateString);
                } catch (_) {
                  // parse error, journeyDate remains null
                }
              }

              // Parse journeyStartTime and journeyEndTime as strings
              DateTime? startTime;
              if (journeyStartTimeStr != null &&
                  journeyStartTimeStr.isNotEmpty) {
                try {
                  startTime = DateTime.parse(journeyStartTimeStr);
                } catch (_) {}
              }

              DateTime? endTime;
              if (journeyEndTimeStr != null && journeyEndTimeStr.isNotEmpty) {
                try {
                  endTime = DateTime.parse(journeyEndTimeStr);
                } catch (_) {}
              }

              // Format date/time for display
              String dateString = '';
              if (startTime != null && endTime != null) {
                // If you have both start and end times
                final dateFormat = DateFormat('MMM d, yyyy');
                final timeFormat = DateFormat('h:mm a');
                dateString = "${dateFormat.format(startTime)}, "
                    "${timeFormat.format(startTime)} - "
                    "${timeFormat.format(endTime)}";
              } else if (journeyDate != null) {
                // fallback if you only have journeyDate
                dateString =
                    DateFormat('MMM d, yyyy, h:mm a').format(journeyDate);
              } else {
                dateString = "Unknown Date";
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
                child: Stack(
                  children: [
                    // Main card content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row with date/time + ride type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateString,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                rideType,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(thickness: 1),
                          // Pick-up row using FutureBuilder if needed:
                          Row(
                            children: [
                              const Icon(Icons.radio_button_checked,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Builder(builder: (context) {
                                  // Get the stored journey start data.
                                  final dynamic dataStart =
                                      data['journeyStartLocation'];

                                  // If it's a non-empty string, display it.
                                  if (dataStart is String &&
                                      dataStart.trim().isNotEmpty) {
                                    return Text(
                                      dataStart,
                                      style: const TextStyle(fontSize: 14),
                                    );
                                  }

                                  // If it's a Map, retrieve lat and lng then reverse geocode.
                                  else if (dataStart is Map) {
                                    final double lat = dataStart['lat'] ?? 0.0;
                                    final double lng = dataStart['lng'] ?? 0.0;
                                    final latLng = LatLng(lat, lng);
                                    return FutureBuilder<String>(
                                      future: Get.find<HomeController>()
                                          .getAddressFromLatLng(latLng),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Text(
                                            "Loading address...",
                                            style: TextStyle(fontSize: 14),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return const Text(
                                            "Error loading address",
                                            style: TextStyle(fontSize: 14),
                                          );
                                        }
                                        return Text(
                                          snapshot.data ?? "${lat}, ${lng}",
                                          style: const TextStyle(fontSize: 14),
                                        );
                                      },
                                    );
                                  }

                                  // If journeyStartLocation is not available, try to use the first point from recordedJourney.
                                  else if (data['recordedJourney'] != null &&
                                      (data['recordedJourney'] as List)
                                          .isNotEmpty) {
                                    final firstPoint =
                                        (data['recordedJourney'] as List)[0];
                                    final double lat = firstPoint['lat'] ?? 0.0;
                                    final double lng = firstPoint['lng'] ?? 0.0;
                                    final latLng = LatLng(lat, lng);
                                    return FutureBuilder<String>(
                                      future: Get.find<HomeController>()
                                          .getAddressFromLatLng(latLng),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Text(
                                            "Loading address...",
                                            style: TextStyle(fontSize: 14),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return const Text(
                                            "Error loading address",
                                            style: TextStyle(fontSize: 14),
                                          );
                                        }
                                        return Text(
                                          snapshot.data ?? "${lat}, ${lng}",
                                          style: const TextStyle(fontSize: 14),
                                        );
                                      },
                                    );
                                  }

                                  // Fallback widget if no valid data is available.
                                  return const Text(
                                    "No address available",
                                    style: TextStyle(fontSize: 14),
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Drop-off row (unchanged, or do similar processing if needed)
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  endLocation,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Bottom buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  Get.back();
                                  // Retrieve the recorded journey from the document (assumed stored as a list of maps containing lat/lng).
                                  List<dynamic> recordedJourneyData =
                                      data['recordedJourney'] ?? [];
                                  List<LatLng> journeyPoints =
                                      recordedJourneyData.map((point) {
                                    return LatLng(
                                      (point['lat'] as num).toDouble(),
                                      (point['lng'] as num).toDouble(),
                                    );
                                  }).toList();

                                  // Retrieve the mode (default to 0: driving)
                                  int mode = data['mode'] ?? 0;

                                  // Retrieve origin and destination strings (if empty, displayRecordedJourney will use journeyPoints).
                                  String origin =
                                      data['journeyStartLocation'] is String
                                          ? data['journeyStartLocation']
                                          : "";
                                  String destination =
                                      data['journeyEndLocation'] is String
                                          ? data['journeyEndLocation']
                                          : "";

                                  // Call displayRecordedJourney from HomeController with the appropriate data.
                                  await Get.find<HomeController>()
                                      .displayRecordedJourney(
                                    journeyPoints: journeyPoints,
                                    mode: mode,
                                    origin: origin,
                                    destination: destination,
                                  );

                                  // Close the Journey History view.
                                },
                                child: const Text("View on Map"),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.arrow_drop_down),
                                label: const Text("Stats"),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) {
                                      return Status_view(
                                        totalAwarenessChecks:
                                            totalAwarenessChecks,
                                        successfulAwarenessChecks:
                                            successfulAwarenessChecks,
                                        partialAwarenessChecks:
                                            partialAwarenessChecks,
                                        failedAwarenessChecks:
                                            failedAwarenessChecks,
                                        totalJourneySteps: totalJourneySteps,
                                        totalRewardsEarned: totalRewardsEarned,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Close (X) button at top-right
                    // Positioned(
                    //   top: 0,
                    //   right: 0,
                    //   child: IconButton(
                    //     icon: const Icon(Icons.close),
                    //     onPressed: () async {
                    //       // Example: delete this journey from Firestore
                    //       // If you want a confirmation dialog, show it here first
                    //       await doc.reference.delete();
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
