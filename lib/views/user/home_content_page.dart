import 'package:flutter/material.dart';
import 'business_shortcuts.dart';
import 'package:localbusiness/views/user/search_bar.dart';
import 'near_you_section.dart';
import 'package:localbusiness/widgets/reviews_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  bool _isRefreshing = false;

  Future<void> _refreshContent() async {
    setState(() {
      _isRefreshing = true; // Start refresh
    });

    // Simulate fetching new data (replace with actual data fetching logic)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false; // End refresh
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _refreshContent,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Search(),
              const SizedBox(height: 16),
              const BusinessShortcuts(),
              const SizedBox(height: 16),
              Text(
                localization.user_reviews,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isRefreshing)
                const Center(
                    child: CircularProgressIndicator()) // Optional loading
              else
                const ReviewsList(),
              const SizedBox(height: 16),
              Text(
                localization.near_you,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isRefreshing)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                const NearYouSection(),
            ],
          ),
        ),
      ),
    );
  }
}
