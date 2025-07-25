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

  // Supabase integration
  List<HairstyleData> _hairstyles = [];
  bool _hairstylesLoading = false;
  String? _hairstylesError;

  // Keys for sections to enable scrolling
  final GlobalKey _analysisKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchHairstyles();
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

      // 3. Save the session to Supabase
      await StorageService.saveUploadSession(
        imageUrl: imageUrl,
        analysisData: _analysisResult!,
        quizData: _quizData,
      );

      setState(() {
        _isAnalyzing = false;
        _currentState = AppState.results;
      });

      // 4. Fetch personalized recommendations
      _fetchHairstyles(analysisResult: _analysisResult);
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
          height: 450, // Final height to prevent overflow
          child: _hairstylesLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                )
              : _hairstylesError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _hairstylesError!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchHairstyles,
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
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ), // Consistent padding for first and last items
                  itemCount: _hairstyles.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 260,
                      margin: EdgeInsets.only(
                        right: index == _hairstyles.length - 1 ? 0 : 16,
                      ),
                      child: _buildHairstyleCard(_hairstyles[index], index),
                    );
                  },
                ),
        ),
        const SizedBox(height: 32), // Add bottom spacing
      ],
    );
  }

  Widget _buildHairstyleCard(HairstyleData hairstyle, int index) {
    final isLiked = _likedStyles.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLiked ? const Color(0xFF10B981) : const Color(0xFF374151),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hairstyle image - Make clickable to open gallery
          Expanded(
            flex: 5, // Slightly reduce image height to give content more space
            child: GestureDetector(
              onTap: () => _showHairstyleOverlay(hairstyle, index),
              child: SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: hairstyle.imageUrl,
                    fit: BoxFit.cover, // Keep cover to fill the container
                    placeholder: (context, url) => Container(
                      color: Colors.grey[700],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[700],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content section
          Expanded(
            flex: 2, // Increase content area to avoid overflow
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ), // Compact padding
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
                  const SizedBox(height: 4),
                  // "I like this style" button
                  ElevatedButton.icon(
                    onPressed: () => _toggleLike(index, hairstyle),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked
                          ? const Color(0xFFEC4899)
                          : Colors.white70, // Pink when liked
                      size: 18,
                    ),
                    label: const Text('I like this style'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLiked
                          ? const Color(0xFF10B981)
                          : const Color(0xFF374151), // Green when liked
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        double.infinity,
                        44,
                      ), // Full width button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      if (_likedStyles.contains(index)) {
        _likedStyles.remove(index);
        // TODO: Implement removeLikedStyle from Supabase
      } else {
        _likedStyles.add(index);
        // TODO: Implement saveLikedStyle to Supabase
        // StorageService.saveLikedStyle(
        //   hairstyle: hairstyle,
        //   uploadSessionId: _analysisResult!['id'],
        // );
      }
    });
  }

  // Fetch hairstyles from Supabase
  Future<void> _fetchHairstyles({Map<String, dynamic>? analysisResult}) async {
    if (_hairstyles.isNotEmpty && analysisResult == null) {
      return; // Don't fetch if already loaded and not a new analysis
    }

    try {
      setState(() {
        _hairstylesLoading = true;
        _hairstylesError = null;
      });

      final hairstyles = await SupabaseService.getHairstyles(
        analysis: analysisResult,
      );

      if (!mounted) return;
      setState(() {
        _hairstyles = hairstyles;
        _hairstylesLoading = false;
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

  void _showHairstyleOverlay(HairstyleData hairstyle, int cardIndex) async {
    // Fetch images from Supabase database for all hairstyles
    final images = await SupabaseService.getHairstyleImages(
      hairstyle.id!,
      skinTone:
          null, // Don't filter by skin tone - get all images for this hairstyle
    );

    if (!mounted) return;

    // ignore: use_build_context_synchronously
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        builder: (context) => _HairstyleOverlayModal(
          hairstyle: hairstyle,
          images: images,
          isLiked: _likedStyles.contains(cardIndex),
          onLikeToggle: () => _toggleLike(cardIndex, hairstyle),
        ),
      );
    }
  }
}

class _HairstyleOverlayModal extends StatefulWidget {
  final HairstyleData hairstyle;
  final List<HairstyleImage> images;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const _HairstyleOverlayModal({
    required this.hairstyle,
    required this.images,
    required this.isLiked,
    required this.onLikeToggle,
  });

  @override
  State<_HairstyleOverlayModal> createState() => _HairstyleOverlayModalState();
}

class _HairstyleOverlayModalState extends State<_HairstyleOverlayModal> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = screenSize.width * 0.9; // Increased to 90% width
    final modalHeight = screenSize.height * 0.85; // Increased to 85% height

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: modalWidth,
        height: modalHeight,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          // Wrap everything in SingleChildScrollView
          child: SizedBox(
            height: modalHeight,
            child: Column(
              children: [
                // Top controls
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button (X)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      // Heart button
                      IconButton(
                        onPressed: () {
                          widget.onLikeToggle();
                          setState(() {}); // Trigger rebuild to update heart
                        },
                        icon: Icon(
                          widget.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isLiked
                              ? const Color(0xFFEC4899)
                              : Colors.white.withAlpha(170),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Image gallery - use more space
                Expanded(
                  flex: 3, // Give more space to the image gallery
                  child: widget.images.isEmpty
                      ? const Center(
                          child: Text(
                            'No images available',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        )
                      : Stack(
                          children: [
                            // PageView for horizontal scrolling
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                              itemCount: widget.images.length,
                              itemBuilder: (context, index) {
                                final imageUrl = widget
                                    .images[index]
                                    .imageUrl; // Use URL as-is, no normalization

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      // Use Image.network instead of CachedNetworkImage
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey[800],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: const Color(0xFF8B5CF6),
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
                                            color: Colors.grey[800],
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.white54,
                                                  size: 60,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Failed to load image ${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Left arrow
                            if (widget.images.length > 1 && _currentIndex > 0)
                              Positioned(
                                left: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: IconButton(
                                    onPressed: _previousImage,
                                    icon: const Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                ),
                              ),

                            // Right arrow
                            if (widget.images.length > 1 &&
                                _currentIndex < widget.images.length - 1)
                              Positioned(
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: IconButton(
                                    onPressed: _nextImage,
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                ),
                              ),

                            // Navigation dots
                            if (widget.images.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      widget.images.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: index == _currentIndex
                                              ? Colors.white
                                              : Colors.white.withAlpha(102),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                // Hairstyle info at bottom - use less space
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Important: minimize space
                    children: [
                      Text(
                        widget.hairstyle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22, // Slightly smaller
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      Text(
                        widget.hairstyle.description,
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 14, // Slightly smaller
                          height: 1.3, // Reduced line height
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3, // Limit lines to prevent overflow
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is a demo showing how results would look.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(178),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
