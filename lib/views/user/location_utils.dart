import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationUtils {
  static Future<bool> isLocationAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final locationEnabled = prefs.getBool('isLocationEnabled') ?? true;

    if (!locationEnabled) return false;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<Position> getUserLocationWithChecks() async {
    if (!await isLocationAvailable()) {
      throw Exception('Location services disabled by user');
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String> getLocationName(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print(place);

        // Build a more detailed address
        String address = [
          place.name, // Place name (if available)
          place.street, // Street name
          place.subAdministrativeArea,
          place.subLocality, // District
          place.locality, // City
          place.administrativeArea, // State/Region
          place.country // Country
        ]
            .where((element) =>
                element != null &&
                element != "B51" &&
                element.length < 15 &&
                element.isNotEmpty)
            .join(', ');

        return address.isNotEmpty ? address : 'Unknown Location';
      }
    } catch (e) {
      print('Error fetching location name: $e');
    }
    return 'Unknown Location';
  }
} // Inside consts.dart
