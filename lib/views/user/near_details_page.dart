import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localbusiness/views/user/location_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/widgets/reviews_dialog.dart';
import 'package:localbusiness/views/user/call_action.dart';
import 'package:localbusiness/views/user/email_action.dart';
import 'package:share_plus/share_plus.dart';
import 'package:localbusiness/views/auth/auth_modal.dart';
import 'package:localbusiness/views/user/sharing_service.dart';

class NearDetailsPage extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final String businessId;
  final String creatorId;

  const NearDetailsPage({
    super.key,
    required this.businessData,
    required this.businessId,
    required this.creatorId,
  });

  @override
  State<NearDetailsPage> createState() => _NearDetailsPageState();
}

class _NearDetailsPageState extends State<NearDetailsPage> {
  late GoogleMapController _mapController;
  LatLng? _userPosition;
  late LatLng _businessPosition;
  final Set<Polyline> _polylines = {};
  bool _isLoading = false;
  String _locationText = "Location";
  int _currentImageIndex = 0;

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
    setState(() => _isLoading = true);
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToMap() {
    if (_userPosition == null || _isLoading) {
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
          userPosition: _userPosition!,
          businessPosition: _businessPosition,
          businessName: widget.businessData['name'],
        ),
      ),
    );
  }

  Future<void> _getUserLocationName() async {
    String name = await LocationUtils.getLocationName(
        _businessPosition.latitude, _businessPosition.longitude);
    setState(() => _locationText = name);
  }

  void _showAuthModal() {
    showDialog(
      context: context,
      builder: (context) => const AuthModal(role: 'user'),
    );
  }

  Future<void> _flagBusiness() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAuthModal();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.flag_business),
        content: Text(AppLocalizations.of(context)!.flag_business_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.flag),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .update({
          'flags': FieldValue.increment(1),
          'flaggedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.creatorId)
            .update({
          'totalFlagsReceived': FieldValue.increment(1),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business flagged successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error flagging business: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null;
    final List<String> imageUrls =
        (widget.businessData['images'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessData['name'] ?? 'Business Details'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          if (imageUrls.isNotEmpty)
            _ImageCarousel(
              imageUrls: imageUrls,
              currentIndex: _currentImageIndex,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
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

          // Business Info Card
          _buildBusinessInfoCard(),

          // Description Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.about,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Text(
                      widget.businessData['description'] ??
                          'No description available.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(thickness: 1, height: 1),

          // Business Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailCard(
                  localization.catagory,
                  widget.businessData['category'] ?? 'No Category',
                ),
                _buildDetailCard(
                  localization.owners_name,
                  widget.businessData['owner_name'] ?? 'No Owner Name',
                ),
                _buildDetailCard(
                  localization.prince_range,
                  widget.businessData['price_range'] ?? 'N/A',
                ),
                _buildDetailCard(
                  localization.operating_days,
                  widget.businessData['operating_days'] ?? 'N/A',
                ),
                _buildDetailCard(
                  localization.opening_hrs,
                  '${widget.businessData['opening_hours'] ?? 'N/A'} - ${widget.businessData['closing_hours'] ?? 'N/A'}',
                ),
                _buildDetailCard(
                  localization.phone,
                  widget.businessData['phone'] ?? 'N/A',
                ),
              ],
            ),
          ),

          const Divider(thickness: 1, height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.call,
                      label: localization.call,
                      color: Colors.green,
                      onPressed: isGuest
                          ? _showAuthModal
                          : () => CallAction.launchCaller(
                              widget.businessData['phone'] ?? ''),
                    ),
                    _buildActionButton(
                      icon: Icons.email,
                      label: localization.email,
                      color: Colors.blue,
                      onPressed: isGuest
                          ? _showAuthModal
                          : () => EmailAction.launchEmail(
                                toEmail: widget.businessData['email'] ?? '',
                                subject:
                                    'Regarding ${widget.businessData['name']}',
                                body: 'Hello, I would like to inquire...',
                              ),
                    ),
                    // In your DetailsPage widget's action button:
                    _buildActionButton(
                      icon: Icons.share,
                      label: localization.share,
                      color: Colors.blueAccent,
                      onPressed: isGuest
                          ? () => _showAuthModal()
                          : () => ShareService.shareBusiness(
                                name: widget.businessData['name'],
                                description: widget.businessData['description'],
                                phone: widget.businessData['phone'],
                                category: widget.businessData['category'],
                                context: context,
                              ),
                    ),
                    _buildActionButton(
                      icon: Icons.rate_review,
                      label: localization.review,
                      color: Colors.orange,
                      onPressed: isGuest
                          ? _showAuthModal
                          : () => showDialog(
                                context: context,
                                builder: (context) =>
                                    ReviewPage(businessId: widget.businessId),
                              ),
                    ),
                    _buildActionButton(
                      icon: Icons.flag,
                      label: localization.flag,
                      color: Colors.red,
                      onPressed: isGuest ? _showAuthModal : _flagBusiness,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildBusinessInfoCard() {
    final localization = AppLocalizations.of(context)!;
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.businessData['category'] ?? 'No category',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationText,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1,
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
                  ? Text(localization.fetching_Directions)
                  : Text(localization.get_directions),
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

  Widget _buildDetailCard(String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 32),
          onPressed: onPressed,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
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
  final LatLng userPosition;
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: userPosition,
          zoom: 12,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('user'),
            position: userPosition,
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
            points: [userPosition, businessPosition],
          )
        },
      ),
    );
  }
}
