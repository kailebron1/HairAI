import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/hair_quiz_popup.dart';

class QuizWizardScreen extends StatefulWidget {
  const QuizWizardScreen({super.key});

  @override
  State<QuizWizardScreen> createState() => _QuizWizardScreenState();
}

class _QuizWizardScreenState extends State<QuizWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Quiz data
  String _selectedTexture = 'Fine';
  String _selectedPorosity = 'Low';
  double _timeAvailable = 15.0;
  String _selectedStyle = 'Professional';
  final TextEditingController _hairGoalsController = TextEditingController();
  final TextEditingController _featuresController = TextEditingController();

  final List<String> _textureOptions = ['Fine', 'Thick', 'Curly', 'Straight'];
  final List<String> _porosityOptions = ['Low', 'Medium', 'High'];
  final List<String> _styleOptions = [
    'Professional',
    'Edgy',
    'Casual',
    'Trendy',
    'Classic',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _hairGoalsController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeQuiz() {
    final quizData = QuizData(
      hairTexture: _selectedTexture,
      hairPorosity: _selectedPorosity,
      timeAvailable: _timeAvailable,
      style: _selectedStyle,
      hairGoals: _hairGoalsController.text,
      featuresHighlight: _featuresController.text,
    );

    // Return to intro screen first, then to upload screen with quiz data
    Navigator.pop(context, quizData);
  }

  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Quiz?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B5CF6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            child: const Text(
              'Exit Anyway',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  bool _isFirstStep() {
    return _currentStep == 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isFirstStep(),
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        _previousStep();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Progress bar
              _buildProgressBar(),

              // Quiz content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildTextureStep(),
                    _buildPorosityStep(),
                    _buildTimeStep(),
                    _buildStyleStep(),
                    _buildHairGoalsStep(),
                    _buildFeaturesStep(),
                  ],
                ),
              ),

              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentStep > 0 ? _previousStep : _showExitWarning,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Hair Analysis Quiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showExitWarning,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  color: Colors.white.withAlpha(119),
                  fontSize: 14,
                ),
              ),
              Text(
                _currentStep == _totalSteps - 1
                    ? '95%'
                    : '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.white.withAlpha(25),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width:
                      MediaQuery.of(context).size.width *
                          (_currentStep == _totalSteps - 1
                              ? 0.95
                              : (_currentStep + 1) / _totalSteps) -
                      40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextureStep() {
    return _buildQuestionStep(
      title: 'What is your hair texture?',
      subtitle:
          'This helps us recommend styles that work with your natural hair.',
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showTextureInfo(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF8B5CF6),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'What does this mean?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._textureOptions.map((texture) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _selectedTexture == texture
                    ? const Color(0xFF8B5CF6).withAlpha(51)
                    : const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedTexture == texture
                      ? const Color(0xFF8B5CF6)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: RadioListTile<String>(
                value: texture,
                groupValue: _selectedTexture,
                onChanged: (value) => setState(() => _selectedTexture = value!),
                title: Text(
                  texture,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: const Color(0xFF8B5CF6),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPorosityStep() {
    return _buildQuestionStep(
      title: 'What is your hair porosity?',
      subtitle: 'This determines how your hair absorbs and retains moisture.',
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showPorosityInfo(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF8B5CF6),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'What does this mean?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...(_porosityOptions.map((porosity) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _selectedPorosity == porosity
                    ? const Color(0xFF8B5CF6).withAlpha(51)
                    : const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedPorosity == porosity
                      ? const Color(0xFF8B5CF6)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: RadioListTile<String>(
                value: porosity,
                groupValue: _selectedPorosity,
                onChanged: (value) =>
                    setState(() => _selectedPorosity = value!),
                title: Text(
                  porosity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: const Color(0xFF8B5CF6),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildTimeStep() {
    return _buildQuestionStep(
      title: 'How much time do you have for styling?',
      subtitle: 'We\'ll recommend styles that fit your schedule.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  _timeAvailable >= 30
                      ? '30+ minutes'
                      : '${_timeAvailable.round()} minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                  ),
                  child: Slider(
                    value: _timeAvailable,
                    min: 0,
                    max: 30,
                    divisions: 6,
                    activeColor: const Color(0xFF8B5CF6),
                    inactiveColor: const Color(0xFF8B5CF6).withAlpha(76),
                    onChanged: (value) {
                      setState(() => _timeAvailable = value);
                    },
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0 min',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '30+ min',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleStep() {
    return _buildQuestionStep(
      title: 'What style do you prefer?',
      subtitle: 'Choose the vibe that matches your personality.',
      child: Column(
        children: _styleOptions.map((style) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _selectedStyle == style
                  ? const Color(0xFF8B5CF6).withAlpha(51)
                  : const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedStyle == style
                    ? const Color(0xFF8B5CF6)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: RadioListTile<String>(
              value: style,
              groupValue: _selectedStyle,
              onChanged: (value) => setState(() => _selectedStyle = value!),
              title: Text(
                style,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              activeColor: const Color(0xFF8B5CF6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHairGoalsStep() {
    return _buildQuestionStep(
      title: 'What are your hair goals?',
      subtitle: 'Tell us what you want to achieve with your hair.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Examples: grow longer, add volume, easier maintenance, enhance curls',
            style: TextStyle(
              color: Colors.white.withAlpha(102),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hairGoalsController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your hair goals...',
              hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
              filled: true,
              fillColor: const Color(0xFF2D2D2D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesStep() {
    return _buildQuestionStep(
      title: 'Features to highlight or minimize?',
      subtitle: 'Help us recommend styles that flatter your best features.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Examples: draw attention to eyes, minimize forehead, enhance cheekbones',
            style: TextStyle(
              color: Colors.white.withAlpha(102),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _featuresController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe features you want to highlight or minimize...',
              hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
              filled: true,
              fillColor: const Color(0xFF2D2D2D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStep({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withAlpha(178),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep < _totalSteps - 1
                  ? _nextStep
                  : _completeQuiz,
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
                child: Center(
                  child: Text(
                    _currentStep < _totalSteps - 1 ? 'Next' : 'Complete Quiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPorosityInfo() {
    showDialog(
      context: context,
      builder: (context) => const PorosityInfoDialog(),
    );
  }

  void _showTextureInfo() {
    showDialog(
      context: context,
      builder: (context) => const TextureInfoDialog(),
    );
  }
}
