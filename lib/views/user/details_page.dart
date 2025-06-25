import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/widgets/reviews_dialog.dart';
import 'package:localbusiness/views/user/call_action.dart';
import 'package:localbusiness/views/user/email_action.dart';
import 'package:localbusiness/views/auth/auth_modal.dart';
import 'package:localbusiness/views/user/sharing_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DetailsPage extends StatelessWidget {
  final String businessId;
  final String creatorId;

  const DetailsPage(
      {super.key, required this.businessId, required this.creatorId});

  void _showAuthModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AuthModal(role: 'user'),
    );
  }

  Future<void> _flagBusiness(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAuthModal(context); // ✅ Ask guest users to log in
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.flag_business),
        content: Text(AppLocalizations.of(context)!.flag_business_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.flag),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .update({
          'flags': FieldValue.increment(1),
          'flaggedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId)
            .update({
          'totalFlagsReceived': FieldValue.increment(1),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business flagged successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error flagging business: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.business_details),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SpinKitWave(
              color: Color.fromARGB(255, 133, 128,
                  128), // Or use Theme.of(context).colorScheme.primary
              size: 50.0,
            ));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(localization.no_business));
          }

          final businessData = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> imageUrls =
              (businessData['image'] as List<dynamic>?)?.cast<String>() ?? [];

          final String name = businessData['name'] ?? 'No Name';
          final String description =
              businessData['description'] ?? 'No Description';
          final String openingHours = businessData['opening_hours'] ?? 'N/A';
          final String closingHours = businessData['closing_hours'] ?? 'N/A';
          final String phone = businessData['phone'] ?? 'N/A';
          final String email = businessData['email'] ?? 'N/A';
          final String category = businessData['category'] ?? 'No Category';
          final String ownerName =
              businessData['owner_name'] ?? 'No Owner Name';
          final String priceRange = businessData['price_range'] ?? 'N/A';
          final String operatingDays = businessData['operating_days'] ?? 'N/A';
          final String imageUrl = businessData['image'] ??
              'https://via.placeholder.com/150'; // Placeholder image

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Business Name and Category
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                const Divider(thickness: 1, height: 1),

                // Description Section (Scrollable)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 150, // Fixed height for scrollable description
                        child: SingleChildScrollView(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              // White text color
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                const Divider(thickness: 1, height: 1),

                // Business Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailCard(localization.owners_name, ownerName),
                      _buildDetailCard(localization.prince_range, priceRange),
                      _buildDetailCard(
                          localization.operating_days, operatingDays),
                      _buildDetailCard(localization.opening_hrs, openingHours),
                      _buildDetailCard(localization.closing_hrs, closingHours),
                      _buildDetailCard(localization.phone, phone),
                    ],
                  ),
                ),

                // Divider
                const Divider(thickness: 1, height: 1),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.call,
                            label: localization.call,
                            color: Colors.green,
                            onPressed: isGuest
                                ? () => _showAuthModal(context) // 🚨 Blocked!
                                : () => CallAction.launchCaller(phone),
                          ),
                          _buildActionButton(
                            icon: Icons.email,
                            label: localization.email,
                            color: Colors.blue,
                            onPressed: isGuest
                                ? () => _showAuthModal(context) // 🚨 Blocked!
                                : () => EmailAction.launchEmail(
                                      toEmail: email,
                                      subject: 'Regarding $name',
                                      body: 'Hello, I would like to inquire...',
                                    ),
                          ),
                          // In the DetailsPage widget, update the share button action:
                          // In your DetailsPage widget's action button:
                          _buildActionButton(
                            icon: Icons.share,
                            label: localization.share,
                            color: Colors.blueAccent,
                            onPressed: isGuest
                                ? () => _showAuthModal(context)
                                : () => ShareService.shareBusiness(
                                      name: name,
                                      description: description,
                                      phone: phone,
                                      category: category,
                                      context: context,
                                    ),
                          ),
                          _buildActionButton(
                            icon: Icons.rate_review,
                            label: localization.review,
                            color: Colors.orange,
                            onPressed: isGuest
                                ? () => _showAuthModal(context) // 🚨 Blocked!
                                : () => showDialog(
                                      context: context,
                                      builder: (context) =>
                                          ReviewPage(businessId: businessId),
                                    ),
                          ),
                          _buildActionButton(
                            icon: Icons.flag,
                            label: localization.flag,
                            color: Colors.red,
                            onPressed: isGuest
                                ? () => _showAuthModal(context) // 🚨 Blocked!
                                : () => _flagBusiness(context),
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        subtitle: Text(value,
            style: const TextStyle(
              fontSize: 16,
            ) // White text
            ),
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 32),
          onPressed: onPressed,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
