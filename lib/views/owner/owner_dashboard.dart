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
import 'package:convex_bottom_bar/convex_bottom_bar.dart'; // ✅ New Package

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  _OwnerDashboardState createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _currentIndex = 0;
  late Stream<QuerySnapshot> _businessesStream;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _businessesStream = FirebaseFirestore.instance
          .collection('businesses')
          .where('creatorId', isEqualTo: user!.uid)
          .snapshots();
    } else {
      _businessesStream = const Stream.empty();
    }
  }

  List<Widget> get _pages {
    return [
      _dashboardPage(),
      if (user != null) OwnerReviewsPage(creatorId: user!.uid),
      const OwnerAnalyticsPage(),
    ];
  }

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
            'id': doc.id,
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
                      business: business,
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
        email: user?.email ?? 'owner@example.com',
        role: 'Owner',
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/welcome_page');
        },
      ),
      body: _pages[_currentIndex],
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
          : null,
      // ✅ Stylish Bottom Navigation
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: const Color.fromARGB(255, 211, 185, 255),
        color: Colors.white,
        activeColor: const Color.fromARGB(255, 227, 250, 255),
        initialActiveIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          TabItem(icon: Icons.home, title: localization.home),
          TabItem(icon: Icons.reviews, title: localization.review),
          TabItem(icon: Icons.analytics, title: localization.analytics),
        ],
      ),
    );
  }
}
