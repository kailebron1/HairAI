import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/analysis_service.dart'; // New service
import 'quiz_intro_screen.dart';

// Enum for tracking the current screen state
enum AppState { upload, analyzing, results }

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // State management
  AppState _currentState = AppState.upload;
  File? _selectedImage;
  Uint8List? _imageBytes;
  String? _fileName;
  Map<String, dynamic>? _analysisResult;
  String? _analysisError;
  bool _isAnalyzing = false;
  final Set<int> _likedStyles = {};
  QuizData? _quizData;
  int? _selectedHairstyleId;

  // Supabase integration
  List<HairstyleData> _hairstyles = [];
  Map<int, String> _explanations = {};
  bool _hairstylesLoading = false;
  String? _hairstylesError;

  // Keys for sections to enable scrolling
  final GlobalKey _analysisKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await SupabaseService.initialize();
    // Load saved style ids first so hearts render correctly
    try {
      final savedIds = await SupabaseService.fetchSavedStyleIds();
      setState(() {
        _likedStyles.clear();
        _likedStyles.addAll(savedIds);
      });
    } catch (_) {}

    await _fetchHairstyles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Get dynamic title based on current state
  String get _appBarTitle {
    switch (_currentState) {
      case AppState.upload:
        return 'HairStyle AI';
      case AppState.analyzing:
      case AppState.results:
        return 'Hair Analysis';
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await _handleImageSelection(null, bytes, 'Camera Photo');
        } else {
          await _handleImageSelection(File(image.path), null, null);
        }
      }
    } catch (e) {
      _showErrorDialog(
        'Camera access failed. Please try uploading a file instead.',
      );
    }
  }

  Future<void> _pickImageFromFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      final file = result.files.single;

      if (kIsWeb) {
        if (file.bytes != null) {
          await _handleImageSelection(null, file.bytes!, file.name);
        } else {
          _showErrorDialog('Unable to read the selected file on web platform.');
        }
      } else {
        if (file.path != null) {
          await _handleImageSelection(File(file.path!), null, null);
        } else {
          _showErrorDialog('Unable to access the selected file path.');
        }
      }
    }
  }

  Future<void> _handleImageSelection(
    File? file,
    Uint8List? bytes,
    String? fileName,
  ) async {
    setState(() {
      _selectedImage = file;
      _imageBytes = bytes;
      _fileName = fileName;
      _currentState = AppState.analyzing;
      _isAnalyzing = true;
    });

    // Smooth scroll to analysis section
    await _scrollToAnalysis();
  }

  Future<void> _scrollToAnalysis() async {
    if (_analysisKey.currentContext != null) {
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Small delay for layout
      await Scrollable.ensureVisible(
        _analysisKey.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showQuizPopup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizIntroScreen()),
    );

    if (result != null && result is QuizData) {
      _quizData = result;
      // Start analysis after quiz completion
      _startAnalysis();
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null && _imageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      // 1. Upload image to Supabase to get a public URL
      final imageUrl = await StorageService.uploadImage(
        file: _selectedImage,
        bytes: _imageBytes,
        fileName: _fileName,
      );

      // 2. Call the new backend to analyze the image
      final analysis = await AnalysisService.analyzeImage(imageUrl);
      _analysisResult = analysis;

      // 3. Get AI-powered recommendations
      if (_quizData == null) {
        throw Exception(
          "Please complete the hair quiz before getting recommendations.",
        );
      }
      final recommendations = await AnalysisService.getRecommendations(
        analysisResult: _analysisResult!,
        quizData: _quizData!.toJson(),
      );

      if (kDebugMode) {
        // Print the raw data to see what we're getting from the backend
        print(
          'DEBUG: Recommendations received: ${recommendations.map((r) => {'id': r.id, 'explanation': r.explanation}).toList()}',
        );
      }

      // Extract ranked IDs and explanations
      final rankedIds = recommendations.map((r) => r.id).toList();
      _explanations = {for (var r in recommendations) r.id: r.explanation};

      // 4. Save the session to Supabase (optional, could be done in parallel)
      await StorageService.saveUploadSession(
        imageUrl: imageUrl,
        analysisData: _analysisResult!,
        quizData: _quizData,
      );

      setState(() {
        _isAnalyzing = false;
        _currentState = AppState.results;
      });

      // 5. Fetch the recommended hairstyles in the correct order
      await _fetchHairstyles(rankedIds: rankedIds);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = e.toString();
      });

      if (!mounted) return;
      _showErrorDialog(_analysisError!);
    }
  }

  Future<void> _saveUploadSession() async {
    // This method is now replaced by the logic in _startAnalysis
    // and can be removed.
  }

  Future<void> _changePhoto() async {
    // Open file picker to replace current photo
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      final file = result.files.single;

      if (kIsWeb) {
        if (file.bytes != null) {
          await _handleImageSelection(null, file.bytes!, file.name);
        }
      } else {
        if (file.path != null) {
          await _handleImageSelection(File(file.path!), null, null);
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        automaticallyImplyLeading: false, // Remove hamburger menu
        title: Row(
          children: [
            const Icon(Icons.content_cut, color: Color(0xFF8B5CF6), size: 24),
            const SizedBox(width: 8),
            Text(_appBarTitle, style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Show full text on wider screens, abbreviated on narrow
              if (MediaQuery.of(context).size.width > 400) {
                return Text(
                  'Your Personal Hair Consultant',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                );
              } else {
                return Text(
                  'Hair Consultant',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                );
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload area or thumbnail
                  _currentState == AppState.upload
                      ? _buildUploadArea()
                      : _buildThumbnailArea(),

                  const SizedBox(height: 24),

                  // Camera button (only show in upload state)
                  if (_currentState == AppState.upload) _buildCameraButton(),

                  // Step 2 - Hair Profile Setup (always show)
                  const SizedBox(height: 32),
                  _buildHairProfileStep(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Recommendations section (full-width)
          SliverToBoxAdapter(child: _buildRecommendations()),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B7280),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: _pickImageFromFiles,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.upload, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Drag and drop your selfie here',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'or click to browse files',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailArea() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Larger thumbnail image
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildThumbnailImage(),
                  ),
                ),
                const SizedBox(height: 16),
                // Photo info
                Text(
                  _fileName ?? 'Uploaded Photo',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for analysis',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8B5CF6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Add the new analyze button here
                if (!_isAnalyzing && _currentState != AppState.results)
                  _buildAnalyzeButton(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Replace photo button
        TextButton(
          onPressed: _changePhoto,
          child: const Text(
            'Replace Photo',
            style: TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailImage() {
    if (kIsWeb) {
      if (_imageBytes != null) {
        return Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
          width: 150,
          height: 150,
        );
      } else {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person, size: 60, color: Color(0xFF8B5CF6)),
        );
      }
    } else {
      if (_selectedImage != null) {
        return Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: 150,
          height: 150,
        );
      } else {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person, size: 60, color: Color(0xFF8B5CF6)),
        );
      }
    }
  }

  Widget _buildCameraButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'You can also ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        TextButton.icon(
          onPressed: _pickImageFromCamera,
          icon: const Icon(Icons.camera_alt, color: Color(0xFF8B5CF6)),
          label: const Text(
            'Take a photo',
            style: TextStyle(
              color: Color(0xFF8B5CF6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton.icon(
      onPressed: _startAnalysis,
      icon: const Icon(Icons.psychology, color: Colors.white),
      label: const Text('Analyze Photo', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHairProfileStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Get your personal hair profile set up',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete a quick assessment about your hair to get personalized recommendations.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white.withAlpha(170)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showQuizPopup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Center(
                  child: Text(
                    'Take Hair Analysis Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Container(
      key: _analysisKey,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Hair Analysis',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),

          if (_isAnalyzing) ...[
            const Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Analyzing your hair and face shape...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(68),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Analysis Complete',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Face Shape: ${_analysisResult?['faceShape']?.toUpperCase() ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._getAnalysisForFaceShape(
              _analysisResult?['faceShape'] ?? 'oval',
            ).map(
              (feedback) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        feedback,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(230),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with proper spacing
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Hairstyle Recommendations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360, // Increased height for larger cards
          child: _hairstylesLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _hairstyles.length,
                  itemBuilder: (context, index) {
                    final hairstyle = _hairstyles[index];
                    final isSelected = _selectedHairstyleId == hairstyle.id;
                    // Determine if any card is selected to apply dimming
                    final isAnyCardSelected = _selectedHairstyleId != null;

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isAnyCardSelected && !isSelected ? 0.5 : 1.0,
                      child: Container(
                        width: 260, // Reverted to a skinnier width
                        margin: EdgeInsets.only(
                          right: index == _hairstyles.length - 1 ? 0 : 16,
                        ),
                        child: _buildHairstyleCard(hairstyle, isSelected),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 24),
        // Explanation section
        _buildExplanationSection(),
      ],
    );
  }

  Widget _buildHairstyleCard(HairstyleData hairstyle, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedHairstyleId == hairstyle.id) {
            _selectedHairstyleId = null; // Deselect if tapped again
          } else {
            _selectedHairstyleId = hairstyle.id; // Select new card
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : const Color(0xFF374151),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hairstyle image with overlay functionality
            Expanded(flex: 5, child: _buildCardImage(hairstyle)),
            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hairstyle.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hairstyle.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(170),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Save / Like controls
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _likedStyles.contains(hairstyle.id)
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _toggleLike(hairstyle.id ?? 0, hairstyle),
                    child: Text(
                      _likedStyles.contains(hairstyle.id)
                          ? 'Saved'
                          : 'Save This Style',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationSection() {
    final explanation = _selectedHairstyleId != null
        ? _explanations[_selectedHairstyleId]
        : null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.vertical,
            child: child,
          ),
        );
      },
      child: explanation != null
          ? Container(
              key: ValueKey<int>(_selectedHairstyleId!),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Why This Style Works For You",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF8B5CF6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    explanation,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey<String>('empty')),
    );
  }

  Widget _buildCardImage(HairstyleData hairstyle) {
    return FutureBuilder<String>(
      future: SupabaseService.getHairstyleCardImageUrl(
        hairstyleId: hairstyle.id!,
        skinTone: _analysisResult?['skin_tone'] ?? 'light',
        assumedRace: _analysisResult?['assumed_race'],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 150,
            width: double.infinity,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildImagePlaceholder(); // Fallback to a generic placeholder
        }

        final imageUrl = snapshot.data!;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          child: Container(
            color: Colors.black, // Background for letterboxing
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.contain, // Show the whole image
              placeholder: (context, url) => _buildImagePlaceholder(),
              errorWidget: (context, url, error) => _buildImageError(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      color: Colors.grey[800],
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 150,
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2025 HairStyle AI. Your personal hair consultant.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Upload your selfie to get personalized hair advice and style recommendations.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods
  List<String> _getAnalysisForFaceShape(String faceShape) {
    switch (faceShape.toLowerCase()) {
      case 'oval':
        return [
          'Perfect balance - you can wear almost any hairstyle',
          'Your face has ideal proportions with gentle curves',
          'Consider styles that maintain your natural symmetry',
          'Both long and short styles will complement your features',
        ];
      case 'round':
        return [
          'Soft curves and width equal to length create a youthful look',
          'Styles with height and volume on top will elongate your face',
          'Side parts work better than center parts',
          'Avoid styles that add width to the sides',
        ];
      case 'square':
        return [
          'Strong, angular features with a defined jawline',
          'Soft, layered styles will balance your strong features',
          'Side-swept bangs can soften your forehead',
          'Avoid blunt cuts that emphasize angularity',
        ];
      case 'heart':
        return [
          'Wider forehead with a narrower chin creates elegant proportions',
          'Styles that add volume at the chin level are ideal',
          'Side-swept bangs will balance your forehead',
          'Avoid too much volume on top',
        ];
      case 'diamond':
        return [
          'Narrow forehead and chin with prominent cheekbones',
          'Styles with volume at the crown and chin work best',
          'Side parts help widen your forehead appearance',
          'Avoid styles that emphasize cheek width',
        ];
      default:
        return [
          'Unique face shape with distinctive characteristics',
          'Consider styles that highlight your best features',
          'Consult with a professional stylist for personalized advice',
          'Experiment with different lengths and textures',
        ];
    }
  }

  void _toggleLike(int index, HairstyleData hairstyle) async {
    setState(() {
      if (_likedStyles.contains(hairstyle.id)) {
        _likedStyles.remove(hairstyle.id);
      } else {
        _likedStyles.add(hairstyle.id!);
      }
    });

    // Persist change
    if (hairstyle.id != null) {
      if (_likedStyles.contains(hairstyle.id)) {
        await SupabaseService.saveStyle(hairstyle.id!);
      } else {
        await SupabaseService.unsaveStyle(hairstyle.id!);
      }
    }
  }

  // Fetch hairstyles from Supabase
  Future<void> _fetchHairstyles({List<int>? rankedIds}) async {
    setState(() {
      _hairstylesLoading = true;
      _hairstylesError = null;
    });

    try {
      final hairstyles = await SupabaseService.getHairstyles(
        rankedIds: rankedIds,
      );

      if (!mounted) return;
      setState(() {
        _hairstyles = hairstyles;
        _hairstylesLoading = false;
        // Reset selection when new hairstyles are loaded
        _selectedHairstyleId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hairstylesLoading = false;
        _hairstylesError =
            'Sorry, our servers are experiencing issues right now. Please try again later.';
      });
      if (kDebugMode) {
        print('Error fetching hairstyles: $e');
      }
    }
  }
}
