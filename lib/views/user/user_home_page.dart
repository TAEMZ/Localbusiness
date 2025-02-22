import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localbusiness/views/user/home_content_page.dart';
import 'favorites_page.dart';
import 'bookmarks_page.dart';
import 'your_reviews_page.dart';
import '../shared/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserHomePage extends StatefulWidget {
  final bool isGuest; // Indicates if the user is in guest mode

  const UserHomePage({super.key, this.isGuest = false});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;
  late Future<void> _refreshFuture;
  User? currentUser;

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

  void _showAuthModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('Please log in or sign up to use this feature.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login_user');
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/signup_user');
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
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
      const HomeContentPage(),
      const FavoritesPage(),
      const BookmarksPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.discover_businesses),
        actions: [
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
            Navigator.pushReplacementNamed(context, '/welcome');
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localization.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: localization.favorites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark),
            label: localization.bookmarks,
          ),
        ],
      ),
    );
  }
}
