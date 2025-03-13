import 'package:flutter/material.dart';
import 'business_shortcuts.dart';
import 'package:localbusiness/views/user/search_bar.dart';
import 'near_you_section.dart';
import 'package:localbusiness/widgets/reviews_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class HomeContentPage extends StatefulWidget {
  final TextEditingController searchController;
  const HomeContentPage({super.key, required this.searchController});

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
              Search(searchController: widget.searchController),
              const SizedBox(height: 16),
              const BusinessShortcuts(),
              const SizedBox(height: 16),
              Text(
                localization.user_reviews,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Fixed height for ReviewsList
              SizedBox(
                height: 150, // Same height as the shimmer loader
                child: _isRefreshing
                    ? _buildShimmerLoader() // Use shimmer during refresh
                    : const ReviewsList(),
              ),
              const SizedBox(height: 16),
              Text(
                localization.near_you,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Fixed height for NearYouSection
              SizedBox(
                height: 200, // Same height as the shimmer loader
                child: _isRefreshing
                    ? _buildShimmerLoader() // Use shimmer during refresh
                    : const NearYouSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shimmer loader for refreshing
  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // Number of shimmer placeholders
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    color: Colors.grey[300], // Placeholder for image
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 120,
                    color: Colors.grey[300], // Placeholder for text
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 80,
                    color: Colors.grey[300], // Placeholder for text
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
