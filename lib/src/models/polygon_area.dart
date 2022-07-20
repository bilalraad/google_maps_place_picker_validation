import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class PolygonArea extends Polygon {
  final bool validation;
  PolygonArea({
    required this.validation,
    required LatLng center,
    required double radius,
    required List<LatLng> points,
    Color? fillColor,
    Color? strokeColor,
    int strokeWidth = 2,
  }) : super(
          polygonId: PolygonId(const Uuid().v4()),
          fillColor: fillColor ?? Colors.blue.withAlpha(32),
          strokeColor: strokeColor ?? Colors.blue.withAlpha(192),
          points: points,
          strokeWidth: strokeWidth,
        );

  bool checkIsValid(LatLng latLng) {
    // TODO(masreplay): raycasting
    return false;
  }
}
