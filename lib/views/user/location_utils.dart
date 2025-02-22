import 'package:geocoding/geocoding.dart';

class LocationUtils {
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
}
