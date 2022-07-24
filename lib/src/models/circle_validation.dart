import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_validation/src/models/shape_validation.dart';
import 'package:uuid/uuid.dart';

class CircleValidation extends Circle implements ShapeValidation {
  final bool validation;
  CircleValidation({
    required LatLng center,
    required double radius,
    Color? fillColor,
    Color? strokeColor,
    int strokeWidth = 2,
    this.validation = true,
  })  : assert(radius > 0, "radius must be greater than zero"),
        super(
          circleId: CircleId(const Uuid().v4()),
          center: center,
          radius: radius,
          fillColor: fillColor ?? Colors.blue.withAlpha(32),
          strokeColor: strokeColor ?? Colors.blue.withAlpha(192),
          strokeWidth: strokeWidth,
        );

  @override
  bool checkIsValid(LatLng point) {
    final distance = Geolocator.distanceBetween(
      center.latitude,
      center.longitude,
      point.latitude,
      point.longitude,
    );
    bool valid = distance <= radius;

    return valid;
  }

  @override
  bool checkIsNotValid(LatLng point) {
    return !checkIsValid(point);
  }
}
