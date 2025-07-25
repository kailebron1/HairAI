import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class HairQuizPopup extends StatefulWidget {
  final Function(QuizData) onComplete;
  final VoidCallback onSkip;

  const HairQuizPopup({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<HairQuizPopup> createState() => _HairQuizPopupState();
}

class _HairQuizPopupState extends State<HairQuizPopup> {
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
    _hairGoalsController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  void _showPorosityInfo() {
    showDialog(
      context: context,
      builder: (context) => const PorosityInfoDialog(),
    );
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Are you sure?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'If you skip, your results will not be as accurate.',
          style: TextStyle(color: Colors.white.withAlpha(178)),
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
              Navigator.pop(context);
              widget.onSkip();
            },
            child: const Text(
              'Skip Anyway',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _submitQuiz() {
    final quizData = QuizData(
      hairTexture: _selectedTexture,
      hairPorosity: _selectedPorosity,
      timeAvailable: _timeAvailable,
      style: _selectedStyle,
      hairGoals: _hairGoalsController.text,
      featuresHighlight: _featuresController.text,
    );

    widget.onComplete(quizData);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.quiz, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Hair Analysis Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _showSkipConfirmation,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Quiz Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hair Texture
                    _buildQuestionTitle('What is your hair texture?'),
                    const SizedBox(height: 12),
                    _buildRadioOptions(_textureOptions, _selectedTexture, (
                      value,
                    ) {
                      setState(() => _selectedTexture = value);
                    }),
                    const SizedBox(height: 24),

                    // Hair Porosity
                    _buildQuestionTitle('What is your hair porosity?'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showPorosityInfo,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'What does this mean?',
                                style: TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOptions(_porosityOptions, _selectedPorosity, (
                      value,
                    ) {
                      setState(() => _selectedPorosity = value);
                    }),
                    const SizedBox(height: 24),

                    // Time Available
                    _buildQuestionTitle(
                      'How much time do you have for styling?',
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlider(),
                    const SizedBox(height: 24),

                    // Style Preference
                    _buildQuestionTitle('What style do you prefer?'),
                    const SizedBox(height: 12),
                    _buildRadioOptions(_styleOptions, _selectedStyle, (value) {
                      setState(() => _selectedStyle = value);
                    }),
                    const SizedBox(height: 24),

                    // Hair Goals
                    _buildQuestionTitle('What are your hair goals?'),
                    const SizedBox(height: 8),
                    _buildExampleText(
                      'e.g., grow longer, add volume, easier maintenance',
                    ),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      _hairGoalsController,
                      'Describe your hair goals...',
                    ),
                    const SizedBox(height: 24),

                    // Features to Highlight
                    _buildQuestionTitle(
                      'Any features you want to highlight or minimize?',
                    ),
                    const SizedBox(height: 8),
                    _buildExampleText(
                      'e.g., draw attention to eyes, minimize forehead',
                    ),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      _featuresController,
                      'Describe features...',
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showSkipConfirmation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Complete Quiz',
                        style: TextStyle(color: Colors.white),
                      ),
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

  Widget _buildQuestionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRadioOptions(
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          value: option,
          groupValue: selectedValue,
          onChanged: (value) => onChanged(value!),
          title: Text(option, style: const TextStyle(color: Colors.white)),
          activeColor: const Color(0xFF8B5CF6),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlider() {
    return Column(
      children: [
        Slider(
          value: _timeAvailable,
          min: 0,
          max: 30,
          divisions: 6,
          activeColor: const Color(0xFF8B5CF6),
          inactiveColor: const Color(0xFF8B5CF6).withAlpha(77),
          onChanged: (value) {
            setState(() => _timeAvailable = value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 min',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              _timeAvailable >= 30
                  ? '30+ min'
                  : '${_timeAvailable.round()} min',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '30+ min',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExampleText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: 2,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white30),
        ),
      ),
    );
  }
}

class TextureInfoDialog extends StatelessWidget {
  const TextureInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.texture, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'How to check hair texture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The Feel Test',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Visual Steps
                    _buildTextureStep(
                      1,
                      'Take a Hair',
                      'Pull out a single strand of clean, dry hair',
                      const Icon(Icons.gesture, color: Colors.white, size: 30),
                    ),
                    _buildTextureStep(
                      2,
                      'Roll Between Fingers',
                      'Roll the strand between your thumb and index finger',
                      const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    _buildTextureStep(
                      3,
                      'Assess the Feel',
                      'Determine the thickness and texture',
                      const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Results:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildTextureResult(
                      'Fine',
                      'You can barely feel the strand',
                      const Color(0xFFC084FC),
                    ),
                    _buildTextureResult(
                      'Medium',
                      'You can feel it, but it doesn\'t feel wiry',
                      const Color(0xFFAD7BF4),
                    ),
                    _buildTextureResult(
                      'Coarse',
                      'Feels thick or wiry between your fingers',
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextureResult(String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextureStep(
    int number,
    String title,
    String description,
    Widget icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Step number
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),
          // Icon moved to the far right
          SizedBox(width: 40, height: 40, child: icon),
        ],
      ),
    );
  }
}

class PorosityInfoDialog extends StatelessWidget {
  const PorosityInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'How to check hair porosity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visual Steps
                    _buildCustomStep(
                      1,
                      'Pluck a Hair',
                      'Pull out a single strand of clean hair',
                      const Icon(Icons.gesture, color: Colors.white, size: 30),
                    ),
                    _buildCustomStep(
                      2,
                      'Put in Water',
                      'Drop the strand in a glass of room temp water',
                      const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    _buildCustomStep(
                      3,
                      'Wait & Observe',
                      'Wait 2-4 minutes and see where the hair goes',
                      const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Tips:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Best results: Test after a wash with room temperature water. Wait 2-4 minutes before observing. Note: Hair products can affect accuracy.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Results:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildResult(
                      'Low Porosity',
                      'Hair floats on top',
                      const Color(0xFFC084FC),
                    ),
                    _buildResult(
                      'Medium Porosity',
                      'Hair sinks slowly and stays in middle',
                      const Color(0xFFAD7BF4),
                    ),
                    _buildResult(
                      'High Porosity',
                      'Hair sinks to the bottom',
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStep(
    int number,
    String title,
    String description,
    Widget visual,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withAlpha(25),
            const Color(0xFFEC4899).withAlpha(25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          visual,
        ],
      ),
    );
  }
}
