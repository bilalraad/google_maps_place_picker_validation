import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

final Map<int, double> scalesZoomsLevel = {
  // 0: 591657550.500000,
  1: 295828775.300000,
  2: 147914387.600000,
  3: 73957193.820000,
  4: 36978596.910000,
  5: 18489298.450000,
  6: 9244649.227000,
  7: 4622324.614000,
  8: 2311162.307000,
  9: 1155581.153000,
  10: 577790.576700,
  11: 288895.288400,
  12: 144447.644200,
  13: 72223.822090,
  14: 36111.911040,
  15: 18055.955520,
  16: 9027.977761,
  17: 4513.988880,
  18: 2256.994440,
  // 19: 1128.497220,
};

double distanceToZoom(double distance) {
  // 591657550.500000 / 2^(zoom) = distance
  final zoom = log(591657550.500000 / distance);
  return zoom + 1;
}

double distanceToGreatestZoom(double distance) {
  double zoom = 1;
  scalesZoomsLevel.forEach(
    (zoomLevel, scale) {
      if (distance <= scale) {
        zoom = zoomLevel.toDouble();
      }
    },
  );
  return zoom - 3;
}

double distanceBetween(LatLng start, LatLng end) {
  final startLatitude = start.latitude;
  final startLongitude = start.longitude;

  final endLatitude = end.latitude;
  final endLongitude = end.longitude;

  const earthRadius = 6378137.0;
  final dLat = _toRadians(end.latitude - startLatitude);
  final dLon = _toRadians(endLongitude - startLongitude);

  final a = pow(sin(dLat / 2), 2) +
      pow(sin(dLon / 2), 2) *
          cos(_toRadians(startLatitude)) *
          cos(_toRadians(endLatitude));
  final c = 2 * asin(sqrt(a));

  return earthRadius * c;
}

double _toRadians(double degree) {
  return degree * pi / 180;
}
