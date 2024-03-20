// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/places.dart';

class PickResult {
  PickResult({
    this.placeId,
    this.geometry,
    this.formattedAddress,
    this.types,
    this.addressComponents,
    this.adrAddress,
    this.formattedPhoneNumber,
    this.id,
    this.reference,
    this.icon,
    this.name,
    this.openingHours,
    this.photos,
    this.internationalPhoneNumber,
    this.priceLevel,
    this.rating,
    this.scope,
    this.url,
    this.vicinity,
    this.utcOffset,
    this.website,
    this.reviews,
  });

  final String? placeId;
  final Geometry? geometry;
  final String? formattedAddress;
  final List<String>? types;
  final List<AddressComponent>? addressComponents;

  // Below results will not be fetched if 'usePlaceDetailSearch' is set to false (Defaults to false).
  final String? adrAddress;
  final String? formattedPhoneNumber;
  final String? id;
  final String? reference;
  final String? icon;
  final String? name;
  final OpeningHoursDetail? openingHours;
  final List<Photo>? photos;
  final String? internationalPhoneNumber;
  final PriceLevel? priceLevel;
  final num? rating;
  final String? scope;
  final String? url;
  final String? vicinity;
  final num? utcOffset;
  final String? website;
  final List<Review>? reviews;

  LatLng? get latLng {
    return geometry?.location == null
        ? null
        : LatLng(geometry!.location.lat, geometry!.location.lng);
  }

  String cleanFormattedText({String separator = " - "}) {
    final list = formattedAddress?.split(" ");
    list?.removeWhere((element) => element.contains("+"));
    final newValue = list
        ?.map((e) => e.replaceAll(",", "").replaceAll("،", "").trim())
        .toList();
    return newValue?.join(separator) ?? "";
  }

  factory PickResult.fromGeocodingResult(GeocodingResult result) {
    return PickResult(
      placeId: result.placeId,
      geometry: result.geometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
    );
  }

  factory PickResult.fromLatLang(LatLng result) {
    return PickResult(
      geometry: Geometry(
        location: Location(
          lat: result.latitude,
          lng: result.longitude,
        ),
      ),
    );
  }

  factory PickResult.fromPlaceDetailResult(PlaceDetails result) {
    return PickResult(
      placeId: result.placeId,
      geometry: result.geometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
      adrAddress: result.adrAddress,
      formattedPhoneNumber: result.formattedPhoneNumber,
      id: result.id,
      reference: result.reference,
      icon: result.icon,
      name: result.name,
      openingHours: result.openingHours,
      photos: result.photos,
      internationalPhoneNumber: result.internationalPhoneNumber,
      priceLevel: result.priceLevel,
      rating: result.rating,
      scope: result.scope,
      url: result.url,
      vicinity: result.vicinity,
      utcOffset: result.utcOffset,
      website: result.website,
      reviews: result.reviews,
    );
  }

  @override
  String toString() {
    return 'PickResult(placeId: $placeId, geometry: $geometry, formattedAddress: $formattedAddress, types: $types, addressComponents: $addressComponents, adrAddress: $adrAddress, formattedPhoneNumber: $formattedPhoneNumber, id: $id, reference: $reference, icon: $icon, name: $name, openingHours: $openingHours, photos: $photos, internationalPhoneNumber: $internationalPhoneNumber, priceLevel: $priceLevel, rating: $rating, scope: $scope, url: $url, vicinity: $vicinity, utcOffset: $utcOffset, website: $website, reviews: $reviews)';
  }
}
