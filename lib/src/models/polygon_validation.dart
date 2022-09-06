import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_validation/src/models/shape_validation.dart';
import 'package:map_utils/polygon_extension.dart';
import 'package:uuid/uuid.dart';

class PolygonValidation extends Polygon implements ShapeValidation {
  @override
  final bool validation;

  PolygonValidation({
    required List<LatLng> points,
    Color? fillColor,
    Color? strokeColor,
    int strokeWidth = 2,
    this.validation = true,
  })  : assert(points.length >= 2),
        super(
          polygonId: PolygonId(const Uuid().v4()),
          fillColor: fillColor ?? Colors.blue.withAlpha(32),
          strokeColor: strokeColor ?? Colors.blue.withAlpha(192),
          points: points,
          strokeWidth: strokeWidth,
        );

  Polygon copyWithValidation({
    bool? validation,
  }) {
    return PolygonValidation(
      points: points,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      validation: validation ?? this.validation,
    );
  }

  @override
  bool checkIsValid(LatLng point) {
    return contains(point);
  }

  @override
  bool checkIsNotValid(LatLng point) {
    return !checkIsValid(point);
  }

  @override
  LatLng get center => getCenter;
}
