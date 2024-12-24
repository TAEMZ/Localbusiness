import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localbusiness/views/user/details_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/widgets/locale_provider.dart';
import 'package:provider/provider.dart';

class UserBusinessCard extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final VoidCallback? onRemove; // Callback to handle removal (optional)

  const UserBusinessCard({
    super.key,
    required this.businessData,
    this.onRemove,
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

      final docId =
          widget.businessData['id']; // Firestore document ID for the business
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
    final String imageUrl = widget.businessData['image'] ?? '';
    final String businessId = widget.businessData['id'] ?? '';

    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsPage(businessId: businessId),
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
                      setState(
                          () {}); // Trigger a UI update to instantly reflect removal
                    }
                  },
                  tooltip: 'Remove',
                ),
              ),

            // Business Image
            imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
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
