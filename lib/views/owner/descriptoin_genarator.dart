import 'package:http/http.dart' as http;
import 'dart:convert';
import '/consts.dart'; // Import API key

class AIDescriptionGenerator {
  static Future<String> generateDescription({
    required String name,
    required String category,
    required String city,
  }) async {
    // Clean the category input (remove "Other" prefix if present)
    String cleanCategory =
        category.replaceAll('Other (', '').replaceAll(')', '').trim();

    // Construct the AI prompt
    String prompt = """
      Generate a 4-line description for a business with the following details 
      just the exact reply dont say here are and donot use any special characters:
      - Name: $name
      - Category: $cleanCategory
      - City: $city

      The description should highlight the business's unique qualities and appeal to potential customers donot add special characters when responding and also make
       it a
       little detailed and longer atleast 10 lines use beautifull  icons but not too much and bullets and others if possible.
      Respond with only the description text, no additional commentary.
    """;

    // Call the AI API (Gemini)
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
        throw Exception("AI returned an empty response.");
      }

      // Clean the response by removing any unwanted prefixes or markdown
      rawText = rawText
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .replaceAll("\"", "")
          .trim();
      return rawText;
    } else {
      throw Exception("Failed to get AI description. ${response.body}");
    }
  }
}
