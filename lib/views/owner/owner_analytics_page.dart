import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
          'totalBusinesses': 0,
          'totalReviews': 0,
          'averageRating': 0.0,
          'totalPositiveReviews': 0,
          'totalNegativeReviews': 0,
          'totalFlags': 0,
        };
      }

      int totalBusinesses = businessSnapshot.docs.length;
      int totalReviews = 0;
      double totalRating = 0;
      int totalPositiveReviews = 0;
      int totalNegativeReviews = 0;
      int totalFlags = 0;

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

        // Fetch flags for the business
        totalFlags += (business.data()['flags'] ?? 0) as int;
      }

      return {
        'totalBusinesses': totalBusinesses,
        'totalReviews': totalReviews,
        'averageRating': totalReviews > 0 ? totalRating / totalReviews : 0.0,
        'totalPositiveReviews': totalPositiveReviews,
        'totalNegativeReviews': totalNegativeReviews,
        'totalFlags': totalFlags,
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh the content without navigating away
          await _fetchAnalytics(); // Await the fetch and return void
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: SpinKitWave(
                color: Color.fromARGB(255, 133, 128,
                    128), // Or use Theme.of(context).colorScheme.primary
                size: 50.0,
              ));
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
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two cards per row
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.85, // Adjusted to prevent overflow
                ),
                children: [
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.business,
                    title: 'Total Businesses',
                    value: '${analytics['totalBusinesses'] ?? 0}',
                    color: Colors.blue,
                  ),
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.rate_review,
                    title: 'Total Reviews',
                    value: '${analytics['totalReviews'] ?? 0}',
                    color: Colors.green,
                  ),
                  _buildAnalyticsCardWithRating(
                    context,
                    icon: Icons.star,
                    title: 'Average Rating',
                    rating: analytics['averageRating'] ?? 0.0,
                    color: Colors.amber,
                  ),
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.thumb_up,
                    title: 'Positive Reviews',
                    value: '${analytics['totalPositiveReviews'] ?? 0}',
                    color: Colors.blue,
                  ),
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.thumb_down,
                    title: 'Negative Reviews',
                    value: '${analytics['totalNegativeReviews'] ?? 0}',
                    color: Colors.red,
                  ),
                  _buildAnalyticsCard(
                    context,
                    icon: Icons.flag,
                    title: 'Total Flags',
                    value: '${analytics['totalFlags'] ?? 0}',
                    color: Colors.purple,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color), // Reduced icon size
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color), // Reduced icon size
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // Reduced spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16, // Reduced star size
                  ),
                ),
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
