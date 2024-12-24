import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/widgets/reviews_dialog.dart';
import 'package:localbusiness/views/user/call_action.dart';
import 'package:localbusiness/views/user/email_action.dart';
import 'package:share_plus/share_plus.dart';

class DetailsPage extends StatelessWidget {
  final String businessId;

  const DetailsPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.business_details),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(localization.no_business));
          }

          final businessData = snapshot.data!.data() as Map<String, dynamic>;

          final String name = businessData['name'] ?? 'No Name';
          final String description =
              businessData['description'] ?? 'No Description';
          final String openingHours = businessData['opening_hours'] ?? 'N/A';
          final String closingHours = businessData['closing_hours'] ?? 'N/A';
          final String phone = businessData['phone'] ?? 'N/A';
          final String email = businessData['email'] ?? 'N/A';
          final String category = businessData['category'] ?? 'No Category';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with Name
                // Header with Name and Category
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 25.0,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black45,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Business Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Description Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Business Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildDetailCard(localization.opening_hrs, openingHours),
                      _buildDetailCard(localization.closing_hrs, closingHours),
                      const SizedBox(height: 20.0),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              CallAction(phone: phone),
                              const SizedBox(height: 5),
                              const Text(
                                'Call',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              EmailAction(
                                fetchedEmail: email,
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Email',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.share, color: Colors.blue),
                                onPressed: () {
                                  Share.share(
                                    'Check out $name!\n\n$description\n\nPhone: $phone\nEmail: $email',
                                  );
                                },
                                tooltip: 'Share',
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Share',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.rate_review,
                                    color: Colors.orange),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ReviewPage(businessId: businessId),
                                  );
                                },
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Review',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to build detail cards
  Widget _buildDetailCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }
}
