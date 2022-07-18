import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class CircleArea extends Circle {
  final bool validation;
  CircleArea({
    required this.validation,
    required LatLng center,
    required double radius,
    Color? fillColor,
    Color? strokeColor,
    int strokeWidth = 2,
  })  : assert(radius >= 0, "radius must be greater than zero"),
        super(
          circleId: CircleId(const Uuid().v4()),
          center: center,
          radius: radius,
          fillColor: fillColor ?? Colors.blue.withAlpha(32),
          strokeColor: strokeColor ?? Colors.blue.withAlpha(192),
          strokeWidth: strokeWidth,
        );

  bool checkIsValid(LatLng latLng) {
    final distance = Geolocator.distanceBetween(
      center.latitude,
      center.longitude,
      latLng.latitude,
      latLng.longitude,
    );

    if (kDebugMode) {
      log("distance $distance: $center, $radius: $latLng");
    }
    return distance <= radius;
  }
}
