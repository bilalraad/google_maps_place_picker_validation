// ignore_for_file: no_leading_underscores_for_library_prefixes
// ignore: library_prefixes

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_validation/src/models/pick_result.dart';
import 'package:google_maps_place_picker_validation/src/place_picker.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:location/location.dart' as _location;
import 'package:provider/provider.dart';

class PlaceProvider extends ChangeNotifier {
  PlaceProvider(
    String apiKey,
    String? proxyBaseUrl,
    Client? httpClient,
    Map<String, dynamic> apiHeaders,
  ) {
    places = GoogleMapsPlaces(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );

    geocoding = GoogleMapsGeocoding(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );
  }

  static PlaceProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<PlaceProvider>(context, listen: listen);

  late GoogleMapsPlaces places;
  late GoogleMapsGeocoding geocoding;
  String? sessionToken;
  bool isOnUpdateLocationCooldown = false;
  LocationAccuracy? desiredAccuracy;
  bool isAutoCompleteSearching = false;

  // _location.Location location = _location.Location();
  PermissionStatus permissionGranted = PermissionStatus.denied;
  bool isLocationServiceEnabled = false;

  Future<void> updateCurrentLocation(bool forceAndroidLocationManager) async {
    final status = await requestLocationPermission();

    isLocationServiceEnabled = status.isGranted || status.isLimited;

    if (!isLocationServiceEnabled) {
      final permission = await Geolocator.requestPermission();
      isLocationServiceEnabled = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!isLocationServiceEnabled) {
        return;
      }
    }
    permissionGranted = await requestLocationPermission();
    try {
      permissionGranted = await requestLocationPermission();

      if (permissionGranted == PermissionStatus.granted) {
        currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: desiredAccuracy ?? LocationAccuracy.best);
      } else {
        currentPosition = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      currentPosition = null;
    }

    notifyListeners();
  }

  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;
  set currentPosition(Position? newPosition) {
    _currentPosition = newPosition;
    notifyListeners();
  }

  Timer? _debounceTimer;
  Timer? get debounceTimer => _debounceTimer;
  set debounceTimer(Timer? timer) {
    _debounceTimer = timer;
    notifyListeners();
  }

  CameraPosition? _previousCameraPosition;
  CameraPosition? get prevCameraPosition => _previousCameraPosition;
  setPrevCameraPosition(CameraPosition? prePosition) {
    _previousCameraPosition = prePosition;
  }

  CameraPosition? _currentCameraPosition;
  CameraPosition? get cameraPosition => _currentCameraPosition;
  setCameraPosition(CameraPosition? newPosition) {
    _currentCameraPosition = newPosition;
  }

  PickResult? _selectedPlace;
  PickResult? get selectedPlace => _selectedPlace;
  set selectedPlace(PickResult? result) {
    _selectedPlace = result;
    notifyListeners();
  }

  SearchingState _placeSearchingState = SearchingState.Idle;
  SearchingState get placeSearchingState => _placeSearchingState;
  set placeSearchingState(SearchingState newState) {
    _placeSearchingState = newState;
    notifyListeners();
  }

  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;
  set mapController(GoogleMapController? controller) {
    _mapController = controller;
    notifyListeners();
  }

  PinState _pinState = PinState.Preparing;
  PinState get pinState => _pinState;
  set pinState(PinState newState) {
    _pinState = newState;
    notifyListeners();
  }

  bool _isSearchBarFocused = false;
  bool get isSearchBarFocused => _isSearchBarFocused;
  set isSearchBarFocused(bool focused) {
    _isSearchBarFocused = focused;
    notifyListeners();
  }

  MapType _mapType = MapType.normal;
  MapType get mapType => _mapType;
  setMapType(MapType mapType, {bool notify = false}) {
    _mapType = mapType;
    if (notify) notifyListeners();
  }

  switchMapType() {
    _mapType = MapType.values[(_mapType.index + 1) % MapType.values.length];
    if (_mapType == MapType.none) _mapType = MapType.normal;

    notifyListeners();
  }
}
