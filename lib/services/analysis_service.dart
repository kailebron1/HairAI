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
    if (kDebugMode) {
      print('DEBUG: Sending to /analyze with body: ${jsonEncode(requestBody)}');
    }

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

  static Future<List<String>> recognizeProducts(String imageUrl) async {
    final requestBody = {'image_url': imageUrl};
    if (kDebugMode) {
      print(
        'DEBUG: Sending to /recognize-products with body: ${jsonEncode(requestBody)}',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recognize-products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['products']);
      } else {
        if (kDebugMode) {
          print(
            'Backend Error (/recognize-products): ${response.statusCode} ${response.body}',
          );
        }
        throw Exception(
          'Failed to recognize products: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network or parsing error (/recognize-products): $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getImplementationGuide({
    required String userImageUrl,
    required int targetStyleId,
    required List<String> userProducts,
  }) async {
    final requestBody = {
      'user_image_url': userImageUrl,
      'target_style_id': targetStyleId,
      'user_products': userProducts,
    };
    if (kDebugMode) {
      print(
        'DEBUG: Sending to /implementation-guide with body: ${jsonEncode(requestBody)}',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/implementation-guide'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print(
            'Backend Error (/implementation-guide): ${response.statusCode} ${response.body}',
          );
        }
        throw Exception(
          'Failed to get implementation guide: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network or parsing error (/implementation-guide): $e');
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
