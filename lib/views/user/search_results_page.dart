import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_business_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _fetchSearchResults(widget.query);
  }

  Future<void> _fetchSearchResults(String query) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('name_lowercase', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name_lowercase',
              isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();

      final results = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching search results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeBusiness(String businessId) {
    setState(() {
      _searchResults.removeWhere((business) => business['id'] == businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "${widget.query}"'),
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitWave(
              color:
                  Colors.black, // Or use Theme.of(context).colorScheme.primary
              size: 50.0,
            ))
          : _searchResults.isEmpty
              ? Center(child: Text(localization.no_business))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final business = _searchResults[index];
                    return UserBusinessCard(
                      businessData: business,
                      onRemove: () => _removeBusiness(business['id']),
                    );
                  },
                ),
    );
  }
}
