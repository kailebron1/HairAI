import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAppHeader(context),
            const SizedBox(height: 32),
            _buildAppInfo(context),
            const SizedBox(height: 24),
            _buildFeatures(context),
            const SizedBox(height: 24),
            _buildCredits(context),
            const SizedBox(height: 24),
            _buildContact(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'HairStyle AI',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF8B5CF6)),
          ),
          const SizedBox(height: 12),
          Text(
            'AI-Powered Hair Analysis & Style Recommendations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
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
            'About HairStyle AI',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'HairStyle AI revolutionizes your hair care journey by combining cutting-edge artificial intelligence with personalized styling recommendations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(204),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Whether you\'re looking for a dramatic change or subtle enhancement, our comprehensive database of hairstyles will help you achieve your perfect look.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(204),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      {
        'icon': Icons.camera_alt_outlined,
        'title': 'AI Face Analysis',
        'description': 'Advanced face shape detection and analysis',
      },
      {
        'icon': Icons.style_outlined,
        'title': 'Personalized Recommendations',
        'description': 'Curated hairstyles based on your unique features',
      },
      {
        'icon': Icons.book_outlined,
        'title': 'Step-by-Step Guides',
        'description': 'Detailed tutorials with product recommendations',
      },
      {
        'icon': Icons.favorite_border,
        'title': 'Save & Track',
        'description': 'Save your favorite styles and track your journey',
      },
    ];

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
            'Key Features',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: const Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white.withAlpha(178)),
                        ),
                      ],
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

  Widget _buildCredits(BuildContext context) {
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
            'Credits & Acknowledgments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCreditItem(
            context,
            'UI/UX Design',
            'Modern interface designed for optimal user experience',
          ),
          _buildCreditItem(
            context,
            'AI Technology',
            'Powered by advanced machine learning algorithms',
          ),
          _buildCreditItem(
            context,
            'Hair Experts',
            'In collaboration with top hairstylists',
          ),
          _buildCreditItem(
            context,
            'Photography',
            'High-quality hairstyle images from professionals',
          ),
        ],
      ),
    );
  }

  Widget _buildCreditItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white.withAlpha(178)),
          ),
        ],
      ),
    );
  }

  Widget _buildContact(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildContactItem(
            context,
            'Support & Feedback',
            'support@hairstyleai.app',
            Icons.email_outlined,
          ),
          const Divider(height: 24, color: Colors.white12),
          _buildContactItem(
            context,
            'Follow Us',
            '@HairStyleAI',
            Icons.link_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: subtitle));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied "$subtitle" to clipboard'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Icon(
            Icons.copy_outlined,
            color: Colors.white.withAlpha(128),
            size: 20,
          ),
        ),
      ],
    );
  }
}
