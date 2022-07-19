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
                      initialPosition: HomePage.kInitialPosition,
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
            initialPosition: HomePage.kInitialPosition,
            pickArea: CircleArea(
              center: HomePage.kInitialPosition,
              radius: 500,
              strokeWidth: 2,
              // fillColor: Colors.red,
              strokeColor: Colors.red,
              validation: true,
            ),
            // useCurrentLocation: true,
            selectInitialPosition: true,
            usePinPointingSearch: true,
            usePlaceDetailSearch: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
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
