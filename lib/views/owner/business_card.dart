import 'package:flutter/material.dart';

class BusinessCard extends StatelessWidget {
  final Map<String, dynamic> businessData;
  final bool showExtras; // Determines if extras (favorites & share) are shown

  const BusinessCard({
    super.key,
    required this.businessData,
    this.showExtras = false, // Default to false for owner page
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        businessData['image'] ?? ''; // Firebase URL or empty string
    final String name = businessData['name'] ?? 'No Name';
    final String description = businessData['description'] ?? 'No Description';
    final String phone = businessData['phone'] ?? 'No Phone';
    final String city = businessData['city'] ?? 'No City';
    final String openingHours = businessData['opening_hours'] ?? 'N/A';
    final String closingHours = businessData['closing_hours'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      elevation: 6.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16.0)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 200, // Increased height for better visibility
                    width: double.infinity, // Full width
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
          ),

          // Display the business details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Name
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 22.0, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8.0),

                // Business Description
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
                ),

                Divider(height: 20.0, color: Colors.grey[300]),

                // Additional Info (Phone, City, Hours)
                Text(
                  'Phone: $phone',
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                ),
                Text(
                  'City: $city',
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                ),
                Text(
                  'Hours: $openingHours - $closingHours',
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                ),

                // Extras for user page
                if (showExtras)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            // TODO: Add to favorites
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // TODO: Implement share functionality
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
