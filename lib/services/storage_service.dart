import 'dart:io';
import 'dart:typed_data';
import 'package:my_first_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

class StorageService {
  static final _supabase = Supabase.instance.client;

  // New method to upload an image and return its public URL
  static Future<String> uploadImage({
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    if (file == null && bytes == null) {
      throw Exception('Either file or bytes must be provided.');
    }

    final user = _supabase.auth.currentUser;
    final folder = user?.id ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = fileName ?? '$timestamp.jpg';
    final path = '/$folder/$uniqueFileName';

    if (bytes != null) {
      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
    } else if (file != null) {
      await _supabase.storage
          .from('user-uploads')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
    }

    return _supabase.storage.from('user-uploads').getPublicUrl(path);
  }

  // Save uploaded photo and analysis to Supabase
  static Future<void> saveUploadSession({
    required String imageUrl,
    required Map<String, dynamic> analysisData,
    QuizData? quizData,
  }) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;

    final sessionData = {
      'user_id': userId,
      'image_url': imageUrl,
      'face_shape': analysisData['face_shape'],
      'skin_tone': analysisData['skin_tone'],
      'hair_color': analysisData['hair_color'],
      'hair_length': analysisData['hair_length'],
      'raw_analysis_data': analysisData,
      'quiz_data': quizData?.toJson(),
    };

    await _supabase.from('upload_sessions').insert(sessionData);
  }

  // Get all upload sessions for the current user
  static Future<List<UploadSession>> getUploadSessions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('upload_sessions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((data) => UploadSession.fromJson(data))
        .toList();
  }

  // TODO: Refactor these methods to work with Supabase
  // static Future<void> saveLikedStyle(...) async {}
  // static Future<List<SavedHairstyle>> getSavedHairstyles() async { return []; }
  // static Future<void> removeSavedStyle(String styleId) async {}

  // Clear all stored data (now clears Supabase data for the user)
  static Future<void> clearAllData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // This is a destructive operation. In a real app, you might want to handle
    // this differently (e.g., soft deletes).
    await _supabase.from('upload_sessions').delete().eq('user_id', user.id);
    // You would also delete saved styles and other user-related data here.
  }
}

// Data models (UploadSession, QuizData, etc. remain here for now)
class UploadSession {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime timestamp;
  final QuizData? quizData;

  // AI-generated attributes
  final String? faceShape;
  final String? skinTone;
  final String? hairColor;
  final String? jawline;
  final bool? hasEyeglasses;
  final bool? hasFacialHair;
  final Map<String, dynamic>? rawAnalysisData;

  UploadSession({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.timestamp,
    this.quizData,
    this.faceShape,
    this.skinTone,
    this.hairColor,
    this.jawline,
    this.hasEyeglasses,
    this.hasFacialHair,
    this.rawAnalysisData,
  });

  factory UploadSession.fromJson(Map<String, dynamic> json) {
    return UploadSession(
      id: json['id'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
      timestamp: DateTime.parse(json['created_at']),
      faceShape: json['face_shape'],
      skinTone: json['skin_tone'],
      hairColor: json['hair_color'],
      jawline: json['jawline'],
      hasEyeglasses: json['has_eyeglasses'],
      hasFacialHair: json['has_facial_hair'],
      rawAnalysisData: json['raw_analysis_data'],
      quizData: json['quiz_data'] != null
          ? QuizData.fromJson(json['quiz_data'])
          : null,
    );
  }
}

class QuizData {
  final String hairTexture;
  final String hairPorosity;
  final double timeAvailable;
  final String style;
  final String hairGoals;
  final String featuresHighlight;

  QuizData({
    required this.hairTexture,
    required this.hairPorosity,
    required this.timeAvailable,
    required this.style,
    required this.hairGoals,
    required this.featuresHighlight,
  });

  Map<String, dynamic> toJson() {
    return {
      'hairTexture': hairTexture,
      'hairPorosity': hairPorosity,
      'timeAvailable': timeAvailable,
      'style': style,
      'hairGoals': hairGoals,
      'featuresHighlight': featuresHighlight,
    };
  }

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      hairTexture: json['hairTexture'],
      hairPorosity: json['hairPorosity'],
      timeAvailable: json['timeAvailable'],
      style: json['style'],
      hairGoals: json['hairGoals'],
      featuresHighlight: json['featuresHighlight'],
    );
  }
}

class SavedHairstyle {
  final String id;
  final HairstyleData hairstyle;
  final String uploadSessionId;
  final DateTime savedAt;

  SavedHairstyle({
    required this.id,
    required this.hairstyle,
    required this.uploadSessionId,
    required this.savedAt,
  });

  factory SavedHairstyle.fromJson(Map<String, dynamic> json) {
    final hairstyleData = json['hairstyle'];
    return SavedHairstyle(
      id: json['id'],
      hairstyle: HairstyleData(
        id: hairstyleData['id'], // Add this
        name: hairstyleData['name'],
        description: hairstyleData['description'],
        imageUrl: hairstyleData['imageUrl'],
        steps: List<String>.from(hairstyleData['steps']),
        products: (hairstyleData['products'] as List)
            .map((p) => Product(p['name'], p['description'], p['price']))
            .toList(),
        proTips: List<String>.from(hairstyleData['pro_tips'] ?? []), // Fix this
      ),
      uploadSessionId: json['uploadSessionId'],
      savedAt: DateTime.parse(json['savedAt']),
    );
  }
}
