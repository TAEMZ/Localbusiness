import 'package:flutter/material.dart';

class BusinessCard extends StatelessWidget {
  final Map<String, dynamic> businessData;
  final bool showExtras;

  const BusinessCard({
    super.key,
    required this.businessData,
    this.showExtras = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls =
        (businessData['images'] as List<dynamic>?)?.cast<String>() ?? [];
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
          // Image Carousel with Dots Indicator
          if (imageUrls.isNotEmpty)
            _ImageCarousel(imageUrls: imageUrls)
          else
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 50, color: Colors.grey),
            ),

          // Business Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 22.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
                ),
                Divider(height: 20.0, color: Colors.grey[300]),
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
