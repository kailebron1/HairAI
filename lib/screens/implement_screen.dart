import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class ImplementScreen extends StatefulWidget {
  const ImplementScreen({super.key});

  @override
  State<ImplementScreen> createState() => _ImplementScreenState();
}

class _ImplementScreenState extends State<ImplementScreen> {
  List<SavedHairstyle> _savedHairstyles = [];
  List<HairstyleData> _allHairstyles = [];
  bool _isLoading = true;
  bool _isSelectingStyle = false;
  HairstyleData? _selectedHairstyle;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _implementationGuideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // TODO: Re-implement saved hairstyles with Supabase.
      // For now, load all hairstyles directly.
      final allStyles = await SupabaseService.getHairstyles();
      if (!mounted) return;

      setState(() {
        _allHairstyles = allStyles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectHairstyle(HairstyleData hairstyle) async {
    setState(() {
      _isSelectingStyle = true;
    });

    // Show loading for 1 second
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _selectedHairstyle = hairstyle;
      _isSelectingStyle = false;
    });

    // Scroll to implementation guide
    await _scrollToImplementationGuide();
  }

  Future<void> _scrollToImplementationGuide() async {
    if (_implementationGuideKey.currentContext != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      await Scrollable.ensureVisible(
        _implementationGuideKey.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.build, color: Color(0xFF8B5CF6), size: 24),
            SizedBox(width: 8),
            Text('Implement', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        // No padding here
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section wrapped in padding
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Hairstyle',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _savedHairstyles.isNotEmpty
                        ? 'Select a hairstyle from your saved styles to get implementation instructions.'
                        : 'Select any hairstyle to get detailed implementation instructions.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Gallery and loading state are NOT in padding
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                ),
              )
            else
              _buildHairstylesGallery(_allHairstyles),

            // The rest of the content below the gallery is wrapped in padding
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_isSelectingStyle) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading implementation guide...',
                            style: TextStyle(
                              color: Colors.white.withAlpha(178),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_selectedHairstyle != null && !_isSelectingStyle) ...[
                    const SizedBox(height: 40),
                    _buildImplementationGuide(),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable horizontal gallery builder - reverted to simple version
  Widget _buildHairstylesGallery(List<HairstyleData> styles) {
    return SizedBox(
      height: 450, // Match AnalyzeScreen
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: styles.length,
        itemBuilder: (context, index) {
          return Container(
            width: 260,
            margin: EdgeInsets.only(right: index == styles.length - 1 ? 0 : 16),
            child: _buildHairstyleCard(styles[index]),
          );
        },
      ),
    );
  }

  Widget _buildHairstyleCard(HairstyleData hairstyle) {
    final isSelected = _selectedHairstyle?.id == hairstyle.id;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF374151), // Always grey like Analyze screen
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hairstyle image with overlay functionality
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () => _showHairstyleOverlay(hairstyle),
              child: SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: hairstyle.imageUrl,
                    fit: BoxFit.cover,
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
                  const SizedBox(height: 4),
                  // View Guide button
                  ElevatedButton(
                    onPressed: () => _selectHairstyle(hairstyle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Guide'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show overlay gallery similar to AnalyzeScreen
  void _showHairstyleOverlay(HairstyleData hairstyle) async {
    final images = await SupabaseService.getHairstyleImages(hairstyle.id!);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) =>
          _HairstyleOverlayModal(hairstyle: hairstyle, images: images),
    );
  }

  Widget _buildImplementationGuide() {
    if (_selectedHairstyle == null) return const SizedBox.shrink();

    return Container(
      key: _implementationGuideKey,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Implementation Guide: ${_selectedHairstyle!.name}',
            key: _implementationGuideKey,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow these steps to achieve your new look. For best results, show this guide to your barber.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(204),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Tools and products
          _buildSection(
            icon: Icons.cut,
            title: 'Tools & Products',
            content: _buildToolsAndProductsList(),
          ),

          const SizedBox(height: 24),

          // Step-by-step guide
          _buildSection(
            icon: Icons.list_alt,
            title: 'Step-by-Step Guide',
            content: _buildStepsList(),
          ),

          const SizedBox(height: 24),

          // Pro-tips section
          _buildSection(
            icon: Icons.lightbulb_outline,
            title: 'Pro Tips',
            content: _buildProTipsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildToolsAndProductsList() {
    return Column(
      children: [
        _buildListItem(
          'Clippers with guards (#1, #2, #3)',
          'Essential for fading',
        ),
        _buildListItem('Trimmer', 'For clean lines and edges'),
        _buildListItem('Styling pomade or wax', 'For hold and texture'),
        _buildListItem('Comb', 'For precision styling'),
      ],
    );
  }

  Widget _buildStepsList() {
    return Column(
      children: (_selectedHairstyle!.steps)
          .asMap()
          .entries
          .map((entry) => _buildStepItem('Step ${entry.key + 1}', entry.value))
          .toList(),
    );
  }

  Widget _buildProTipsList() {
    return Column(
      children: (_selectedHairstyle!.proTips ?? [])
          .map((tip) => _buildListItem(tip, null))
          .toList(),
    );
  }

  Widget _buildListItem(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(178),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                step.split(' ')[1],
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    height: 1.4,
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

class _HairstyleOverlayModal extends StatefulWidget {
  final HairstyleData hairstyle;
  final List<HairstyleImage> images;

  const _HairstyleOverlayModal({required this.hairstyle, required this.images});

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
    final modalWidth = screenSize.width * 0.9;
    final modalHeight = screenSize.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: modalWidth,
        height: modalHeight,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Top bar with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Image gallery
            Expanded(
              flex: 3,
              child: widget.images.isEmpty
                  ? const Center(
                      child: Text(
                        'No images available',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: widget.images.length,
                          itemBuilder: (context, index) {
                            final url = widget.images[index].imageUrl;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white54,
                                            size: 60,
                                          ),
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

                        // Dots
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

            // Info section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.hairstyle.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.hairstyle.description,
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
