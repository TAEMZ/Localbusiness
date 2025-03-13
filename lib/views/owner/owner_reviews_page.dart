import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OwnerReviewsPage extends StatefulWidget {
  final String creatorId;

  const OwnerReviewsPage({super.key, required this.creatorId});

  @override
  State<OwnerReviewsPage> createState() => _OwnerReviewsPageState();
}

class _OwnerReviewsPageState extends State<OwnerReviewsPage> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  String _filter = 'all';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchOwnerReviews();
  }

  Future<void> _flagReview(String reviewId, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Review'),
        content: const Text('Are you sure you want to flag this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Flag'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId == null) return;

        // Flag the review
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reviews')
            .doc(reviewId)
            .update({
          'flags': FieldValue.increment(1),
          'flaggedAt': FieldValue.serverTimestamp(),
        });

        // Increment the flag count for the user who flagged
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'totalFlagsReceived': FieldValue.increment(1),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review flagged successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error flagging review: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOwnerReviews() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    try {
      Query query = FirebaseFirestore.instance
          .collectionGroup('reviews')
          .where('reviewedId', isEqualTo: userId);

      if (_filter == 'flagged') {
        query = query.where('flags', isGreaterThan: 0);
      } else if (_filter == '5_star') {
        query = query.where('rating', isEqualTo: 5);
      }

      final reviewsSnapshot = await query.get();

      List<Map<String, dynamic>> reviews = [];
      for (var reviewDoc in reviewsSnapshot.docs) {
        final reviewData =
            reviewDoc.data() as Map<String, dynamic>?; // Explicit cast
        String businessName = 'Unknown Business';

        try {
          final businessId = reviewData?['business_id']?.toString() ?? '';
          final businessSnapshot = await FirebaseFirestore.instance
              .collection('businesses')
              .doc(businessId)
              .get();

          businessName = businessSnapshot.data()?['name'] ?? 'Unknown Business';
        } catch (e) {
          debugPrint('Error fetching business: $e');
        }

        reviews.add({
          'reviewId': reviewDoc.id,
          ...?reviewData, // Safe spread with null check
          'businessName': businessName,
          'userId': reviewDoc.reference.parent.parent?.id,
        });
      }

      return reviews;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  void _refreshReviews() {
    setState(() {
      _reviewsFuture = _fetchOwnerReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.user_reviews),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReviews,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filter,
              icon: const Icon(Icons.filter_list),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(localization.all),
                ),
                DropdownMenuItem(
                  value: 'flagged',
                  child: Text(localization.flagged),
                ),
                DropdownMenuItem(
                  value: '5_star',
                  child: Text(localization.five_star),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filter = value;
                    _refreshReviews();
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                localization.error_business,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
              ),
            );
          }

          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return Center(
              child: Text(
                localization.no_reviews,
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final rating = review['rating']?.toDouble() ?? 0.0;
              final flags = review['flags'] ?? 0;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              review['businessName'] ??
                                  localization.no_business,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (flags > 0)
                            Row(
                              children: [
                                const Icon(Icons.flag,
                                    color: Colors.red, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$flags',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${localization.rating}: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          _buildStarRating(rating),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['comment'] ?? localization.no_comment,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.reviewer}: ${review['name'] ?? localization.unknown}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.flag_outlined),
                            color: Colors.red,
                            iconSize: 20,
                            onPressed: () => _flagReview(
                              review['reviewId'],
                              review['userId'],
                            ),
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

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index == rating.floor() && rating % 1 >= 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 20);
      }),
    );
  }
}
