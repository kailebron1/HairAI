import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';
import 'hairstyle_detail_screen.dart';

class SavedStylesScreen extends StatefulWidget {
  const SavedStylesScreen({super.key});

  @override
  State<SavedStylesScreen> createState() => _SavedStylesScreenState();
}

class _SavedStylesScreenState extends State<SavedStylesScreen> {
  List<SavedHairstyle> _savedHairstyles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedHairstyles();
  }

  Future<void> _loadSavedHairstyles() async {
    // TODO: Re-implement this with Supabase
    setState(() {
      _savedHairstyles = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Saved Styles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedHairstyles.isEmpty
          ? _buildEmptyState()
          : _buildSavedStylesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.white.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved styles yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white.withAlpha(178),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Like hairstyles to save them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedStylesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedHairstyles.length,
      itemBuilder: (context, index) {
        final savedStyle = _savedHairstyles[index];
        return _buildSavedStyleCard(savedStyle);
      },
    );
  }

  Widget _buildSavedStyleCard(SavedHairstyle savedStyle) {
    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToHairstyleDetail(savedStyle),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Hairstyle image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: savedStyle.hairstyle.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[700],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[700],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Hairstyle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      savedStyle.hairstyle.name,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      savedStyle.hairstyle.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(178),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFEC4899),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(savedStyle.savedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                color: const Color(0xFF2D2D2D),
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeStyle(savedStyle);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Text(
                      'Remove from saved',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Saved today';
    } else if (difference.inDays == 1) {
      return 'Saved yesterday';
    } else if (difference.inDays < 7) {
      return 'Saved ${difference.inDays} days ago';
    } else {
      return 'Saved ${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToHairstyleDetail(SavedHairstyle savedStyle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HairstyleDetailScreen(savedHairstyle: savedStyle),
      ),
    );
  }

  void _removeStyle(SavedHairstyle savedStyle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Remove Style',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${savedStyle.hairstyle.name}" from your saved styles?',
          style: const TextStyle(color: Colors.white70),
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
            onPressed: () async {
              if (!mounted) return;
              // TODO: Re-implement this with Supabase
              // await StorageService.removeSavedStyle(savedStyle.id);
              if (!mounted) return;
              Navigator.pop(context);
              _loadSavedHairstyles();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
