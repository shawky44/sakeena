import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerLocationService {
  static const double _countryRefreshDistanceMeters = 25000;

  Future<bool> refreshCachedLocation({required bool fromBackground}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      if (fromBackground && permission != LocationPermission.always) {
        return false;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 0,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final oldLat = prefs.getDouble('cached_lat');
      final oldLon = prefs.getDouble('cached_lon');
      final movedDistance = oldLat == null || oldLon == null
          ? double.infinity
          : Geolocator.distanceBetween(
              oldLat,
              oldLon,
              position.latitude,
              position.longitude,
            );

      String? country = prefs.getString('cached_country');
      if (country == null || movedDistance >= _countryRefreshDistanceMeters) {
        try {
          final places = await geo.placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (places.isNotEmpty) {
            final place = places.first;
            country = place.country?.trim();
            final locality = place.locality?.trim().isNotEmpty == true
                ? place.locality!.trim()
                : place.subAdministrativeArea?.trim();
            final locationName = [locality, country]
                .whereType<String>()
                .where((part) => part.isNotEmpty)
                .join(' - ');
            if (locationName.isNotEmpty) {
              await prefs.setString('cached_location', locationName);
            }
          }
        } catch (error) {
          debugPrint('Background reverse geocoding failed: $error');
        }
      }

      await prefs.setDouble('cached_lat', position.latitude);
      await prefs.setDouble('cached_lon', position.longitude);
      if (country != null && country.isNotEmpty) {
        await prefs.setString('cached_country', country);
      }
      await prefs.setString(
        'cached_location_updated_at',
        DateTime.now().toUtc().toIso8601String(),
      );
      return true;
    } catch (error) {
      debugPrint('Background location refresh failed: $error');
      return false;
    }
  }
}
