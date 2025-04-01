import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localbusiness/widgets/reviews_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import your ReviewPage

class MyReviews extends StatefulWidget {
  const MyReviews({super.key});

  @override
  State<MyReviews> createState() => _MyReviewsState();
}

class _MyReviewsState extends State<MyReviews> {
  Future<List<Map<String, dynamic>>> _fetchUserReviews() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reviews')
          .orderBy('created_at', descending: true)
          .get();

      List<Map<String, dynamic>> reviews = [];
      for (var doc in snapshot.docs) {
        final reviewData = doc.data();
        final businessId = reviewData['business_id'];

        if (businessId != null) {
          final businessSnapshot = await FirebaseFirestore.instance
              .collection('businesses')
              .doc(businessId)
              .get();

          // Skip this review if the business doesn't exist
          if (businessSnapshot.exists) {
            final businessName = businessSnapshot.data()?['name'] ?? 'Unknown';

            reviews.add({
              'id': doc.id,
              'businessName': businessName,
              ...reviewData,
            });
          }
        }
      }
      return reviews;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );

      setState(() {}); // Refresh after deletion
    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
  }

  void _editReview(Map<String, dynamic> review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPage(
          businessId: review['business_id'], // Pass business ID
          reviewData: review, // Pass review data to populate fields
        ),
      ),
    ).then((_) {
      setState(() {}); // Refresh the page when returning from ReviewPage
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localization.my_reviews)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SpinKitWave(
              color:
                  Colors.black, // Or use Theme.of(context).colorScheme.primary
              size: 50.0,
            ));
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Center(child: Text(localization.no_reviews));
          }

          final reviews = snapshot.data!;
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];

              return Card(
                margin: const EdgeInsets.all(12.0),
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Name
                      Text(
                        review['businessName'] ?? localization.no_business,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // User Name
                      Text(
                        'Reviewer: ${review['name'] ?? localization.unknown}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8.0),
                      // Rating
                      Row(
                        children: List.generate(
                          review['rating']?.toInt() ?? 0,
                          (index) =>
                              const Icon(Icons.star, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Comment
                      Text(
                        review['comment'] ?? localization.no_comment,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8.0),
                      // Actions (Edit & Delete)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editReview(review),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteReview(review['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
