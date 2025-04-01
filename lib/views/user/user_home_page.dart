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
  final String businessId;

  const UserHomePage(
      {super.key, this.isGuest = false, required this.businessId});

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
    // Debugging: Print the index and guest status
    debugPrint('Tapped index: $index, isGuest: ${widget.isGuest}');

    // If the user is a guest and tries to access Favorites or Bookmarks, show the auth modal
    if (widget.isGuest && (index == 1 || index == 2)) {
      debugPrint('Showing auth modal for guest user');
      _showAuthModal(context);
      return; // Prevent changing the index
    }

    // Otherwise, update the index
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
      HomeContentPage(
        searchController: _searchController,
        businessId: '',
      ),
      const FavoritesPage(),
      const BookmarksPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.discover_businesses),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome,
                color: Color.fromARGB(255, 141, 133, 133)),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 5), // Add padding here
        child: ConvexAppBar(
          backgroundColor: Colors.white, // Background color of the bar
          color: Colors.grey[600], // Color of inactive icons
          activeColor: Colors.deepPurple, // Color of the active icon
          initialActiveIndex: _currentIndex,
          onTap: _onItemTapped, // Ensure this is correctly set
          items: [
            TabItem(icon: Icons.home, title: localization.home),
            TabItem(icon: Icons.reviews, title: localization.favorites),
            TabItem(icon: Icons.analytics, title: localization.bookmarks),
          ],
          // Use a circular style for the active tab
          curveSize: 100, // Adjust the curve size of the active tab
          top: -20, // Move the bar slightly upwards
          height: 65, // Adjust the height of the bar
        ),
      ),
    );
  }
}
