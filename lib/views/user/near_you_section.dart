import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localbusiness/views/user/near_details_page.dart';
import 'package:shimmer/shimmer.dart';
// Import the new details page
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NearYouSection extends StatefulWidget {
  const NearYouSection({super.key});

  @override
  State<NearYouSection> createState() => _NearYouSectionState();
}

class _NearYouSectionState extends State<NearYouSection> {
  late Future<List<Map<String, dynamic>>> _nearbyBusinesses;

  @override
  void initState() {
    super.initState();
    _nearbyBusinesses = _getNearbyBusinesses();
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      final localization = AppLocalizations.of(context)!;
      throw Exception(localization.location_Prompt);
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<Map<String, dynamic>>> _getNearbyBusinesses() async {
    try {
      final userLocation = await _getUserLocation();

      final snapshot =
          await FirebaseFirestore.instance.collection('businesses').get();

      List<Map<String, dynamic>> businesses = snapshot.docs.map((doc) {
        final data = doc.data();
        final double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          data['location']['latitude'],
          data['location']['longitude'],
        );

        return {
          'id': doc.id,
          ...data,
          'distance': distance,
        };
      }).toList();

      businesses.sort((a, b) => a['distance'].compareTo(b['distance']));

      return businesses
          .where((business) => business['distance'] <= 30000)
          .toList();
    } catch (e) {
      debugPrint('Error fetching businesses: $e');
      return [];
    }
  }

  Widget _buildShimmerLoader() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      width: 150,
                      color: Colors.grey[300],
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Loading...',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _nearbyBusinesses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        }
        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(child: Text('No businesses found nearby.'));
        }

        final businesses = snapshot.data!;
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];

              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NearDetailsPage(businessData: business),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        business['image'] != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12.0)),
                                child: Image.network(
                                  business['image'],
                                  height: 100,
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                height: 100,
                                width: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 50),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            business['name'] ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${(business['distance'] / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
