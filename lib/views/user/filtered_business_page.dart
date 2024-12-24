import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_business_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FilteredBusinessPage extends StatelessWidget {
  final String category;

  const FilteredBusinessPage({super.key, required this.category});

  Future<List<Map<String, dynamic>>> _fetchBusinessesByCategory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      debugPrint('Error fetching businesses: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBusinessesByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Center(child: Text(localization.no_business));
          }

          final businesses = snapshot.data!;
          return ListView.builder(
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              return UserBusinessCard(
                businessData: business,
                onRemove: () {}, // Add logic if necessary
              );
            },
          );
        },
      ),
    );
  }
}
