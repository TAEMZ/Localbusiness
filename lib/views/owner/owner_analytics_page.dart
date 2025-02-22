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
      // Fetch all businesses created by the owner
      final businessSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('creatorId', isEqualTo: userId)
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

      int totalReviews = 0;
      double totalRating = 0;
      int totalPositiveReviews = 0;
      int totalNegativeReviews = 0;
      int totalSearches = 0;

      for (var business in businessSnapshot.docs) {
        final businessId = business.id;

        // Fetch reviews for the business
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collectionGroup('reviews')
            .where('business_id', isEqualTo: businessId)
            .get();

        totalReviews += reviewsSnapshot.docs.length;

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

        // Fetch search metrics
        totalSearches += (business.data()['timesSearched'] ?? 0) as int;
      }

      return {
        'totalReviews': totalReviews,
        'averageRating': totalReviews > 0 ? totalRating / totalReviews : 0.0,
        'totalPositiveReviews': totalPositiveReviews,
        'totalNegativeReviews': totalNegativeReviews,
        'timesSearched': totalSearches,
      };
    } catch (e) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OwnerAnalyticsPage(),
                ),
              );
            },
          ),
        ],
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
            return const Center(
              child: Text(
                'No analytics data available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final analytics = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.rate_review,
                    title: localization.your_review,
                    value: '${analytics['totalReviews'] ?? 0}',
                    color: Colors.green,
                  ),
                  _buildAnalyticsCardWithRating(
                    context,
                    icon: Icons.star,
                    title: localization.rating,
                    rating: analytics['averageRating'] ?? 0.0,
                    color: Colors.amber,
                  ),
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.thumb_up,
                    title: localization.total_positive,
                    value: '${analytics['totalPositiveReviews'] ?? 0}',
                    color: Colors.blue,
                  ),
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.thumb_down,
                    title: localization.total_negative,
                    value: '${analytics['totalNegativeReviews'] ?? 0}',
                    color: Colors.red,
                  ),
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.search,
                    title: localization.times_searched,
                    value: '${analytics['timesSearched'] ?? 0}',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Container(
      width: 150, // Fixed width for horizontal scrolling
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 4.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCardWithRating(BuildContext context,
      {required IconData icon,
      required String title,
      required double rating,
      required Color color}) {
    return Container(
      width: 150, // Fixed width for horizontal scrolling
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 4.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                rating.toStringAsFixed(1),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
