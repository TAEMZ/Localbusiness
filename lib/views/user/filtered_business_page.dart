import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'user_business_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:localbusiness/widgets/location_provider.dart'; // Adjust the path if needed

class FilteredBusinessPage extends StatelessWidget {
  final String category;
  final bool isCustomCategory;

  const FilteredBusinessPage({
    super.key,
    required this.category,
    this.isCustomCategory = false,
  });

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<List<Map<String, dynamic>>> _loadNearbyBusinesses(
      LocationProvider localProvider) async {
    final userLocation = await localProvider.getLocation();
    final querySnapshot =
        await FirebaseFirestore.instance.collection('businesses').get();

    const maxDistance = 10000.0;
    const predefinedCategories = [
      'Restaurant',
      'Hairdresser',
      'Bar',
      'Delivery',
      'Coffee',
      'Shopping',
      'Fitness',
      'Health',
      'Beauty',
      'Entertainment',
    ];

    return querySnapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final businessCategory = data['category'];
          if (businessCategory == null) return false;

          return isCustomCategory
              ? !predefinedCategories.contains(businessCategory)
              : businessCategory == category;
        })
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final location = data['location'] as Map<String, dynamic>?;
          if (location == null) return null;

          final distance = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            location['latitude'],
            location['longitude'],
          );

          if (distance > maxDistance) return null;

          return {
            'id': doc.id,
            ...data,
            'distance': distance,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final localProvider = Provider.of<LocationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadNearbyBusinesses(localProvider),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitWave(
                color: Color.fromARGB(255, 133, 128, 128),
                size: 50.0,
              ),
            );
          }

          if (snapshot.hasError || snapshot.data?.isEmpty == true) {
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
                distance: business['distance'],
              );
            },
          );
        },
      ),
    );
  }
}
