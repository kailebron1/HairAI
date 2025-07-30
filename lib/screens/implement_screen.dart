import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/analysis_service.dart';

class ImplementScreen extends StatefulWidget {
  const ImplementScreen({super.key});

  @override
  State<ImplementScreen> createState() => _ImplementScreenState();
}

class _ImplementScreenState extends State<ImplementScreen>
    with SingleTickerProviderStateMixin {
  List<HairstyleData> _savedHairstyles = [];
  bool _isLoading = true;
  HairstyleData? _selectedHairstyle;
  bool _isAnalyzing = false;
  String? _error;
  List<String> _userProducts = [];
  bool _showProductInput = false;
  Map<String, dynamic>? _implementationGuide;
  late AnimationController _animationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _otherCardsAnimation;
  late Animation<double> _buttonTextAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _otherCardsAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _buttonTextAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await SupabaseService.initialize();
      final saved = await SupabaseService.fetchSavedStyles();
      if (!mounted) return;

      setState(() {
        _savedHairstyles = saved;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectHairstyle(HairstyleData hairstyle) async {
    setState(() => _selectedHairstyle = hairstyle);
    await _animationController.forward();
  }

  Future<void> _showProductInputDialog() async {
    setState(() => _showProductInput = true);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          "Let's personalize your guide!",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your current hair products:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  maxHeight: 1024,
                );
                if (image != null) {
                  // Upload image and get products from AI
                  final imageUrl = await StorageService.uploadImage(
                    file: File(image.path),
                  );
                  // TODO: Add AI product recognition
                  setState(() {
                    _userProducts = ['Product 1', 'Product 2']; // Placeholder
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                'Upload Product Photo',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Or type your products:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter product name',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _userProducts.add(value);
                  });
                }
              },
            ),
            if (_userProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Your Products:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _userProducts.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF8B5CF6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userProducts[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startAnalysis();
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: Color(0xFF8B5CF6)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      // TODO: Implement AI analysis with OpenAI
      await Future.delayed(const Duration(seconds: 2)); // Placeholder
      setState(() {
        _implementationGuide = {
          'current_analysis': {
            'hair_type': 'Straight',
            'hair_length': 'Medium',
            'hair_health': 'Good',
          },
          'recommended_products': [
            {
              'name': 'Volume Boost Shampoo',
              'link': 'https://amazon.com/sample1',
              'reason': 'Adds body and lift to fine hair',
            },
            {
              'name': 'Heat Protection Spray',
              'link': 'https://amazon.com/sample2',
              'reason': 'Essential for heat styling',
            },
          ],
          'steps': [
            'Start with clean, damp hair using the recommended shampoo',
            'Apply heat protection spray throughout your hair',
            'Section your hair into 4 parts',
            'Use a round brush while blow-drying each section',
          ],
          'maintenance': [
            'Deep condition once a week',
            'Trim ends every 8-10 weeks',
            'Use dry shampoo between washes',
          ],
          'estimated_time': '6-8 weeks',
        };
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  void _resetSelection() {
    _animationController.reverse().then((_) {
      setState(() {
        _selectedHairstyle = null;
        _implementationGuide = null;
        _userProducts.clear();
        _showProductInput = false;
      });
    });
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
        actions: [
          if (_selectedHairstyle != null)
            TextButton(
              onPressed: _resetSelection,
              child: const Text(
                'Choose Different Style',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            )
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _selectedHairstyle == null
                          ? 'Choose Your Hairstyle'
                          : 'Selected Style',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 360,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _savedHairstyles.length,
                      itemBuilder: (context, index) {
                        final hairstyle = _savedHairstyles[index];
                        final isSelected =
                            _selectedHairstyle?.id == hairstyle.id;

                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            if (isSelected) {
                              return Transform.scale(
                                scale: _cardScaleAnimation.value,
                                child: Opacity(opacity: 1.0, child: child),
                              );
                            }
                            return Opacity(
                              opacity: _selectedHairstyle == null
                                  ? 1.0
                                  : _otherCardsAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 260,
                            margin: EdgeInsets.only(
                              right: index == _savedHairstyles.length - 1
                                  ? 0
                                  : 16,
                            ),
                            child: GestureDetector(
                              onTap: _selectedHairstyle == null
                                  ? () => _selectHairstyle(hairstyle)
                                  : null,
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
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(14),
                                          topRight: Radius.circular(14),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: hairstyle.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hairstyle.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isSelected)
                                            AnimatedBuilder(
                                              animation: _buttonTextAnimation,
                                              builder: (context, child) {
                                                return Opacity(
                                                  opacity: _buttonTextAnimation
                                                      .value,
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          top: 12,
                                                        ),
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed:
                                                          !_showProductInput
                                                          ? _showProductInputDialog
                                                          : null,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF8B5CF6,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 12,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Get Guide',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
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
                      },
                    ),
                  ),
                  if (_isAnalyzing)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                            SizedBox(height: 16),
                            Text(
                              'Analyzing your hair and creating your personalized guide...',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_implementationGuide != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Personalized Implementation Guide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildGuideSection(
                            'Current Hair Analysis',
                            _implementationGuide!['current_analysis'].entries
                                .map(
                                  (e) =>
                                      '${e.key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}: ${e.value}',
                                )
                                .toList()
                                .cast<String>(),
                          ),
                          _buildGuideSection(
                            'Recommended Products',
                            _implementationGuide!['recommended_products']
                                .map((p) => '${p['name']}: ${p['reason']}')
                                .toList()
                                .cast<String>(),
                            showBuyLinks: true,
                            products:
                                _implementationGuide!['recommended_products'],
                          ),
                          _buildGuideSection(
                            'Step-by-Step Guide',
                            _implementationGuide!['steps'].cast<String>(),
                          ),
                          _buildGuideSection(
                            'Maintenance Tips',
                            _implementationGuide!['maintenance'].cast<String>(),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Estimated Time: ${_implementationGuide!['estimated_time']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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

  Widget _buildGuideSection(
    String title,
    List<String> items, {
    bool showBuyLinks = false,
    List<Map<String, dynamic>>? products,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        if (showBuyLinks && products != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: Open affiliate link
                              },
                              icon: const Icon(
                                Icons.shopping_cart,
                                color: Color(0xFF8B5CF6),
                                size: 16,
                              ),
                              label: const Text(
                                'Buy on Amazon',
                                style: TextStyle(color: Color(0xFF8B5CF6)),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: const Color(
                                  0xFF8B5CF6,
                                ).withOpacity(0.1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
