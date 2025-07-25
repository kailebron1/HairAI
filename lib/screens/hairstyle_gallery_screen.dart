import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import 'package:flutter/foundation.dart';

class HairstyleGalleryScreen extends StatefulWidget {
  final HairstyleData hairstyle;
  final String? skinTone;

  const HairstyleGalleryScreen({
    super.key,
    required this.hairstyle,
    this.skinTone,
  });

  @override
  State<HairstyleGalleryScreen> createState() => _HairstyleGalleryScreenState();
}

class _HairstyleGalleryScreenState extends State<HairstyleGalleryScreen> {
  List<HairstyleImage> _images = [];
  bool _isLoading = true;
  String? _errorMessage;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchImages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // For now, use 'light' as default skin tone
      final images = await SupabaseService.getHairstyleImages(
        widget.hairstyle.id!,
        skinTone: widget.skinTone ?? 'light',
      );

      // Clean up URLs to fix double slash issues
      final cleanedImages = images.map((image) {
        final cleanedUrl = image.imageUrl
            .replaceAll('//', '/')
            .replaceFirst('https:/', 'https://');
        if (kDebugMode) {
          print('DEBUG: Original URL: ${image.imageUrl}');
          print('DEBUG: Cleaned URL: $cleanedUrl');
        }

        return HairstyleImage(
          id: image.id,
          hairstyleId: image.hairstyleId,
          imageUrl: cleanedUrl,
          viewType: image.viewType,
          skinTone: image.skinTone,
          displayOrder: image.displayOrder,
          createdAt: image.createdAt,
        );
      }).toList();

      setState(() {
        _images = cleanedImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load images. Please try again.';
      });
      if (kDebugMode) {
        print('Error fetching hairstyle images: $e');
      }
    }
  }

  void _nextImage() {
    if (_currentIndex < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _normalizeImageUrl(String url) {
    // Fix double slashes and ensure proper protocol
    return url
        .replaceAll(
          RegExp(r'(?<!:)//+'),
          '/',
        ) // Replace multiple slashes (but not after :)
        .replaceFirst('https:/', 'https://'); // Fix protocol if broken
  }

  Widget _buildRobustImage(String url, int index) {
    if (kDebugMode) {
      print('DEBUG: Building image widget for index $index with URL: $url');
    }

    return FutureBuilder<bool>(
      future: _testImageUrl(url, index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[700],
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            ),
          );
        }

        if (snapshot.hasError || (snapshot.hasData && !snapshot.data!)) {
          if (kDebugMode) {
            print('ERROR: Image $index failed to load or test failed');
          }
          return Container(
            color: Colors.grey[700],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load\nImage ${index + 1}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Retry loading
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        }

        // Try Image.network first as it's more reliable than CachedNetworkImage
        return Image.network(
          url,
          fit: BoxFit.contain,
          width: double.infinity,
          headers: const {'User-Agent': 'Flutter App', 'Accept': 'image/*'},
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              if (kDebugMode) {
                print('SUCCESS: Image $index loaded successfully');
              }
              return child;
            }
            return Container(
              color: Colors.grey[700],
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF8B5CF6),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              print('ERROR: Image.network failed for index $index: $error');
            }

            // Fallback to CachedNetworkImage
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: double.infinity,
              httpHeaders: const {
                'User-Agent': 'Flutter App',
                'Accept': 'image/*',
              },
              placeholder: (context, url) => Container(
                color: Colors.grey[700],
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                ),
              ),
              errorWidget: (context, url, error) {
                if (kDebugMode) {
                  print(
                    'ERROR: CachedNetworkImage also failed for index $index: $error',
                  );
                }
                return Container(
                  color: Colors.grey[700],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Both loading methods failed\nImage ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.red, fontSize: 8),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _testImageUrl(String url, int index) async {
    try {
      final client = HttpClient();
      final request = await client.headUrl(Uri.parse(url));
      final response = await request.close();

      final bool isValid =
          response.statusCode >= 200 && response.statusCode < 300;
      if (kDebugMode) {
        print(
          'DEBUG: Image test for index $index ($url) - Status: ${response.statusCode}, Valid: $isValid',
        );
      }
      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Image test failed for index $index ($url): $e');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.hairstyle.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Image counter
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_images.length}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : _images.isEmpty
          ? const Center(
              child: Text(
                'No images available',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          : Column(
              children: [
                // Hairstyle info header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hairstyle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.hairstyle.description,
                        style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      if (widget.hairstyle.stylingTimeMinutes > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFF8B5CF6),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.hairstyle.stylingTimeMinutes} min styling time',
                              style: TextStyle(
                                color: Colors.white.withAlpha(128),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Horizontal scrollable image gallery
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          final normalizedUrl = _normalizeImageUrl(
                            image.imageUrl,
                          );

                          if (kDebugMode) {
                            print(
                              'DEBUG: Loading image $index: $normalizedUrl',
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                // Image view type label
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${image.viewType.toUpperCase()} VIEW',
                                    style: const TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Image with enhanced error handling
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildRobustImage(
                                      normalizedUrl,
                                      index,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Navigation arrows
                      if (_images.length > 1) ...[
                        // Left arrow
                        if (_currentIndex > 0)
                          Positioned(
                            left: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _previousImage,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(128),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Right arrow
                        if (_currentIndex < _images.length - 1)
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _nextImage,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(128),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],

                      // Page indicators
                      if (_images.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentIndex
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.white.withAlpha(102),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
