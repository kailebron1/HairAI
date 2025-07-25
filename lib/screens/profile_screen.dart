import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'quiz_intro_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _emailUpdatesEnabled = false;

  // Hair profile data
  String? _hairTexture;
  String? _hairPorosity;
  double _stylingTime = 15.0;
  String? _stylePreference;
  String? _hairGoals;
  String? _featuresToHighlight;
  String? _featuresToMinimize;

  @override
  void initState() {
    super.initState();
    _loadHairProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadHairProfile() async {
    try {
      final sessions = await StorageService.getUploadSessions();
      if (sessions.isNotEmpty) {
        final latestSession = sessions.last;
        if (latestSession.quizData != null) {
          setState(() {
            _hairTexture = latestSession.quizData!.hairTexture;
            _hairPorosity = latestSession.quizData!.hairPorosity;
            _stylingTime = latestSession.quizData!.timeAvailable;
            _stylePreference = latestSession.quizData!.style;
            _hairGoals = latestSession.quizData!.hairGoals;
            _featuresToHighlight = latestSession.quizData!.featuresHighlight;
            _featuresToMinimize = null; // Not available in QuizData
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _editHairProfile() {
    // Navigate to quiz intro screen to retake the quiz
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizIntroScreen()),
    ).then((result) {
      if (result != null && result is QuizData) {
        setState(() {
          _hairTexture = result.hairTexture;
          _hairPorosity = result.hairPorosity;
          _stylingTime = result.timeAvailable;
          _stylePreference = result.style;
          _hairGoals = result.hairGoals;
          _featuresToHighlight = result.featuresHighlight;
          _featuresToMinimize = null; // Not available in QuizData
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF8B5CF6)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildPersonalInfo(),
            const SizedBox(height: 24),
            _buildHairProfile(),
            const SizedBox(height: 24),
            _buildPreferences(),
            const SizedBox(height: 24),
            _buildAccountActions(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[700],
              border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
            ),
            child: const Icon(Icons.person, size: 60, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome Back!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile to get personalized recommendations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildHairProfile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hair Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_hairTexture != null || _hairPorosity != null)
                TextButton(
                  onPressed: _editHairProfile,
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: Color(0xFF8B5CF6)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_hairTexture == null && _hairPorosity == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(77)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.content_cut,
                    color: Color(0xFF8B5CF6),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your hair profile',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload a photo and take the hair assessment to get personalized recommendations',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withAlpha(178),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildHairProfileItem('Hair Texture', _hairTexture),
            _buildHairProfileItem('Hair Porosity', _hairPorosity),
            _buildHairProfileItem(
              'Styling Time',
              '${_stylingTime.round()} minutes',
            ),
            _buildHairProfileItem('Style Preference', _stylePreference),
            if (_hairGoals != null)
              _buildHairProfileItem('Hair Goals', _hairGoals),
            if (_featuresToHighlight != null)
              _buildHairProfileItem(
                'Features to Highlight',
                _featuresToHighlight,
              ),
            if (_featuresToMinimize != null)
              _buildHairProfileItem(
                'Features to Minimize',
                _featuresToMinimize,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHairProfileItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withAlpha(128),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value ?? 'Not set',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: value != null
                    ? Colors.white
                    : Colors.white.withAlpha(128),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
            prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferences() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Get notified about new hairstyle trends',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Email Updates',
            subtitle: 'Receive weekly hairstyle tips and guides',
            value: _emailUpdatesEnabled,
            onChanged: (value) {
              setState(() {
                _emailUpdatesEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(178),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings coming soon'),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with your account',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support coming soon'),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            isDestructive: true,
            onTap: () {
              _showSignOutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFF8B5CF6),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDestructive ? Colors.red : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withAlpha(178),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withAlpha(77),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    // TODO: Implement profile saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully'),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
