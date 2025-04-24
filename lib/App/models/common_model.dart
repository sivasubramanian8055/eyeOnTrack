import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteSummery {
  final DirectionsRoute route;
  Map<String, dynamic> hazardPoint;
  final List<LatLng> path;
  final int minDist;

  RouteSummery({
    required this.route,
    required this.hazardPoint,
    required this.minDist,
    required this.path,
  });
}

class HazardSorted {
  final Map<String, dynamic> hazardPoint;
  double distance;
  HazardSorted({required this.hazardPoint, required this.distance});
}
