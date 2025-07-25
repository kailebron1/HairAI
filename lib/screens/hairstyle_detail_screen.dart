import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class HairstyleDetailScreen extends StatelessWidget {
  final SavedHairstyle savedHairstyle;

  const HairstyleDetailScreen({super.key, required this.savedHairstyle});

  @override
  Widget build(BuildContext context) {
    final hairstyle = savedHairstyle.hairstyle;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(hairstyle.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHairstyleImage(context, hairstyle),
            const SizedBox(height: 24),
            _buildHairstyleInfo(context, hairstyle),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHairstyleImage(BuildContext context, HairstyleData hairstyle) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: CachedNetworkImage(
        imageUrl: hairstyle.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[700],
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[700],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 80,
                ),
                SizedBox(height: 16),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHairstyleInfo(BuildContext context, HairstyleData hairstyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hairstyle.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hairstyle.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(204),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildSavedInfo(context),
          const SizedBox(height: 24),
          _buildQuickSteps(context, hairstyle),
        ],
      ),
    );
  }

  Widget _buildSavedInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Color(0xFFEC4899), size: 20),
          const SizedBox(width: 8),
          Text(
            'Saved ${_formatDate(savedHairstyle.savedAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8B5CF6)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSteps(BuildContext context, HairstyleData hairstyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...hairstyle.steps
            .take(3)
            .map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                      child: Text(
                        step,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(204),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (hairstyle.steps.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${hairstyle.steps.length - 3} more steps in the full guide',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8B5CF6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToImplementationGuide(context),
              icon: const Icon(Icons.book),
              label: const Text('View Implementation Guide'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareHairstyle(context),
              icon: const Icon(Icons.share),
              label: const Text('Share Style'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'on ${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToImplementationGuide(BuildContext context) {
    // Show message to use the Implement tab
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Implementation guides are now available in the Implement tab. Select this hairstyle there to get detailed instructions.',
        ),
        backgroundColor: Color(0xFF8B5CF6),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _shareHairstyle(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${savedHairstyle.hairstyle.name}" style...'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }
}
