import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:localbusiness/views/user/near_details_page.dart';
import 'dart:async';

class NearYouSection extends StatefulWidget {
  final String businessId;
  const NearYouSection({super.key, required this.businessId});

  @override
  State<NearYouSection> createState() => _NearYouSectionState();
}

class _NearYouSectionState extends State<NearYouSection> {
  late Future<List<Map<String, dynamic>>> _nearbyBusinesses;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _nearbyBusinesses = _getNearbyBusinesses();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_scrollController.hasClients || _isUserScrolling) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      _scrollController.animateTo(
        currentScroll >= maxScroll ? 0 : currentScroll + 150,
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onScrollStart() {
    _isUserScrolling = true;
    _autoScrollTimer?.cancel();
  }

  void _onScrollEnd() {
    _isUserScrolling = false;
    _startAutoScroll();
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      bool enableService = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content:
              const Text('Enable location services to see nearby businesses.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enable')),
          ],
        ),
      );

      if (enableService == true) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled)
          throw Exception('Location services are still disabled.');
      } else {
        throw Exception('Location services are required.');
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      bool openSettings = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'Location permissions are permanently denied. Open settings to enable.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings')),
          ],
        ),
      );

      if (openSettings == true) {
        await Geolocator.openAppSettings();
        permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          throw Exception('Location permission still denied.');
        }
      } else {
        throw Exception('Location permission required.');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<Map<String, dynamic>>> _getNearbyBusinesses() async {
    try {
      final userLocation = await _getUserLocation();
      final snapshot =
          await FirebaseFirestore.instance.collection('businesses').get();

      List<Map<String, dynamic>> businesses = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>?;

        if (location == null) continue;

        final double businessLat = location['latitude'] ?? 0.0;
        final double businessLng = location['longitude'] ?? 0.0;

        final double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          businessLat,
          businessLng,
        );

        businesses.add({
          'id': doc.id,
          ...data,
          'distance': distance,
        });
      }

      businesses.sort((a, b) => a['distance'].compareTo(b['distance']));
      return businesses.where((b) => b['distance'] <= 5000).toList();
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
        itemCount: 10,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 100, width: 150, color: Colors.grey[300]),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Loading...', style: TextStyle(fontSize: 14)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('...', style: TextStyle(fontSize: 12)),
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) _onScrollStart();
        if (notification is ScrollEndNotification) _onScrollEnd();
        return true;
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _nearbyBusinesses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return _buildShimmerLoader();
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No businesses found nearby.',
                    style: TextStyle(color: Colors.grey)));
          }

          final businesses = snapshot.data!;
          return SizedBox(
            height: 200,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final business = businesses[index];
                final List<String> imageUrls =
                    (business['images'] as List<dynamic>?)?.cast<String>() ??
                        [];

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 3.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NearDetailsPage(
                            businessData: business,
                            businessId: business['id'],
                            creatorId: business['creatorId'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrls.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: PageView.builder(
                                itemCount: imageUrls.length,
                                itemBuilder: (context, imgIndex) {
                                  return ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12.0)),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrls[imgIndex],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image,
                                              size: 50)),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                  Icons.broken_image,
                                                  size: 50)),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 50)),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              business['name'] ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "${(business['distance'] / 1000).toStringAsFixed(1)} km away",
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
      ),
    );
  }
}
