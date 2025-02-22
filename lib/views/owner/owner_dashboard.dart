import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'owner_analytics_page.dart';
import 'owner_reviews_page.dart';
import 'business_card.dart';
import 'business_form.dart';
import 'business_detail_page.dart';
import '../shared/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  _OwnerDashboardState createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _currentIndex = 0;

  // Stream for the businesses
  late Stream<QuerySnapshot> _businessesStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Filter businesses by creatorId
      _businessesStream = FirebaseFirestore.instance
          .collection('businesses')
          .where('creatorId', isEqualTo: user.uid)
          .snapshots();
    } else {
      _businessesStream = const Stream.empty();
    }
  }

  // Pages for navigation
  List<Widget> get _pages => [
        _dashboardPage(),
        const OwnerReviewsPage(),
        const OwnerAnalyticsPage(),
      ];

  // Dashboard Page UI
  Widget _dashboardPage() {
    final localization = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot>(
      stream: _businessesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(localization.businesses));
        }

        final businesses = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id, // Add the Firestore document ID for further use
          };
        }).toList();

        return ListView.builder(
          itemCount: businesses.length,
          itemBuilder: (context, index) {
            final business = businesses[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusinessDetailPage(
                      business: business, // Pass the selected business data
                    ),
                  ),
                );
              },
              child: BusinessCard(businessData: business),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.owner_dashboard),
      ),
      drawer: SharedDrawer(
        email: 'owner@example.com', // Replace with actual email
        role: 'Owner', // Replace with actual role
        onLogout: () {},
      ),
      body: _pages[_currentIndex], // Display the selected page
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusinessForm(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null, // FloatingActionButton is only visible on the dashboard page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localization.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.reviews),
            label: localization.review,
          ),
          BottomNavigationBarItem(
              icon: const Icon(Icons.analytics), label: localization.analytics),
        ],
      ),
    );
  }
}
