import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Recommendation {
  final int id;
  final String explanation;

  Recommendation({required this.id, required this.explanation});

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(id: json['id'], explanation: json['explanation']);
  }
}

class AnalysisService {
  // TODO: Replace with your deployed backend URL
  static const String _baseUrl = 'https://hair-ai-analysis.onrender.com';

  static Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    final requestBody = {'image_url': imageUrl};
    print('DEBUG: Sending to /analyze with body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
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

  static Future<List<Recommendation>> getRecommendations({
    required Map<String, dynamic> analysisResult,
    required Map<String, dynamic> quizData,
  }) async {
    final requestBody = {
      'analysis_result': analysisResult,
      'quiz_data': quizData,
    };
    if (kDebugMode) {
      print(
        'DEBUG: Sending to /recommend with body: ${jsonEncode(requestBody)}',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Recommendation.fromJson(item)).toList();
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
