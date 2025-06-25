import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/consts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

class RecommendationPage extends StatefulWidget {
  final Function(String)? onCardClicked;
  final TextEditingController searchController;

  const RecommendationPage(
      {super.key, this.onCardClicked, required this.searchController});

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final TextEditingController _queryController = TextEditingController();
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _recommendations = [];
      _message = '';
    });

    String userInput = _queryController.text.trim();

    if (userInput.isEmpty) {
      setState(() {
        _message = "Please enter a request.";
        _isLoading = false;
      });
      return;
    }

    try {
      // 🔹 Fetch businesses from Firestore
      QuerySnapshot businessesSnapshot =
          await FirebaseFirestore.instance.collection('businesses').get();
      List<Map<String, dynamic>> businesses = businessesSnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      if (businesses.isEmpty) {
        setState(() {
          _message = "No businesses found.";
          _isLoading = false;
        });
        return;
      }

      // 🔹 Construct a more intelligent AI prompt
      String prompt = """
        The user is looking for: "$userInput".
        Interpret the user's intent and recommend the best matching businesses.

        **Guidelines**:
        1. For food-related queries (e.g., "I'm hungry", "I want to eat"), prioritize:
           - Restaurants
           - Cafes
           - Food trucks
           - Bakeries
        2. For relaxation-related queries (e.g., "I need to relax", "Where can I chill?"), prioritize:
           - Spas
           - Cafes
           - Parks
        3. For shopping-related queries (e.g., "I want to shop", "Where can I buy clothes?"), prioritize:
           - Retail stores
           - Shopping malls
           - Boutiques
        4. For entertainment-related queries (e.g., "I want to have fun", "Where can I party?"), prioritize:
           - Cinemas
           - Clubs
           - Event venues

        **Available businesses**:
        ${businesses.map((b) => "${b['name']} - ${b['category']} in ${b['city']}. ${b['description']}").join("\n")}

        **Response format**:
        Return a **clean JSON array** of up to 5 businesses, each containing:
        - 'name'
        - 'category'
        - 'city'
        - 'description'
      """;

      // 🔹 Call AI API (Gemini)
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String? rawText = jsonResponse["candidates"]?[0]["content"]["parts"]?[0]
                ["text"]
            ?.trim();

        if (rawText == null || rawText.isEmpty) {
          setState(() {
            _message = "AI returned an empty response.";
          });
          return;
        }

        // 🔹 Clean AI response (remove markdown formatting)
        rawText =
            rawText.replaceAll("```json", "").replaceAll("```", "").trim();

        try {
          List<dynamic> aiResults = jsonDecode(rawText);

          // 🔹 Match AI results with Firestore data
          setState(() {
            _recommendations = businesses
                .where((b) => aiResults.any((ai) => ai["name"] == b["name"]))
                .toList();
          });
        } catch (e) {
          setState(() {
            _message = "AI response format error: $e";
          });
        }
      } else {
        setState(() {
          _message = "Failed to get AI recommendations. ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recommendFromFavorites() async {
    setState(() {
      _isLoading = true;
      _recommendations = [];
      _message = '';
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _message = "Please log in.";
        _isLoading = false;
      });
      return;
    }

    try {
      debugPrint("Fetching favorites and bookmarks...");
      QuerySnapshot favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      QuerySnapshot bookmarksSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .get();

      List<String> favoriteBusinessIds =
          favoritesSnapshot.docs.map((doc) => doc.id).toList();
      List<String> bookmarkBusinessIds =
          bookmarksSnapshot.docs.map((doc) => doc.id).toList();

      if (favoriteBusinessIds.isEmpty && bookmarkBusinessIds.isEmpty) {
        setState(() {
          _message = "Not enough activity to suggest.";
          _isLoading = false;
        });
        return;
      }

      debugPrint("Fetching businesses from favorites and bookmarks...");
      QuerySnapshot businessesSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where(FieldPath.documentId,
              whereIn: [...favoriteBusinessIds, ...bookmarkBusinessIds]).get();

      List<Map<String, dynamic>> businesses = businessesSnapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      if (businesses.isNotEmpty) {
        String category = businesses.first['category'] ?? 'default_category';
        debugPrint("Fetching similar businesses based on category: $category");
        QuerySnapshot similarBusinessesSnapshot = await FirebaseFirestore
            .instance
            .collection('businesses')
            .where('category', isEqualTo: category)
            .get();

        List<Map<String, dynamic>> similarBusinesses =
            similarBusinessesSnapshot.docs
                .map((doc) => {
                      "id": doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    })
                .toList();

        setState(() {
          _recommendations = similarBusinesses;
        });
      } else {
        setState(() {
          _message = "No similar businesses found.";
        });
      }
    } catch (e) {
      debugPrint("Error in _recommendFromFavorites: $e");
      setState(() {
        _message = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.find_businesses),
        backgroundColor: Colors.deepPurple, // AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: localization.what_are_you_looking,
                labelStyle: const TextStyle(color: Colors.deepPurple),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.deepPurple),
                  onPressed: _fetchRecommendations,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.deepPurple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _recommendFromFavorites,
              child: Text(localization.recommend),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const SpinKitWave(
                color: Color.fromARGB(255, 133, 128,
                    128), // Or use Theme.of(context).colorScheme.primary
                size: 50.0,
              ),
            if (_message.isNotEmpty) Text(_message),
            Expanded(
              child: ListView.builder(
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final business = _recommendations[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (widget.onCardClicked != null) {
                          widget.onCardClicked!(business['name']);
                        }
                        widget.searchController.text = business['name'];
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Business Name
                            Text(
                              business['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 🔹 Business Category and City
                            Text(
                              "${business['category'] ?? 'Unknown Category'} • ${business['city'] ?? 'Unknown City'}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 🔹 Business Description
                            Text(
                              business['description'] ?? 'No description',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
