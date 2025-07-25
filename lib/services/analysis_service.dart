import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AnalysisService {
  // TODO: Replace with your deployed backend URL
  static const String _baseUrl = 'https://hair-ai-analysis.onrender.com';

  static Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print(
            'Backend Error (/analyze): ${response.statusCode} ${response.body}',
          );
        }
        throw Exception('Failed to analyze image: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network or parsing error (/analyze): $e');
      }
      rethrow;
    }
  }

  static Future<List<int>> getRecommendations({
    required Map<String, dynamic> analysisResult,
    required Map<String, dynamic> quizData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'analysis_result': analysisResult,
          'quiz_data': quizData,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<int>();
      } else {
        if (kDebugMode) {
          print(
            'Backend Error (/recommend): ${response.statusCode} ${response.body}',
          );
        }
        throw Exception(
          'Failed to get recommendations: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network or parsing error (/recommend): $e');
      }
      rethrow;
    }
  }
}
