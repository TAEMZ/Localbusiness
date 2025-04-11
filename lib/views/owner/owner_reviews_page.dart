import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class OwnerReviewsPage extends StatefulWidget {
  final String creatorId;

  const OwnerReviewsPage({super.key, required this.creatorId});

  @override
  State<OwnerReviewsPage> createState() => _OwnerReviewsPageState();
}

class _OwnerReviewsPageState extends State<OwnerReviewsPage> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  String _filter = 'all';
  String? _selectedCategory;

  final TextEditingController _searchController = TextEditingController();

  // Predefined categories
  final List<String> _predefinedCategories = [
    'restaurant',
    'hairdresser',
    'bar',
    'delivery',
    'coffee',
    'shopping',
    'fitness',
    'health',
    'beauty',
    'entertainment',
  ];

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

        _refreshReviews(); // Refresh the list after flagging
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

      // Apply filters
      if (_filter == 'flagged') {
        query = query.where('flags', isGreaterThan: 0);
        debugPrint('Filter: $_filter');
      } else if (_filter == '5_star') {
        query = query.where('rating', isEqualTo: 5);
      }

      final reviewsSnapshot = await query.get();

      List<Map<String, dynamic>> reviews = [];
      for (var reviewDoc in reviewsSnapshot.docs) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>?;

        // Skip if the business no longer exists
        final businessId = reviewData?['business_id']?.toString() ?? '';
        final businessSnapshot = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .get();

        if (!businessSnapshot.exists) {
          // Delete the review if the business no longer exists
          await reviewDoc.reference.delete();
          continue;
        }

        final businessName =
            businessSnapshot.data()?['name'] ?? 'Unknown Business';
        final businessCategory =
            businessSnapshot.data()?['category'] ?? 'Unknown Category';

        // Apply category filter
        if (_selectedCategory != null) {
          if (_selectedCategory == 'Other') {
            // Show reviews with custom categories (not in predefined list)
            if (_predefinedCategories.contains(businessCategory)) {
              continue; // Skip predefined categories
            }
          } else if (businessCategory != _selectedCategory) {
            continue; // Skip reviews that don't match the selected category
          }
        }

        reviews.add({
          'reviewId': reviewDoc.id,
          ...?reviewData,
          'businessName': businessName,
          'businessCategory': businessCategory,
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

  void _removeReviewFromUI(String reviewId) {
    setState(() {
      _reviewsFuture = _reviewsFuture.then((reviews) {
        return reviews
            .where((review) => review['reviewId'] != reviewId)
            .toList();
      });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._predefinedCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                const DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _refreshReviews();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: SpinKitWave(
                    color: Color.fromARGB(255, 133, 128,
                        128), // Or use Theme.of(context).colorScheme.primary
                    size: 50.0,
                  ));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      localization.error_business,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: Colors.red),
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
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
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
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
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
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.flag_outlined),
                                      color: Colors.red,
                                      iconSize: 20,
                                      onPressed: () => _flagReview(
                                        review['reviewId'],
                                        review['userId'],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      color: Colors.red,
                                      iconSize: 20,
                                      onPressed: () => _removeReviewFromUI(
                                        review['reviewId'],
                                      ),
                                    ),
                                  ],
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
          ),
        ],
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
