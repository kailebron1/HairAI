import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class SupabaseService {
  static late SupabaseClient _client;
  static bool _isInitialized = false;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static String? _deviceId; // persistent UUID for dev favourites

  // ---- Device ID helper ----
  static const String _deviceIdKey = 'device_id';
  static Future<void> _ensureDeviceId() async {
    if (_deviceId != null) return;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
      if (kDebugMode) {
        print('DEBUG: Generated new device ID $_deviceId');
      }
    }
  }

  // Initialize Supabase client with retry logic
  static Future<void> initialize() async {
    if (_isInitialized) return;

    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        if (kDebugMode) {
          print(
            'DEBUG: Initializing Supabase client (attempt ${retryCount + 1}/$_maxRetries)...',
          );
        }

        await Supabase.initialize(
          url: 'https://whybphphnjchcbnuxeph.supabase.co',
          anonKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndoeWJwaHBobmpjaGNibnV4ZXBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyODg4NDQsImV4cCI6MjA2Nzg2NDg0NH0.HoWc3ACEXYKJ0t6CdzisYDsrHlUezyHrYrCsO144VIM',
          debug: true, // Enable debug mode for better error tracking
        );

        _client = Supabase.instance.client;

        // Ensure we have a device UUID for saved_styles operations
        await _ensureDeviceId();

        // Test the connection
        await _testConnection();

        _isInitialized = true;
        if (kDebugMode) {
          print('DEBUG: Supabase client initialized successfully');
        }
        return;
      } catch (e) {
        retryCount++;
        if (kDebugMode) {
          print(
            'ERROR: Failed to initialize Supabase client (attempt $retryCount): $e',
          );
          print('ERROR: Error type: ${e.runtimeType}');
        }

        if (retryCount >= _maxRetries) {
          if (kDebugMode) {
            print(
              'ERROR: Max retries reached. Supabase initialization failed.',
            );
          }
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(_retryDelay);
      }
    }
  }

  // Test the database connection
  static Future<void> _testConnection() async {
    try {
      if (kDebugMode) {
        print('DEBUG: Testing database connection...');
      }
      // Simple query to test connection
      await _client.from('hairstyles').select('count').limit(1);
      if (kDebugMode) {
        print('DEBUG: Database connection test successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Database connection test failed: $e');
      }
      throw Exception('Database connection test failed: $e');
    }
  }

  // Get the Supabase client with initialization check
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception(
        'Supabase client not initialized. Call initialize() first.',
      );
    }
    return _client;
  }

  // Enhanced method with retry logic for database operations
  static Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (kDebugMode) {
          print('ERROR: Database operation failed (attempt $retryCount): $e');
        }

        if (retryCount >= _maxRetries) {
          if (kDebugMode) {
            print('ERROR: Max retries reached for database operation');
          }
          rethrow;
        }

        // Re-initialize connection if needed
        if (e.toString().contains('connection') ||
            e.toString().contains('network')) {
          if (kDebugMode) {
            print('DEBUG: Connection issue detected, re-initializing...');
          }
          _isInitialized = false;
          await initialize();
        }

        await Future.delayed(_retryDelay);
      }
    }
    throw Exception('Unexpected error in retry logic');
  }

  // Fetch all hairstyles from the database with retry logic
  static Future<List<HairstyleData>> getHairstyles({
    Map<String, dynamic>? analysis,
    List<int>? rankedIds,
  }) async {
    return await _executeWithRetry(() async {
      if (kDebugMode) {
        print('DEBUG: Attempting to fetch hairstyles from Supabase...');
      }

      if (rankedIds != null && rankedIds.isNotEmpty) {
        // Fetch specific hairstyles by ID and preserve the ranked order
        final response = await _client
            .from('hairstyles')
            .select('*')
            .inFilter('id', rankedIds);

        // Reorder the results to match the ranked list
        final hairstylesMap = {for (var h in response) h['id']: h};
        final orderedHairstyles = rankedIds
            .map((id) => hairstylesMap[id])
            .where((h) => h != null)
            .cast<Map<String, dynamic>>()
            .toList();

        return orderedHairstyles
            .map((hairstyle) => HairstyleData.fromSupabase(hairstyle))
            .toList();
      }

      // Fallback to the old filtering logic if no ranked IDs are provided
      var query = _client.from('hairstyles').select('*');

      if (analysis != null) {
        if (analysis['faceShape'] != null) {
          final shape = analysis['faceShape'].toString().toLowerCase();
          query = query.ilike('face_shape', '%$shape%');
        }
        if (analysis['skinTone'] != null) {
          final tone = analysis['skinTone'].toString().toLowerCase();
          query = query.ilike('skin_tones', '%$tone%');
        }
        // Add more filters as needed for other attributes
      }

      final response = await query.order('id', ascending: true);

      if (kDebugMode) {
        print('DEBUG: Fetched ${response.length} hairstyles from database');
      }
      for (var hairstyle in response) {
        if (kDebugMode) {
          print(
            'DEBUG: Hairstyle: ${hairstyle['name']} - Card Image: ${hairstyle['image_url']}',
          );
        }

        // Test if the image URL is accessible
        if (hairstyle['image_url'] != null) {
          if (kDebugMode) {
            print('DEBUG: Testing card image URL: ${hairstyle['image_url']}');
          }
        } else {
          if (kDebugMode) {
            print(
              'WARNING: No image_url found for hairstyle: ${hairstyle['name']}',
            );
          }
        }
      }

      final hairstyles = (response as List)
          .map((hairstyle) => HairstyleData.fromSupabase(hairstyle))
          .toList();

      if (kDebugMode) {
        print(
          'DEBUG: Successfully converted ${hairstyles.length} hairstyles to HairstyleData objects',
        );
      }
      return hairstyles;
    });
  }

  // Add a new hairstyle (for future use) with retry logic
  static Future<HairstyleData> addHairstyle(HairstyleData hairstyle) async {
    return await _executeWithRetry(() async {
      final response = await _client
          .from('hairstyles')
          .insert(hairstyle.toSupabase())
          .select()
          .single();

      return HairstyleData.fromSupabase(response);
    });
  }

  // Update an existing hairstyle (for future use) with retry logic
  static Future<HairstyleData> updateHairstyle(HairstyleData hairstyle) async {
    return await _executeWithRetry(() async {
      final response = await _client
          .from('hairstyles')
          .update(hairstyle.toSupabase())
          .eq('id', hairstyle.id!)
          .select()
          .single();

      return HairstyleData.fromSupabase(response);
    });
  }

  // Delete a hairstyle (for future use) with retry logic
  static Future<void> deleteHairstyle(int id) async {
    return await _executeWithRetry(() async {
      await _client.from('hairstyles').delete().eq('id', id);
    });
  }

  // Get additional images for a specific hairstyle with retry logic
  static Future<List<HairstyleImage>> getHairstyleImages(
    int hairstyleId, {
    String? skinTone,
  }) async {
    return await _executeWithRetry(() async {
      if (kDebugMode) {
        print('DEBUG: ========= FETCHING GALLERY IMAGES =========');
        print('DEBUG: Hairstyle ID: $hairstyleId');
        print('DEBUG: Requested skin tone: $skinTone');
      }

      var query = _client
          .from('hairstyle_images')
          .select('*')
          .eq('hairstyle_id', hairstyleId);

      if (skinTone != null) {
        query = query.eq('skin_tone', skinTone);
        if (kDebugMode) {
          print('DEBUG: Added skin tone filter: $skinTone');
        }
      }

      final response = await query.order('display_order', ascending: true);

      if (kDebugMode) {
        print('DEBUG: Raw database response: $response');
        print('DEBUG: Found ${response.length} hairstyle images');
      }

      if (response.isEmpty) {
        if (kDebugMode) {
          print(
            'WARNING: No gallery images found for hairstyle ID $hairstyleId with skin tone $skinTone',
          );
          print('DEBUG: Trying without skin tone filter...');
        }

        // Try again without skin tone filter
        final fallbackResponse = await _client
            .from('hairstyle_images')
            .select('*')
            .eq('hairstyle_id', hairstyleId)
            .order('display_order', ascending: true);

        if (kDebugMode) {
          print(
            'DEBUG: Fallback query (no skin tone filter) returned ${fallbackResponse.length} images',
          );
        }

        for (var image in fallbackResponse) {
          if (kDebugMode) {
            print(
              'DEBUG: Available image - View: ${image['view_type']}, Skin: ${image['skin_tone']}, URL: ${image['image_url']}',
            );
          }
        }

        return (fallbackResponse as List)
            .map((image) => HairstyleImage.fromSupabase(image))
            .toList();
      }

      for (var image in response) {
        if (kDebugMode) {
          print(
            'DEBUG: Gallery Image - View: ${image['view_type']}, Skin: ${image['skin_tone']}, URL: ${image['image_url']}',
          );
        }
      }

      return (response as List)
          .map((image) => HairstyleImage.fromSupabase(image))
          .toList();
    });
  }

  // New function to get a specific card image for a hairstyle
  static Future<String> getHairstyleCardImageUrl({
    required int hairstyleId,
    required String skinTone,
    String? assumedRace, // e.g., 'asian', 'black', etc.
  }) async {
    return await _executeWithRetry(() async {
      if (kDebugMode) {
        print(
          'DEBUG: Fetching card image for hairstyle $hairstyleId with skin tone "$skinTone" and race "$assumedRace"',
        );
      }

      // 1. Prioritize 'front' view with the exact skin tone.
      // If assumedRace is 'asian', we use that as the skin_tone for lookup.
      final lookupSkinTone = (assumedRace == 'asian') ? 'asian' : skinTone;

      var query = _client
          .from('hairstyle_images')
          .select('image_url')
          .eq('hairstyle_id', hairstyleId)
          .eq('view_type', 'front')
          .eq('skin_tone', lookupSkinTone)
          .limit(1);

      final response = await query;

      if (response.isNotEmpty && response[0]['image_url'] != null) {
        final imageUrl = response[0]['image_url'];
        if (kDebugMode) {
          print('DEBUG: Found exact match for card image: $imageUrl');
        }
        return imageUrl;
      }

      // 2. Fallback: If no exact match, find any 'front' view for a different skin tone.
      if (kDebugMode) {
        print(
          'DEBUG: No exact match found. Falling back to any "front" view image for hairstyle $hairstyleId.',
        );
      }
      final fallbackQuery = _client
          .from('hairstyle_images')
          .select('image_url')
          .eq('hairstyle_id', hairstyleId)
          .eq('view_type', 'front')
          .limit(1);

      final fallbackResponse = await fallbackQuery;

      if (fallbackResponse.isNotEmpty &&
          fallbackResponse[0]['image_url'] != null) {
        final imageUrl = fallbackResponse[0]['image_url'];
        if (kDebugMode) {
          print('DEBUG: Found fallback "front" view image: $imageUrl');
        }
        return imageUrl;
      }

      // 3. Final Fallback: If no 'front' view exists at all, get the main hairstyle image.
      if (kDebugMode) {
        print(
          'DEBUG: No "front" view found. Falling back to main hairstyle image_url.',
        );
      }
      final mainHairstyleResponse = await _client
          .from('hairstyles')
          .select('image_url')
          .eq('id', hairstyleId)
          .single();

      return mainHairstyleResponse['image_url'] ?? '';
    });
  }

  // ===================== SAVED STYLES =====================

  static Future<void> saveStyle(int hairstyleId) async {
    await _executeWithRetry(() async {
      await _ensureDeviceId();
      final uid = _deviceId!;
      await _client.from('saved_styles').upsert({
        'user_id': uid,
        'hairstyle_id': hairstyleId,
      });
    });
  }

  static Future<void> unsaveStyle(int hairstyleId) async {
    await _executeWithRetry(() async {
      await _ensureDeviceId();
      final uid = _deviceId!;
      await _client
          .from('saved_styles')
          .delete()
          .eq('user_id', uid)
          .eq('hairstyle_id', hairstyleId);
    });
  }

  static Future<List<int>> fetchSavedStyleIds() async {
    return await _executeWithRetry(() async {
      await _ensureDeviceId();
      final uid = _deviceId!;
      final res = await _client
          .from('saved_styles')
          .select('hairstyle_id')
          .eq('user_id', uid);
      return (res as List).map((e) => e['hairstyle_id'] as int).toList();
    });
  }

  static Future<List<HairstyleData>> fetchSavedStyles() async {
    final ids = await fetchSavedStyleIds();
    if (ids.isEmpty) return [];
    return await getHairstyles(rankedIds: ids);
  }

  // Check if the service is properly initialized
  static bool get isInitialized => _isInitialized;

  // Force re-initialization (useful for troubleshooting)
  static Future<void> forceReinitialize() async {
    _isInitialized = false;
    await initialize();
  }
}

// Updated HairstyleData class to work with Supabase
class HairstyleData {
  final int? id;
  final String name;
  final String description;
  final String imageUrl;
  final int stylingTimeMinutes;
  final String? difficultyLevel;
  final List<String>? hairTexture;
  final List<String>? faceShape;
  final String? hairLength;
  final DateTime? createdAt;
  final List<String>? skinTones;
  final List<String>? tags;

  // Keep backward compatibility with old constructor
  final List<String> steps;
  final List<Product> products;
  final List<String>? proTips;

  HairstyleData({
    this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.stylingTimeMinutes = 0,
    this.difficultyLevel,
    this.hairTexture,
    this.faceShape,
    this.hairLength,
    this.createdAt,
    this.skinTones,
    this.tags,
    this.steps = const [],
    this.products = const [],
    this.proTips = const [],
  });

  static List<String>? _parseFlexibleStringToList(dynamic data) {
    if (data == null) return null;

    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }

    if (data is String) {
      if (data.trim().isEmpty) {
        return [];
      }

      final String trimmedData = data.trim();

      // Try parsing as JSON array
      try {
        // A simple check for JSON array format
        if (trimmedData.startsWith('[') && trimmedData.endsWith(']')) {
          final decoded = jsonDecode(trimmedData);
          if (decoded is List) {
            return decoded.map((item) => item.toString()).toList();
          }
        }
      } catch (e) {
        // Not a valid JSON array, fall through to delimiter splitting
        if (kDebugMode) {
          print(
            'DEBUG: Could not parse "$trimmedData" as JSON, will try splitting. Error: $e',
          );
        }
      }

      // If not a JSON array, or if parsing fails, split by delimiter.
      // Handles both comma and semicolon.
      final separator = trimmedData.contains(';') ? ';' : ',';
      return trimmedData
          .split(separator)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Return an empty list for any other unhandled type to prevent errors
    return [];
  }

  // Create HairstyleData from Supabase response
  factory HairstyleData.fromSupabase(Map<String, dynamic> data) {
    String imageUrl = data['image_url'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = Supabase.instance.client.storage
          .from('public')
          .getPublicUrl(imageUrl.substring(imageUrl.indexOf('/hairstyles')));
    }

    return HairstyleData(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      imageUrl: imageUrl,
      stylingTimeMinutes: data['styling_time_minutes'] ?? 0,
      difficultyLevel: data['difficulty_level'],
      hairTexture: _parseFlexibleStringToList(data['hair_texture']),
      faceShape: _parseFlexibleStringToList(data['face_shape']),
      hairLength: data['hair_length'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
      skinTones: _parseFlexibleStringToList(data['skin_tones']),
      tags: _parseFlexibleStringToList(data['tags']),
      // For now, keep empty lists for backward compatibility
      steps: [],
      products: [],
      proTips: (data['pro_tips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  // Convert HairstyleData to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'styling_time_minutes': stylingTimeMinutes,
      'difficulty_level': difficultyLevel,
      'hair_texture': hairTexture?.join(', '),
      'face_shape': faceShape != null ? jsonEncode(faceShape) : null,
      'hair_length': hairLength,
      'skin_tones': skinTones != null ? jsonEncode(skinTones) : null,
      'tags': tags != null ? jsonEncode(tags) : null,
    };
  }

  // Create a copy with updated fields
  HairstyleData copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    int? stylingTimeMinutes,
    String? difficultyLevel,
    List<String>? hairTexture,
    List<String>? faceShape,
    String? hairLength,
    DateTime? createdAt,
    List<String>? skinTones,
    List<String>? tags,
    List<String>? steps,
    List<Product>? products,
    List<String>? proTips,
  }) {
    return HairstyleData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      stylingTimeMinutes: stylingTimeMinutes ?? this.stylingTimeMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      hairTexture: hairTexture ?? this.hairTexture,
      faceShape: faceShape ?? this.faceShape,
      hairLength: hairLength ?? this.hairLength,
      createdAt: createdAt ?? this.createdAt,
      skinTones: skinTones ?? this.skinTones,
      tags: tags ?? this.tags,
      steps: steps ?? this.steps,
      products: products ?? this.products,
      proTips: proTips ?? this.proTips,
    );
  }
}

// Keep the Product class for backward compatibility
class Product {
  final String name;
  final String description;
  final double price;

  Product(this.name, this.description, this.price);
}

// HairstyleImage class for additional hairstyle images
class HairstyleImage {
  final int? id;
  final int hairstyleId;
  final String imageUrl;
  final String viewType;
  final String skinTone;
  final int displayOrder;
  final DateTime? createdAt;

  HairstyleImage({
    this.id,
    required this.hairstyleId,
    required this.imageUrl,
    required this.viewType,
    required this.skinTone,
    this.displayOrder = 1,
    this.createdAt,
  });

  // Create HairstyleImage from Supabase response
  factory HairstyleImage.fromSupabase(Map<String, dynamic> data) {
    String imageUrl = data['image_url'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = Supabase.instance.client.storage
          .from('public')
          .getPublicUrl(imageUrl.substring(imageUrl.indexOf('/hairstyles')));
    }

    return HairstyleImage(
      id: data['id'],
      hairstyleId: data['hairstyle_id'],
      imageUrl: imageUrl,
      viewType: data['view_type'],
      skinTone: data['skin_tone'],
      displayOrder: data['display_order'] ?? 1,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
    );
  }

  // Convert HairstyleImage to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      'hairstyle_id': hairstyleId,
      'image_url': imageUrl,
      'view_type': viewType,
      'skin_tone': skinTone,
      'display_order': displayOrder,
    };
  }
}
