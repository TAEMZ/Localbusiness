import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OwnerAnalyticsPage extends StatelessWidget {
  const OwnerAnalyticsPage({super.key});

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception('User not logged in.');
    }

    try {
      // Fetch the single business created by the owner
      final businessSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('creatorId', isEqualTo: userId)
          .limit(1)
          .get();

      if (businessSnapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'totalPositiveReviews': 0,
          'totalNegativeReviews': 0,
          'timesSearched': 0,
        };
      }

      final business = businessSnapshot.docs.first;
      final businessId = business.id;

      // Fetch reviews for the single business
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('reviews')
          .where('business_id', isEqualTo: businessId)
          .get();

      int totalReviews = reviewsSnapshot.docs.length;
      double totalRating = 0;
      int totalPositiveReviews = 0;
      int totalNegativeReviews = 0;

      for (var reviewDoc in reviewsSnapshot.docs) {
        final reviewData = reviewDoc.data();
        final rating = (reviewData['rating'] ?? 0) as double;

        totalRating += rating;

        if (rating > 3) {
          totalPositiveReviews++;
        } else {
          totalNegativeReviews++;
        }
      }

      // Fetch search metrics from business
      int timesSearched = (business.data()['timesSearched'] ?? 0) as int;

      return {
        'totalReviews': totalReviews,
        'averageRating': totalReviews > 0 ? totalRating / totalReviews : 0.0,
        'totalPositiveReviews': totalPositiveReviews,
        'totalNegativeReviews': totalNegativeReviews,
        'timesSearched': timesSearched,
      };
    } catch (e) {
      // Log the error to the debug console
      debugPrint('Error fetching analytics: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.analytics),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            // Log the error and show a placeholder message
            debugPrint('Error or no data available in analytics');
            return const Center(
              child: Text('No data available.'),
            );
          }

          final analytics = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.your_analytics,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Total Reviews and Comments
                _buildAnalyticsCard(
                  context,
                  icon: Icons.rate_review,
                  title: localization.your_review,
                  subtitle: '${analytics['totalReviews'] ?? 0} Reviews',
                  color: Colors.green,
                ),

                // Average Rating
                _buildAnalyticsCardWithRating(
                  context,
                  icon: Icons.star,
                  title: localization.rating,
                  rating: analytics['averageRating'] ?? 0.0,
                  color: Colors.amber,
                ),

                // Total Positive Reviews
                _buildAnalyticsCard(
                  context,
                  icon: Icons.thumb_up,
                  title: localization.total_positive,
                  subtitle:
                      '${analytics['totalPositiveReviews'] ?? 0} Positive',
                  color: Colors.blue,
                ),

                // Total Negative Reviews
                _buildAnalyticsCard(
                  context,
                  icon: Icons.thumb_down,
                  title: localization.total_negative,
                  subtitle:
                      '${analytics['totalNegativeReviews'] ?? 0} Negative',
                  color: Colors.red,
                ),

                // Times Searched
                _buildAnalyticsCard(
                  context,
                  icon: Icons.search,
                  title: localization.times_searched,
                  subtitle: '${analytics['timesSearched'] ?? 0} Searches',
                  color: Colors.purple,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCardWithRating(BuildContext context,
      {required IconData icon,
      required String title,
      required double rating,
      required Color color}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
