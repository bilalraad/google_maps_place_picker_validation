import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_validation/google_maps_place_picker.dart';
import 'package:google_maps_place_picker_validation/providers/place_provider.dart';
import 'package:google_maps_place_picker_validation/src/components/animated_pin.dart';
import 'package:google_maps_place_picker_validation/src/models/shape_validation.dart';
import 'package:google_maps_place_picker_validation/utils/position_extension.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

typedef SelectedPlaceWidgetBuilder = Widget Function(
  BuildContext context,
  PickResult? selectedPlace,
  SearchingState state,
  bool isSearchBarFocused,
);

typedef PinBuilder = Widget Function(
  BuildContext context,
  PinState state,
);

class GoogleMapPlacePicker extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final GlobalKey appBarKey;

  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final Widget Function()? notSelectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;

  final ValueChanged<String>? onSearchFailed;
  final VoidCallback? onMoveStart;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onToggleMapType;
  final VoidCallback? onMyLocation;
  final ValueChanged<PickResult>? onPlacePicked;

  final int? debounceMilliseconds;
  final bool? enableMapTypeButton;
  final bool? enableMyLocationButton;

  final bool usePinPointingSearch;
  final bool? usePlaceDetailSearch;
  final bool? useGeocoding;

  final bool? selectInitialPosition;

  final String? language;

  final Circle? circlePin;

  final CircleValidation? circleValidation;

  final PolygonValidation? polygonValidation;

  final bool? forceSearchOnZoomChanged;
  final bool hidePlaceDetailsWhenDraggingPin;

  final Set<Circle> circles;

  final Set<Polygon> polygons;

  final Set<Polyline> polylines;

  /// GoogleMap pass-through events:
  final Function(PlaceProvider)? onCameraMoveStarted;
  final CameraPositionCallback? onCameraMove;
  final Function(CameraPosition? cameraPosition)? onCameraIdle;

  // strings
  final String? selectText;
  final String? outsideOfPickAreaText;

  /// Zoom feature toggle
  final bool zoomGesturesEnabled;
  final bool zoomControlsEnabled;

  const GoogleMapPlacePicker({
    Key? key,
    required this.initialCameraPosition,
    required this.appBarKey,
    required this.usePinPointingSearch,
    required this.hidePlaceDetailsWhenDraggingPin,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.enableMyLocationButton,
    this.onToggleMapType,
    this.onMyLocation,
    this.onPlacePicked,
    this.usePlaceDetailSearch,
    this.useGeocoding,
    this.selectInitialPosition,
    this.language,
    this.circleValidation,
    this.polygonValidation,
    this.forceSearchOnZoomChanged,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.selectText,
    this.outsideOfPickAreaText,
    this.circlePin,
    this.zoomGesturesEnabled = true,
    this.zoomControlsEnabled = false,
    this.circles = const {},
    this.polygons = const {},
    this.polylines = const {},
    this.notSelectedPlaceWidgetBuilder,
  })  : assert(polygonValidation == null || circleValidation == null),
        super(key: key);

  @override
  State<GoogleMapPlacePicker> createState() => _GoogleMapPlacePickerState();
}

class _GoogleMapPlacePickerState extends State<GoogleMapPlacePicker> {
  Circle? _circlePin;

  @override
  void initState() {
    super.initState();
    _circlePin = widget.circlePin;
  }

  _searchByCameraLocation(PlaceProvider provider) async {
    // We don't want to search location again if camera location is changed by zooming in/out.
    if (widget.forceSearchOnZoomChanged == false &&
        provider.prevCameraPosition != null &&
        provider.prevCameraPosition!.target.latitude ==
            provider.cameraPosition!.target.latitude &&
        provider.prevCameraPosition!.target.longitude ==
            provider.cameraPosition!.target.longitude) {
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }
    if (!widget.useGeocoding!) {
      provider.selectedPlace =
          PickResult.fromLatLang(provider.cameraPosition!.target);
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    provider.placeSearchingState = SearchingState.Searching;

    final response = await provider.geocoding.searchByLocation(
      Location(
        lat: provider.cameraPosition!.target.latitude,
        lng: provider.cameraPosition!.target.longitude,
      ),
      language: widget.language,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      provider.placeSearchingState = SearchingState.Idle;
      if (kDebugMode) {
        print("Camera Location Search Error: ${response.errorMessage!}");
      }
      widget.onSearchFailed?.call(response.status);

      return;
    }

    if (!widget.usePlaceDetailSearch!) {
      provider.selectedPlace =
          PickResult.fromGeocodingResult(response.results[0]);
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    final PlacesDetailsResponse detailResponse =
        await provider.places.getDetailsByPlaceId(
      response.results[0].placeId,
      language: widget.language,
    );

    if (detailResponse.errorMessage?.isNotEmpty == true ||
        detailResponse.status == "REQUEST_DENIED") {
      if (kDebugMode) {
        print(
          "Fetching details by placeId Error: ${detailResponse.errorMessage!}",
        );
      }
      if (widget.onSearchFailed != null) {
        widget.onSearchFailed!(detailResponse.status);
      }
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    provider.selectedPlace =
        PickResult.fromPlaceDetailResult(detailResponse.result);
    provider.placeSearchingState = SearchingState.Idle;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildGoogleMap(context),
        _buildPin(),
        _buildFloatingCard(),
        _buildMapIcons(context),
        _buildZoomButtons(),
      ],
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    return Selector<PlaceProvider, Tuple2<MapType, CameraPosition?>>(
      selector: (_, provider) => Tuple2(
        provider.mapType,
        provider.cameraPosition,
      ),
      builder: (_, data, __) {
        PlaceProvider provider = PlaceProvider.of(context, listen: false);

        return GoogleMap(
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          zoomControlsEnabled:
              false, // we use our own implementation that supports iOS as well, see _buildZoomButtons()
          myLocationButtonEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          initialCameraPosition: widget.initialCameraPosition,
          minMaxZoomPreference: const MinMaxZoomPreference(null, 16),
          mapType: data.item1,
          myLocationEnabled: true,
          circles: <Circle>{
            if (widget.circleValidation != null) widget.circleValidation!,
            if (provider.cameraPosition != null && widget.circlePin != null)
              widget.circlePin!.copyWith(centerParam: data.item2!.target),
            ...widget.circles
          },
          polygons: <Polygon>{
            if (widget.polygonValidation != null) widget.polygonValidation!,
            ...widget.polygons
          },
          polylines: widget.polylines,
          onMapCreated: (GoogleMapController controller) {
            provider.mapController = controller;
            provider.setCameraPosition(null);
            provider.pinState = PinState.Idle;

            // When select initialPosition set to true.
            if (widget.selectInitialPosition!) {
              provider.setCameraPosition(widget.initialCameraPosition);
              _searchByCameraLocation(provider);
            }

            if (widget.onMapCreated != null) {
              widget.onMapCreated!(controller);
            }
          },
          onCameraIdle: () {
            if (provider.isAutoCompleteSearching) {
              provider.isAutoCompleteSearching = false;
              provider.pinState = PinState.Idle;
              provider.placeSearchingState = SearchingState.Idle;
              return;
            }

            _circlePin = _circlePin?.copyWith(
              centerParam: provider.currentPosition?.latLng,
            );

            if (widget.circleValidation != null ||
                widget.polygonValidation != null) {
              final isNotValid = _checkLocationValidation(provider);

              if (isNotValid) return;
            }

            // Perform search only if the setting is to true.
            if (widget.usePinPointingSearch) {
              // Search current camera location only if camera has moved (dragged) before.
              if (provider.pinState == PinState.Dragging) {
                // Cancel previous timer.
                if (provider.debounceTimer?.isActive ?? false) {
                  provider.debounceTimer!.cancel();
                }

                provider.debounceTimer = Timer(
                    Duration(milliseconds: widget.debounceMilliseconds!), () {
                  _searchByCameraLocation(provider);
                });
              }
            }

            provider.pinState = PinState.Idle;

            if (widget.onCameraIdle != null) {
              widget.onCameraIdle!(provider.cameraPosition);
            }
          },
          onCameraMoveStarted: () {
            if (widget.onCameraMoveStarted != null) {
              widget.onCameraMoveStarted!(provider);
            }

            provider.setPrevCameraPosition(provider.cameraPosition);

            // Cancel any other timer.
            provider.debounceTimer?.cancel();

            // Update state, dismiss keyboard and clear text.
            provider.pinState = PinState.Dragging;

            // Begins the search state if the hide details is enabled
            if (widget.hidePlaceDetailsWhenDraggingPin) {
              provider.placeSearchingState = SearchingState.Searching;
            }

            widget.onMoveStart!();
          },
          onCameraMove: (CameraPosition position) {
            provider.setCameraPosition(position);

            if (widget.onCameraMove != null) {
              widget.onCameraMove!(position);
            }
          },

          // gestureRecognizers make it possible to navigate the map when it's a
          // child in a scroll view e.g ListView, SingleChildScrollView...
          gestureRecognizers: {
            Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer())
          },
        );
      },
    );
  }

  bool _checkLocationValidation(PlaceProvider provider) {
    bool isValid = false;

    final location = provider.cameraPosition?.target;
    if (location == null) return false;

    ShapeValidation? validator =
        widget.circleValidation ?? widget.polygonValidation;
    if (validator != null && validator.validation) {
      isValid = validator.checkIsNotValid(location);
      if (isValid) {
        provider.mapController?.animateCamera(
          CameraUpdate.newLatLng(validator.center),
        );
      }
    }

    return isValid;
  }

  Widget _buildPin() {
    return IgnorePointer(
      child: Center(
        child: Selector<PlaceProvider, PinState>(
          selector: (_, provider) => provider.pinState,
          builder: (context, state, __) {
            if (widget.pinBuilder == null) {
              return _defaultPinBuilder(context, state);
            } else {
              return Builder(
                builder: (builderContext) =>
                    widget.pinBuilder!(builderContext, state),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _defaultPinBuilder(BuildContext context, PinState state) {
    if (state == PinState.Preparing) {
      return Container();
    } else if (state == PinState.Idle) {
      return Stack(
        children: <Widget>[
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.place, size: 36, color: Colors.red),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: <Widget>[
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedPin(
                  child: Icon(Icons.place, size: 36, color: Colors.red),
                ),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFloatingCard() {
    return Selector<PlaceProvider,
        Tuple4<PickResult?, SearchingState, bool, PinState>>(
      selector: (_, provider) => Tuple4(
        provider.selectedPlace,
        provider.placeSearchingState,
        provider.isSearchBarFocused,
        provider.pinState,
      ),
      builder: (context, data, __) {
        if ((data.item1 == null && data.item2 == SearchingState.Idle) ||
            data.item3 == true ||
            data.item4 == PinState.Dragging &&
                widget.hidePlaceDetailsWhenDraggingPin) {
          return widget.notSelectedPlaceWidgetBuilder?.call() ?? Container();
        } else {
          if (widget.selectedPlaceWidgetBuilder == null) {
            return _defaultPlaceWidgetBuilder(context, data.item1, data.item2);
          } else {
            return Builder(
                builder: (builderContext) => widget.selectedPlaceWidgetBuilder!(
                    builderContext, data.item1, data.item2, data.item3));
          }
        }
      },
    );
  }

  Widget _buildZoomButtons() {
    return Selector<PlaceProvider, Tuple2<GoogleMapController?, LatLng?>>(
      selector: (_, provider) => Tuple2<GoogleMapController?, LatLng?>(
          provider.mapController, provider.cameraPosition?.target),
      builder: (context, data, __) {
        if (!widget.zoomControlsEnabled ||
            data.item1 == null ||
            data.item2 == null) {
          return Container();
        } else {
          return Positioned(
            bottom: 50,
            right: 10,
            child: Card(
              elevation: 2,
              child: SizedBox(
                width: 40,
                height: 100,
                child: Column(
                  children: <Widget>[
                    IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          double currentZoomLevel =
                              await data.item1!.getZoomLevel();
                          currentZoomLevel = currentZoomLevel + 2;
                          data.item1!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: data.item2!,
                                zoom: currentZoomLevel,
                              ),
                            ),
                          );
                        }),
                    const SizedBox(height: 2),
                    IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          double currentZoomLevel =
                              await data.item1!.getZoomLevel();
                          currentZoomLevel = currentZoomLevel - 2;
                          if (currentZoomLevel < 0) currentZoomLevel = 0;
                          data.item1!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: data.item2!,
                                zoom: currentZoomLevel,
                              ),
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _defaultPlaceWidgetBuilder(
      BuildContext context, PickResult? data, SearchingState state) {
    return FloatingCard(
      bottomPosition: MediaQuery.of(context).size.height * 0.1,
      leftPosition: MediaQuery.of(context).size.width * 0.15,
      rightPosition: MediaQuery.of(context).size.width * 0.15,
      width: MediaQuery.of(context).size.width * 0.7,
      borderRadius: BorderRadius.circular(12.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: state == SearchingState.Searching
          ? _buildLoadingIndicator()
          : _buildSelectionDetails(context, data!),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildSelectionDetails(BuildContext context, PickResult result) {
    final canBePicked = widget.circleValidation?.checkIsValid(result.latLng!) ??
        widget.polygonValidation?.checkIsValid(result.latLng!) ??
        true;

    MaterialStateColor buttonColor = MaterialStateColor.resolveWith(
      (states) => canBePicked ? Colors.lightGreen : Colors.red,
    );

    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Text(
            result.formattedAddress!,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          (canBePicked && (widget.selectText?.isEmpty ?? true)) ||
                  (!canBePicked &&
                      (widget.outsideOfPickAreaText?.isEmpty ?? true))
              ? SizedBox.fromSize(
                  size: const Size(56, 56), // button width and height
                  child: ClipOval(
                    child: Material(
                      child: InkWell(
                        overlayColor: buttonColor,
                        onTap: () {
                          if (canBePicked) {
                            widget.onPlacePicked!(result);
                          }
                        },
                        child: Icon(
                          canBePicked
                              ? Icons.check_sharp
                              : Icons.app_blocking_sharp,
                          color: buttonColor,
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox.fromSize(
                  size: Size(MediaQuery.of(context).size.width * 0.8,
                      56), // button width and height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Material(
                      child: InkWell(
                        overlayColor: buttonColor,
                        onTap: () {
                          if (canBePicked) {
                            widget.onPlacePicked!(result);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canBePicked
                                  ? Icons.check_sharp
                                  : Icons.app_blocking_sharp,
                              color: buttonColor,
                            ),
                            SizedBox.fromSize(size: const Size(10, 0)),
                            Text(
                              canBePicked
                                  ? widget.selectText!
                                  : widget.outsideOfPickAreaText!,
                              style: TextStyle(
                                color: buttonColor,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMapIcons(BuildContext context) {
    final RenderBox appBarRenderBox =
        widget.appBarKey.currentContext!.findRenderObject() as RenderBox;

    return Positioned(
      top: appBarRenderBox.size.height,
      right: 15,
      child: Column(
        children: <Widget>[
          widget.enableMapTypeButton!
              ? SizedBox(
                  width: 35,
                  height: 35,
                  child: RawMaterialButton(
                    shape: const CircleBorder(),
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white,
                    elevation: 8.0,
                    onPressed: widget.onToggleMapType,
                    child: const Icon(Icons.layers),
                  ),
                )
              : Container(),
          const SizedBox(height: 10),
          widget.enableMyLocationButton!
              ? SizedBox(
                  width: 35,
                  height: 35,
                  child: RawMaterialButton(
                    shape: const CircleBorder(),
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white,
                    elevation: 8.0,
                    onPressed: widget.onMyLocation,
                    child: const Icon(Icons.my_location),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
