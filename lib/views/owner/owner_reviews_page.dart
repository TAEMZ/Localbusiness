import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OwnerReviewsPage extends StatefulWidget {
  const OwnerReviewsPage({super.key});

  @override
  State<OwnerReviewsPage> createState() => _OwnerReviewsPageState();
}

class _OwnerReviewsPageState extends State<OwnerReviewsPage> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchOwnerReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchOwnerReviews() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      debugPrint('User is not logged in.');
      return [];
    }

    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('reviews')
          .where('reviewedId', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        debugPrint('No reviews found for user with ID: $userId');
        return [];
      }

      List<Map<String, dynamic>> reviews = [];

      for (var reviewDoc in reviewsSnapshot.docs) {
        final reviewData = reviewDoc.data();
        String businessName = 'Unknown Business';

        try {
          final businessSnapshot = await FirebaseFirestore.instance
              .collection('businesses')
              .doc(reviewData['business_id'])
              .get();

          if (businessSnapshot.exists) {
            businessName =
                businessSnapshot.data()?['name'] ?? 'Unknown Business';
          } else {
            debugPrint(
                'Business document with ID ${reviewData['business_id']} does not exist.');
          }
        } catch (e) {
          debugPrint('Error fetching business details: $e');
        }

        reviews.add({
          'reviewId': reviewDoc.id,
          ...reviewData,
          'businessName': businessName,
        });
      }

      debugPrint('Fetched ${reviews.length} reviews for user.');
      return reviews;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          title: Text(localization.user_reviews),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('An error occurred: ${snapshot.error}'),
              );
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return Center(child: Text(localization.no_reviews));
            }

            return ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final double rating = review['rating']?.toDouble() ?? 0.0;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['businessName'] ?? localization.no_business,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Text(
                              localization.rating,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            _buildStarRating(rating),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          review['comment'] ?? localization.no_comment,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Reviewer: ${review['name'] ?? localization.unknown}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ));
  }

  /// Helper method to build star rating widgets
  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index == fullStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }
}
