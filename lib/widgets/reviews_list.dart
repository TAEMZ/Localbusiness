import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReviewsList extends StatefulWidget {
  const ReviewsList({super.key});

  @override
  State<ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  late Future<List<Map<String, dynamic>>> _fetchReviews;

  @override
  void initState() {
    super.initState();
    _fetchReviews = _getAllUserReviews();
  }

  // Fetch all reviews from "users/{userId}/reviews"
  Future<List<Map<String, dynamic>>> _getAllUserReviews() async {
    try {
      // Fetch all user documents
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> reviews = [];

      for (var userDoc in usersSnapshot.docs) {
        // Fetch reviews from the user's "reviews" subcollection
        final userReviewsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('reviews')
            .orderBy('created_at', descending: true)
            .get();

        for (var reviewDoc in userReviewsSnapshot.docs) {
          final reviewData = reviewDoc.data();

          // Fetch the associated business details
          final businessId = reviewData['business_id'];
          if (businessId != null) {
            final businessSnapshot = await FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessId)
                .get();

            // Skip reviews where the associated business doesn't exist
            if (businessSnapshot.exists) {
              final businessName =
                  businessSnapshot.data()?['name'] ?? 'Unknown';

              // Add the review data with the business name
              reviews.add({
                'id': reviewDoc.id,
                'businessName': businessName,
                ...reviewData,
              });
            }
          }
        }
      }
      return reviews;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  Widget _buildShimmerLoader() {
    final localization = AppLocalizations.of(context)!;
    return SizedBox(
      height: 150, // Fixed height for horizontal scrolling
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // Number of shimmer placeholders
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      color: Colors.grey[300], // Placeholder for business name
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.grey[300], // Placeholder for reviewer name
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Container(
                          height: 16,
                          width: 16,
                          margin: const EdgeInsets.only(right: 4.0),
                          color: Colors.grey[300], // Placeholder for stars
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 150,
                      color: Colors.grey[300], // Placeholder for comment
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchReviews,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        }
        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(child: Text('No reviews available.'));
        }

        final reviews = snapshot.data!;
        return SizedBox(
          height: 150, // Fixed height for horizontal scrolling
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Name
                      Text(
                        review['businessName'] ?? 'No Business Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Reviewer's Name
                      Text(
                        review['name'] ?? 'Anonymous',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Star Rating
                      Row(
                        children: List.generate(
                          review['rating']?.toInt() ?? 0,
                          (index) => const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Comment
                      Text(
                        review['comment'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
