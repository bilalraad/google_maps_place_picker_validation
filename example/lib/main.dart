import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_validation/google_maps_place_picker.dart';

// Your api key storage.
import 'keys.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // Light Theme
  final ThemeData lightTheme = ThemeData.light().copyWith(
    // Background color of the FloatingCard
    cardColor: Colors.white,
  );

  // Dark Theme
  final ThemeData darkTheme = ThemeData.dark().copyWith(
    // Background color of the FloatingCard
    cardColor: Colors.grey,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Map Place Picker Demo',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  static const kInitialPosition = LatLng(-33.8567844, 151.213108);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PickResult? selectedPlace;
  bool showGoogleMapInContainer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Map Place Picker Demo"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (!showGoogleMapInContainer)
              ElevatedButton(
                onPressed: onLoadGoogleMapPressed,
                child: const Text("Load Google Map"),
              ),
            !showGoogleMapInContainer
                ? ElevatedButton(
                    child: const Text("Load Google Map in Container"),
                    onPressed: () {
                      setState(() {
                        showGoogleMapInContainer = true;
                      });
                    },
                  )
                : SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: PlacePicker(
                      apiKey: Platform.isAndroid
                          ? APIKeys.androidApiKey
                          : APIKeys.iosApiKey,
                      hintText: "Find a place ...",
                      searchingText: "Please wait ...",
                      selectText: "Select place",
                      outsideOfPickAreaText: "Place not in area",
                      initialCameraPosition: const CameraPosition(
                        target: HomePage.kInitialPosition,
                        zoom: 10,
                      ),
                      useCurrentLocation: true,
                      selectInitialPosition: true,
                      usePinPointingSearch: true,
                      usePlaceDetailSearch: true,
                      zoomGesturesEnabled: true,
                      zoomControlsEnabled: true,
                      onPlacePicked: (PickResult result) {
                        setState(() {
                          selectedPlace = result;
                          showGoogleMapInContainer = false;
                        });
                      },
                      onTapBack: () {
                        setState(() {
                          showGoogleMapInContainer = false;
                        });
                      },
                    ),
                  ),
            selectedPlace == null
                ? Container()
                : Text(selectedPlace?.formattedAddress ?? ""),
          ],
        ),
      ),
    );
  }

  void onLoadGoogleMapPressed() {
    final polygonValidation = PolygonValidation(points: polygon);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PlacePicker(
            apiKey:
                Platform.isAndroid ? APIKeys.androidApiKey : APIKeys.iosApiKey,
            hintText: "Find a place ...",
            searchingText: "Please wait ...",
            selectText: "Select place",
            outsideOfPickAreaText: "Place not in area",
            autocompleteLanguage: "ar",
            initialCameraPosition: polygonValidation.cameraPosition(1),
            onCameraMove: (position) {
              log("zoom-distance ${position.zoom}");
            },
            // circleValidation: CircleValidation(
            //   center: HomePage.kInitialPosition,
            //   radius: 500,
            //   strokeWidth: 2,
            //   strokeColor: Colors.red,
            // ),
            polygonValidation: polygonValidation,
            polylines: {
              Polyline(
                polylineId: const PolylineId("polylineId"),
                points: [
                  polygonValidation.bounds.northeast,
                  polygonValidation.bounds.southwest,
                ],
                color: Colors.red,
                width: 2,
              )
            },
            selectInitialPosition: true,
            usePinPointingSearch: true,
            usePlaceDetailSearch: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            selectedPlaceWidgetBuilder:
                (context, selectedPlace, state, isSearchBarFocused) {
              return SafeArea(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: Text("${selectedPlace?.cleanFormattedText()}"),
                    ),
                  ],
                ),
              );
            },
            onPlacePicked: (PickResult result) {
              setState(() {
                selectedPlace = result;
                Navigator.of(context).pop();
              });
            },
            onMapTypeChanged: (MapType mapType) {
              if (kDebugMode) {
                print("Map type changed to ${mapType.toString()}");
              }
            },
          );
        },
      ),
    );
  }
}

const polygon = [
  LatLng(33.1892128000001, 44.2872734060001),
  LatLng(33.2002716060001, 44.276378631),
  LatLng(33.2033729560002, 44.2729263310002),
  LatLng(33.2046699520002, 44.2710952760002),
  LatLng(33.2064590460001, 44.2673339840001),
  LatLng(33.2102584840002, 44.2573776250001),
  LatLng(33.2151756290002, 44.2473487850001),
  LatLng(33.2174720770001, 44.2435646060001),
  LatLng(33.2188606270001, 44.2418136590001),
  LatLng(33.2219581620001, 44.2385673520001),
  LatLng(33.2253723140001, 44.2356719960002),
  LatLng(33.2272300720001, 44.234462739),
  LatLng(33.235256195, 44.2303085320002),
  LatLng(33.2416992190001, 44.2273979180002),
  LatLng(33.24610138, 44.2257843020001),
  LatLng(33.2531318670001, 44.223487855),
  LatLng(33.2864303580002, 44.223239898),
  LatLng(33.2949752810001, 44.224124907),
  LatLng(33.307971955, 44.2284469600001),
  LatLng(33.3200187690001, 44.2364997870002),
  LatLng(33.330589295, 44.2471084590001),
  LatLng(33.3476104750001, 44.2735061640001),
  LatLng(33.3561286940001, 44.2791290270001),
  LatLng(33.3609695430001, 44.2803001400001),
  LatLng(33.3690719610001, 44.2792663580001),
  LatLng(33.3810920710001, 44.274532319),
  LatLng(33.4095993050001, 44.2576522830001),
  LatLng(33.4246559150002, 44.2518463140001),
  LatLng(33.4339103710001, 44.2549743650001),
  LatLng(33.4382820140001, 44.2567634590001),
  LatLng(33.4465751650001, 44.260803223),
  LatLng(33.4504928580002, 44.26296997),
  LatLng(33.452339172, 44.264190675),
  LatLng(33.4541778560001, 44.2656669610001),
  LatLng(33.4576301580001, 44.268917084),
  LatLng(33.4777107240001, 44.2892341610002),
  LatLng(33.4828491220001, 44.2941513060002),
  LatLng(33.4846878060001, 44.2956161500001),
  LatLng(33.4865341200001, 44.296829224),
  LatLng(33.496452332, 44.302070617),
  LatLng(33.5003471370002, 44.3044471740001),
  LatLng(33.5037689220001, 44.3073310860001),
  LatLng(33.5123519900001, 44.3159790040002),
  LatLng(33.5073928840001, 44.3304061900002),
  LatLng(33.49497223, 44.3537483210002),
  LatLng(33.4874839790001, 44.3634033210002),
  LatLng(33.4579086310001, 44.39496231),
  LatLng(33.4510726930001, 44.4040451060002),
  LatLng(33.443943024, 44.4163780210002),
  LatLng(33.4391250610001, 44.4284515390002),
  LatLng(33.4359321590001, 44.4409370420001),
  LatLng(33.4344711300001, 44.4560737610001),
  LatLng(33.4352149970001, 44.4713592530001),
  LatLng(33.4381408690001, 44.48619461),
  LatLng(33.4496650700001, 44.5185775750001),
  LatLng(33.4505920410002, 44.5269279490001),
  LatLng(33.4484214790002, 44.539276123),
  LatLng(33.4453048700001, 44.5455284130001),
  LatLng(33.438835144, 44.5526771550001),
  LatLng(33.4303169250002, 44.5568466180002),
  LatLng(33.416515351, 44.559314729),
  LatLng(33.4012718200001, 44.55928421),
  LatLng(33.3856086730001, 44.5569267270001),
  LatLng(33.3723678600001, 44.5529327400002),
  LatLng(33.3428649900001, 44.5400047290001),
  LatLng(33.3237686150002, 44.532905579),
  LatLng(33.307228088, 44.529781342),
  LatLng(33.2989768980001, 44.5299415600002),
  LatLng(33.2966346740002, 44.5312576290001),
  LatLng(33.28705597, 44.5267677310002),
  LatLng(33.2780876170001, 44.524307251),
  LatLng(33.203392029, 44.5127754210001),
  LatLng(33.188316345, 44.5065765380002),
  LatLng(33.1841926570001, 44.5035552980001),
  LatLng(33.180969239, 44.4990272520001),
  LatLng(33.1828269960001, 44.4900894170001),
  LatLng(33.1810913090002, 44.4520111080002),
  LatLng(33.1813278200001, 44.3559608450001),
  LatLng(33.1831321720002, 44.338874817),
  LatLng(33.1899909970001, 44.3111534130001),
  LatLng(33.1911239620001, 44.302383422),
  LatLng(33.1906509400002, 44.2910766600002),
  LatLng(33.1892128000001, 44.2872734060001),
];
