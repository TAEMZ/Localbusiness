import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Return to dashboard after deletion
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(localization.business_deleted)));
    } catch (e) {
      final localization = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
        'failed  to delete business',
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final String name = business['name'] ?? 'No Name';
    final String description = business['description'] ?? 'No Description';
    final String phone = business['phone'] ?? 'No Phone';
    final String city = business['city'] ?? 'No City';
    final String openingHours = business['opening_hours'] ?? 'N/A';
    final String closingHours = business['closing_hours'] ?? 'N/A';
    final String imageUrl = business['image'] ?? '';

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
                        // Update the business in Firestore
                        await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(business['id'])
                            .update(updatedBusiness);
                        Navigator.pop(context); // Return to details page
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(localization.business_updated)),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to update business: $e')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              deleteBusiness(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image
            imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),

            const SizedBox(height: 20),

            // Business Name
            Text(
              name,
              style:
                  const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              description,
              style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
            ),

            const SizedBox(height: 20),

            // Additional Info
            Text('Phone: $phone', style: const TextStyle(fontSize: 19.0)),
            Text('City: $city', style: const TextStyle(fontSize: 19.0)),
            Text('Hours: $openingHours - $closingHours',
                style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}
