import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_business_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

class FilteredBusinessPage extends StatelessWidget {
  final String category;

  const FilteredBusinessPage({super.key, required this.category});

  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<List<Map<String, dynamic>>> _fetchBusinessesByCategory() async {
    try {
      final userLocation = await _getUserLocation();
      final snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('category', isEqualTo: category)
          .get();

      final businesses = snapshot.docs.map((doc) {
        final data = doc.data();
        final businessLocation = data['location'] as Map<String, dynamic>;
        final businessLat = businessLocation['latitude'] as double;
        final businessLon = businessLocation['longitude'] as double;

        final distance = calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          businessLat,
          businessLon,
        );

        return {
          'id': doc.id,
          ...data,
          'distance': distance, // Add distance to the business data
        };
      }).toList();

      // Filter businesses within a certain distance (e.g., 10 km)
      const maxDistance = 10000; // 10 km in meters
      final nearbyBusinesses = businesses.where((business) {
        return business['distance'] <= maxDistance;
      }).toList();

      debugPrint(
          'Fetched ${nearbyBusinesses.length} nearby businesses for category: $category');

      return nearbyBusinesses;
    } catch (e) {
      debugPrint('Error fetching businesses: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBusinessesByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Center(child: Text(localization.no_business));
          }

          final businesses = snapshot.data!;
          return ListView.builder(
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              return UserBusinessCard(
                businessData: business,
                onRemove: () {},
                distance: business['distance'], // Add logic if necessary
              );
            },
          );
        },
      ),
    );
  }
}
