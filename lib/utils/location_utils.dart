import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationUtils {
  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      int meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  /// Get the center point between two coordinates
  static LatLng getCenterPoint(LatLng point1, LatLng point2) {
    double lat = (point1.latitude + point2.latitude) / 2;
    double lng = (point1.longitude + point2.longitude) / 2;
    return LatLng(lat, lng);
  }

  /// Get bounds that include two points with padding
  static LatLngBounds getBoundsWithPadding(LatLng point1, LatLng point2,
      {double paddingFactor = 0.1}) {
    double minLat = min(point1.latitude, point2.latitude);
    double maxLat = max(point1.latitude, point2.latitude);
    double minLng = min(point1.longitude, point2.longitude);
    double maxLng = max(point1.longitude, point2.longitude);

    // Calculate padding
    double latPadding = (maxLat - minLat) * paddingFactor;
    double lngPadding = (maxLng - minLng) * paddingFactor;

    // Apply padding
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Convert GeoPoint to LatLng
  static LatLng geoPointToLatLng(GeoPoint geoPoint) {
    return LatLng(geoPoint.latitude, geoPoint.longitude);
  }

  /// Convert LatLng to GeoPoint
  static GeoPoint latLngToGeoPoint(LatLng latLng) {
    return GeoPoint(latLng.latitude, latLng.longitude);
  }

  /// Get estimated travel time based on distance (very simplistic approach)
  static String getEstimatedTravelTime(double distanceInKm) {
    // Assuming average speed of 40 km/h in city, 80 km/h outside
    double averageSpeed = distanceInKm < 10 ? 40 : 80;
    double timeInHours = distanceInKm / averageSpeed;

    if (timeInHours < 1 / 60) {
      return 'Less than a minute';
    } else if (timeInHours < 1) {
      int minutes = (timeInHours * 60).round();
      return '$minutes mins';
    } else {
      int hours = timeInHours.floor();
      int minutes = ((timeInHours - hours) * 60).round();

      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes mins';
      }
    }
  }

  /// Generate a static map URL for a route between two points
  static String getStaticMapUrl(LatLng origin, LatLng destination,
      {String apiKey = 'YOUR_API_KEY'}) {
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?size=600x300'
        '&markers=color:green%7C${origin.latitude},${origin.longitude}'
        '&markers=color:red%7C${destination.latitude},${destination.longitude}'
        '&path=color:0x0000ff%7Cweight:5%7C${origin.latitude},${origin.longitude}%7C${destination.latitude},${destination.longitude}'
        '&key=$apiKey';
  }
}
