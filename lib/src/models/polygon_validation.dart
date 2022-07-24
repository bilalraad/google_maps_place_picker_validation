import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_validation/src/models/shape_validation.dart';
import 'package:google_maps_place_picker_validation/src/scales_zoom_level.dart';
import 'package:uuid/uuid.dart';

LatLngBounds farthestBounds(List<LatLng> list) {
  assert(list.length > 2);
  double? x0, y0, x1, y1;
  for (LatLng latLng in list) {
    if (x0 == null) {
      x0 = x1 = latLng.latitude;
      y0 = y1 = latLng.longitude;
    } else {
      if (latLng.latitude > x1!) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1!) y1 = latLng.longitude;
      if (latLng.longitude < y0!) y0 = latLng.longitude;
    }
  }
  return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
}

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

  @override
  bool checkIsValid(LatLng point) {
    return checkIfValidMarker(point);
  }

  @override
  bool checkIsNotValid(LatLng point) {
    return !checkIsValid(point);
  }

  @override
  LatLng get center {
    return calculateCenter();
  }
}

class Path {
  final LatLng a;
  final LatLng b;

  Path(this.a, this.b);
}

extension PolygonExtension on Polygon {
  int get edgesCount => points.length - 1;

  List<LatLng> get vertices => points;

  Path getPath(int i) {
    return Path(vertices[i], vertices[i + 1]);
  }

  LatLngBounds get bounds => farthestBounds(points);

  CameraPosition cameraPosition(double padding) => CameraPosition(
        target: calculateCenter(),
        zoom: distanceToZoom(
          distanceBetween(bounds.northeast, bounds.southwest),
        ),
      );

  CameraUpdate cameraUpdate(double padding) =>
      CameraUpdate.newLatLngBounds(bounds, padding);

  LatLng calculateCenter() {
    final longitudes = points.map((i) => i.longitude).toList();
    final latitudes = points.map((i) => i.latitude).toList();

    latitudes.sort();
    longitudes.sort();

    final lowX = latitudes.first;
    final highX = latitudes.last;
    final lowY = longitudes.first;
    final highY = longitudes.last;

    final centerX = lowX + ((highX - lowX) / 2);
    final centerY = lowY + ((highY - lowY) / 2);

    return LatLng(centerX, centerY);
  }

  bool checkIfValidMarker(LatLng point) {
    int intersectCount = 0;

    for (int i = 0; i < edgesCount; i++) {
      if (rayCastIntersect(point, getPath(i))) {
        intersectCount++;
      }
    }

    return (intersectCount % 2) == 1; // odd = inside, even = outside;
  }

  bool rayCastIntersect(LatLng point, Path path) {
    double x1 = path.a.longitude;
    double y1 = path.a.latitude;

    double x2 = path.b.longitude;
    double y2 = path.b.latitude;

    double x3 = point.longitude;
    double y3 = point.latitude;

    // a and b can't both be above or below y3, and a or b must be east of x3
    if ((y1 > y3 && y2 > y3) || (y1 < y3 && y2 < y3) || (x1 < x3 && x2 < x3)) {
      return false;
    }

    final double m = (y1 - y2) / (x1 - x2); // Rise over run
    final double y = (-x1) * m + y1; // y = mx + b
    final double x = (y3 - y) / m; // algebra is neat!

    return x > x3;
  }
}
