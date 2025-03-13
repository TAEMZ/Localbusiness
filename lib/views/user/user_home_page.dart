import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localbusiness/views/user/home_content_page.dart';
import 'favorites_page.dart';
import 'bookmarks_page.dart';
import 'your_reviews_page.dart';
import '../shared/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart'; // ✅ New package
import '../auth/auth_modal.dart';
import 'package:localbusiness/views/user/recommendation_page.dart'; // ✅ Import AuthModal

class UserHomePage extends StatefulWidget {
  final bool isGuest;

  const UserHomePage({super.key, this.isGuest = false});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;
  late Future<void> _refreshFuture;
  User? currentUser;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshFuture = _refreshData();
    _fetchUser();
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }

  void _fetchUser() {
    setState(() {
      currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  // ✅ Show AuthModal instead of navigating to non-existing login page
  void _showAuthModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AuthModal(role: 'user'),
    );
  }

  void _onItemTapped(int index) {
    if (widget.isGuest && index != 0) {
      _showAuthModal(context);
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final String email = currentUser?.email ?? 'Guest';
    final String role = widget.isGuest ? 'Guest' : 'User';

    final List<Widget> pages = [
      HomeContentPage(searchController: _searchController),
      const FavoritesPage(),
      const BookmarksPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.discover_businesses),
        actions: [
          IconButton(
            icon: const Icon(Icons.recommend,
                color: Color.fromARGB(255, 190, 245, 255)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecommendationPage(
                    searchController: _searchController, // Pass the controller
                    onCardClicked: (String businessName) {
                      // Update the search bar text and rebuild the UI
                      setState(() {
                        _searchController.text = businessName;
                      });
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.rate_review),
            onPressed: () {
              if (widget.isGuest) {
                _showAuthModal(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyReviews()),
                );
              }
            },
          ),
        ],
      ),
      drawer: SharedDrawer(
        email: email,
        role: role,
        onLogout: () async {
          if (!widget.isGuest) {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/welcome_page');
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: pages[_currentIndex],
      ),
      // ✅ Stylish Bottom Navigation
      bottomNavigationBar: ConvexAppBar(
        backgroundColor:
            const Color.fromARGB(255, 214, 190, 255), // Theme color
        color: Colors.white, // Icon color
        activeColor:
            const Color.fromARGB(255, 226, 248, 253), // Selected icon color
        initialActiveIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          TabItem(icon: Icons.home, title: localization.home),
          TabItem(icon: Icons.favorite, title: localization.favorites),
          TabItem(icon: Icons.bookmark, title: localization.bookmarks),
        ],
      ),
    );
  }
}
