import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.100:3000'; // Replace with your Flask server IP

  Future<Map<String, dynamic>> generateClue(
    String word,
    String category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'clue_${word}_$category';
    final cachedClue = prefs.getString(cacheKey);

    if (cachedClue != null) {
      return jsonDecode(cachedClue);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_clue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': word, 'category': category}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        await prefs.setString(cacheKey, jsonEncode(result));
        return result;
      } else {
        throw Exception('Failed to generate clue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating clue: $e');
    }
  }

  Future<Map<String, dynamic>> generateHint(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'hint_$word';
    final cachedHint = prefs.getString(cacheKey);

    if (cachedHint != null) {
      return jsonDecode(cachedHint);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_hint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': word}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        await prefs.setString(cacheKey, jsonEncode(result));
        return result;
      } else {
        throw Exception('Failed to generate hint: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating hint: $e');
    }
  }

  Future<Map<String, dynamic>> validateWord(
    String word,
    String prevWord,
    List<String> usedWords,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'validate_${word}_${prevWord}_${usedWords.join("_")}';
    final cachedResult = prefs.getString(cacheKey);

    if (cachedResult != null) {
      return jsonDecode(cachedResult);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate_word'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'word': word,
          'prev_word': prevWord,
          'used_words': usedWords,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        await prefs.setString(cacheKey, jsonEncode(result));
        return result;
      } else {
        throw Exception('Failed to validate word: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error validating word: $e');
    }
  }
}
