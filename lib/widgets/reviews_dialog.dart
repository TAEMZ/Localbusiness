import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReviewPage extends StatefulWidget {
  final String businessId;
  final Map<String, dynamic>? reviewData; // Pass review data for editing

  const ReviewPage({super.key, required this.businessId, this.reviewData});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  double rating = 3.0;

  @override
  void initState() {
    super.initState();
    if (widget.reviewData != null) {
      // Populate fields for editing
      nameController.text = widget.reviewData?['name'] ?? '';
      commentController.text = widget.reviewData?['comment'] ?? '';
      rating = widget.reviewData?['rating']?.toDouble() ?? 3.0;
    }
  }

  Future<String?> _fetchCreatorId(String businessId) async {
    try {
      final businessSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();

      if (businessSnapshot.exists) {
        return businessSnapshot.data()?['creatorId'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching creatorId: $e');
    }
    return null; // Return null if creatorId not found
  }

  Future<void> saveReview() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Fetch creatorId (reviewedId) of the business being reviewed
      final reviewedId = await _fetchCreatorId(widget.businessId);
      if (reviewedId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.fetch_business_error)),
        );
        return;
      }

      if (widget.reviewData != null) {
        // Update existing review
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reviews')
            .doc(widget.reviewData?['id'])
            .update({
          'name': nameController.text.trim(),
          'rating': rating,
          'comment': commentController.text.trim(),
          'updated_at': DateTime.now(),
          'reviewedId': reviewedId, // Ensure reviewedId is updated
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.review_updated)),
        );
      } else {
        // Add a new review
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reviews')
            .add({
          'business_id': widget.businessId,
          'name': nameController.text.trim(),
          'rating': rating,
          'comment': commentController.text.trim(),
          'created_at': DateTime.now(),
          'reviewedId': reviewedId, // Automatically include the owner ID
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.review_submitted)),
        );
      }
      Navigator.pop(context); // Navigate back after saving
    } catch (e) {
      debugPrint('Error saving review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.error_saving_review)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reviewData != null
            ? localization.edit_review
            : localization.write_review),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Handle back button
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.your_review,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: localization.your_name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              localization.rating,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 9.0),
            Slider(
              value: rating,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              label: rating.toString(),
              onChanged: (double newRating) {
                setState(() {
                  rating = newRating;
                });
              },
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: localization.comments,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 17.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cancel button
                  },
                  child: Text(localization.cancel),
                ),
                ElevatedButton(
                  onPressed: saveReview, // Submit review button
                  child: Text(localization.submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
