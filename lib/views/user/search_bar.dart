import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/views/user/search_results_page.dart';

class Search extends StatefulWidget {
  final TextEditingController searchController; // Add this
  final Function(String)? onCardClicked; // Callback to update the search bar

  const Search(
      {super.key,
      required this.searchController,
      this.onCardClicked}); // Update constructor

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  void _navigateToSearchResults(String query) {
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            query: query,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return TextField(
      controller: widget.searchController, // Use the passed controller
      decoration: InputDecoration(
        hintText: localization.search,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onSubmitted: _navigateToSearchResults,
    );
  }
}
