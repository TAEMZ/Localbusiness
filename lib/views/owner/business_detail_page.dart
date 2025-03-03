import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'business_form.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BusinessDetailPage extends StatelessWidget {
  final Map<String, dynamic> business;

  const BusinessDetailPage({super.key, required this.business});

  Future<void> deleteBusiness(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(business['id'])
          .delete();
      Navigator.pop(context);
      final localization = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(localization.business_deleted)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete business')),
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  Future<void> _launchMap(double latitude, double longitude) async {
    final Uri mapUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': '$latitude,$longitude',
      },
    );
    if (await canLaunch(mapUri.toString())) {
      await launch(mapUri.toString());
    } else {
      throw 'Could not launch $mapUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final String name = business['name'] ?? 'No Name';
    final String description = business['description'] ?? 'No Description';
    final String phone = business['phone'] ?? 'No Phone';
    final String city = business['city'] ?? 'No City';
    final String address = business['address'] ?? 'No Address';
    final String category = business['category'] ?? 'No Category';
    final String openingHours = business['opening_hours'] ?? 'N/A';
    final String closingHours = business['closing_hours'] ?? 'N/A';
    final List<String> imageUrls =
        (business['images'] as List<dynamic>?)?.cast<String>() ?? [];
    final double? latitude = business['location']?['latitude'];
    final double? longitude = business['location']?['longitude'];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessForm(
                      business: business,
                      onSubmit: (updatedBusiness) async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('businesses')
                              .doc(business['id'])
                              .update(updatedBusiness);

                          if (context.mounted) {
                            // ✅ Check if context is still valid before popping
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(localization.business_updated)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to update business: $e')),
                            );
                          }
                        }
                      }),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => deleteBusiness(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (imageUrls.isNotEmpty)
              _ImageCarousel(imageUrls: imageUrls)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),

            const SizedBox(height: 20),

            // Business Name
            Text(
              name,
              style:
                  const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // Category
            Text(
              category,
              style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 20),

            // Description
            Text(
              description,
              style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
            ),

            const SizedBox(height: 20),

            // Contact Info
            _InfoCard(
              children: [
                _InfoItem(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: phone,
                  onTap: () => _launchPhone(phone),
                ),
                _InfoItem(
                  icon: Icons.map,
                  label: 'Location',
                  value: 'View on Map',
                  onTap: () {
                    if (latitude != null && longitude != null) {
                      _launchMap(latitude, longitude);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Business Hours
            _InfoCard(
              children: [
                _InfoItem(
                  icon: Icons.access_time,
                  label: 'Opening Hours',
                  value: openingHours,
                ),
                _InfoItem(
                  icon: Icons.access_time,
                  label: 'Closing Hours',
                  value: closingHours,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _ImageCarousel({required this.imageUrls});

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image Carousel
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    widget.imageUrls[index],
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
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
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

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 14.0)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16.0)),
      onTap: onTap,
    );
  }
}
