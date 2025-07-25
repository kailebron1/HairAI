import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AnalysisService {
  // TODO: Replace with your deployed backend URL
  static const String _backendUrl =
      'https://your-render-service-name.onrender.com/analyze';

  static Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('Backend Error: ${response.statusCode} ${response.body}');
        }
        throw Exception('Failed to analyze image: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network or parsing error: $e');
      }
      rethrow;
    }
  }
}
