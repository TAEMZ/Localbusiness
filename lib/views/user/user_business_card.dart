import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localbusiness/views/user/details_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/widgets/locale_provider.dart';
import 'package:provider/provider.dart';

class UserBusinessCard extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final VoidCallback? onRemove;
  final double? distance;

  const UserBusinessCard({
    super.key,
    required this.businessData,
    this.onRemove,
    this.distance,
  });

  @override
  _UserBusinessCardState createState() => _UserBusinessCardState();
}

class _UserBusinessCardState extends State<UserBusinessCard> {
  bool isFavorite = false;
  bool isBookmarked = false;

  Future<void> _addToCollection(String collection) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final docId = widget.businessData['id'];
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(collection);

      final existingDoc = await collectionRef.doc(docId).get();
      if (!existingDoc.exists) {
        await collectionRef.doc(docId).set(widget.businessData);
        debugPrint('$collection: Added ${widget.businessData['name']}');
      } else {
        debugPrint('$collection: Already exists');
      }
    } catch (e) {
      debugPrint('Failed to add to $collection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    final String name = widget.businessData['name'] ?? 'No Name';
    final String description =
        widget.businessData['description'] ?? 'No Description';
    final List<String> imageUrls =
        (widget.businessData['images'] as List<dynamic>?)?.cast<String>() ?? [];
    final String businessId = widget.businessData['id'] ?? '';
    final String creatorId = widget.businessData['creatorId'];

    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailsPage(businessId: businessId, creatorId: creatorId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.onRemove != null)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    if (widget.onRemove != null) {
                      widget.onRemove!();
                      setState(() {});
                    }
                  },
                  tooltip: 'Remove',
                ),
              ),

            // Image Carousel
            if (imageUrls.isNotEmpty)
              _ImageCarousel(imageUrls: imageUrls)
            else
              Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),

            // Business Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (widget.distance != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${(widget.distance! / 1000).toStringAsFixed(1)} km away',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10.0),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                          _addToCollection('favorites');
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.blue : null,
                        ),
                        onPressed: () {
                          setState(() {
                            isBookmarked = !isBookmarked;
                          });
                          _addToCollection('bookmarks');
                        },
                      ),
                    ],
                  ),
                ],
              ),
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
          height: 150,
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
