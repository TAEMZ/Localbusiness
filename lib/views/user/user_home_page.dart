import 'package:flutter/material.dart';
import 'package:localbusiness/views/user/home_content_page.dart';
import 'favorites_page.dart';
import 'bookmarks_page.dart';
import 'your_reviews_page.dart'; // Page for displaying user's reviews
import '../shared/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Ensure you import the generated localization file

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;
  late Future<void> _refreshFuture;

  Future<void> _refreshData() async {
    // Simulate a network or database refresh
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      // Any logic to refresh the state of the page goes here, like fetching new data
    });
  }

  final List<Widget> _pages = [
    const HomeContentPage(), // Home page content with Search & Shortcuts
    const FavoritesPage(), // Favorites Page
    const BookmarksPage(), // Bookmarks Page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fetch localization
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.discover_businesses), // Localized text here
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyReviews()),
              );
            },
          ),
        ],
      ),
      drawer: SharedDrawer(
        email: 'user@example.com', // Replace with logged-in user email
        role: 'User', // User role
        onLogout: () {
          // TODO: Implement logout functionality
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _pages[_currentIndex], // Dynamic content based on bottom nav
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localization.home, // Localized text here
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: localization.favorites, // Localized text here
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark),
            label: localization.bookmarks, // Localized text here
          ),
        ],
      ),
    );
  }
}
