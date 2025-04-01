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

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final String name = business['name'] ?? 'No Name';
    final String description = business['description'] ?? 'No Description';
    final String phone = business['phone'] ?? 'No Phone';
    final String city = business['city'] ?? 'No City';
    final String category = business['category'] ?? 'No Category';
    final String openingHours = business['opening_hours'] ?? 'N/A';
    final String closingHours = business['closing_hours'] ?? 'N/A';
    final String ownerName = business['owner_name'] ?? 'No Owner Name';
    final String priceRange = business['price_range'] ?? 'No Price Range';
    final String operatingDays =
        business['operating_days'] ?? 'No Operating Days';
    final List<String> imageUrls =
        (business['images'] as List<dynamic>?)?.cast<String>() ?? [];

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
            SizedBox(
              height: 100, // Set a fixed height for the description
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Contact Info
            _InfoCard(
              children: [
                _InfoItem(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: phone,
                ),
                _InfoItem(
                  icon: Icons.location_city,
                  label: 'City',
                  value: city,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Owner Info
            _InfoCard(
              children: [
                _InfoItem(
                  icon: Icons.person,
                  label: 'Owner Name',
                  value: ownerName,
                ),
                _InfoItem(
                  icon: Icons.attach_money,
                  label: 'Price Range',
                  value: priceRange,
                ),
                _InfoItem(
                  icon: Icons.calendar_today,
                  label: 'Operating Days',
                  value: operatingDays,
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
