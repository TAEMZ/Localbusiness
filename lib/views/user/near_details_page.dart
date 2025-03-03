import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localbusiness/views/user/location_utils.dart';

class NearDetailsPage extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const NearDetailsPage({super.key, required this.businessData});

  @override
  State<NearDetailsPage> createState() => _NearDetailsPageState();
}

class _NearDetailsPageState extends State<NearDetailsPage> {
  late GoogleMapController _mapController;
  LatLng? _userPosition;
  late LatLng _businessPosition;
  final Set<Polyline> _polylines = {};
  bool _isLoading = false; // Add a loading state
  String _locationText = "Location";
  int _currentImageIndex = 0; // Track current image index for carousel

  @override
  void initState() {
    super.initState();
    _businessPosition = LatLng(
      widget.businessData['location']['latitude'],
      widget.businessData['location']['longitude'],
    );
    _getUserLocation();
    _getUserLocationName();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  void _navigateToMap() {
    if (_userPosition == null || _isLoading) {
      // Show a message if location is not ready
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please wait while we fetch your location...')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MapPage(
          userPosition: _userPosition,
          businessPosition: _businessPosition,
          businessName: widget.businessData['name'],
        ),
      ),
    );
  }

  Future<void> _getUserLocationName() async {
    if (_businessPosition != null) {
      String name = await LocationUtils.getLocationName(
          _businessPosition.latitude, _businessPosition.longitude);
      setState(() {
        _locationText = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls =
        (widget.businessData['images'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessData['name'] ?? 'Business Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Carousel
          if (imageUrls.isNotEmpty)
            _ImageCarousel(
              imageUrls: imageUrls,
              currentIndex: _currentImageIndex,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            )
          else
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 100),
              ),
            ),

          // Business Details Card
          _buildDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.businessData['name'] ?? 'Unknown Business',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1, // Limit to a single line
              overflow: TextOverflow.ellipsis, // Truncate if too long
            ),
            const SizedBox(height: 8),
            Text(
              widget.businessData['description'] ?? 'No description available.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  // Ensure content does not overflow
                  child: Text(
                    _locationText,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1, // Prevent overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _navigateToMap,
              icon: const Icon(Icons.directions),
              label: _isLoading
                  ? const Text('Fetching Directions...')
                  : const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: _isLoading ? FontWeight.normal : FontWeight.bold,
                ),
                backgroundColor: _isLoading ? Colors.grey[300] : Colors.blue,
                foregroundColor: _isLoading ? Colors.grey : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final List<String> imageUrls;
  final int currentIndex;
  final Function(int) onPageChanged;

  const _ImageCarousel({
    required this.imageUrls,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image Carousel
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: imageUrls.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // Dots Indicator
        if (imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex == index
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapPage extends StatelessWidget {
  final LatLng? userPosition;
  final LatLng businessPosition;
  final String? businessName;

  const _MapPage({
    required this.userPosition,
    required this.businessPosition,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(businessName ?? 'Directions'),
      ),
      body: userPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userPosition!,
                zoom: 12,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('user'),
                  position: userPosition!,
                  infoWindow: const InfoWindow(title: 'Your Location'),
                ),
                Marker(
                  markerId: const MarkerId('business'),
                  position: businessPosition,
                  infoWindow: InfoWindow(title: businessName),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.blue,
                  width: 5,
                  points: [userPosition!, businessPosition],
                )
              },
            ),
    );
  }
}
