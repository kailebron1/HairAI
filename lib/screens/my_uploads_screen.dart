import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'analyze_screen.dart';

class MyUploadsScreen extends StatefulWidget {
  const MyUploadsScreen({super.key});

  @override
  State<MyUploadsScreen> createState() => _MyUploadsScreenState();
}

class _MyUploadsScreenState extends State<MyUploadsScreen> {
  List<UploadSession> _uploadSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUploadSessions();
  }

  Future<void> _loadUploadSessions() async {
    try {
      final sessions = await StorageService.getUploadSessions();
      setState(() {
        _uploadSessions = sessions
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('My Uploads'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _uploadSessions.isEmpty
          ? _buildEmptyState()
          : _buildUploadsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 80,
            color: Colors.white.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            'No uploads yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white.withAlpha(178),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first photo to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _uploadSessions.length,
      itemBuilder: (context, index) {
        final session = _uploadSessions[index];
        return _buildUploadCard(session);
      },
    );
  }

  Widget _buildUploadCard(UploadSession session) {
    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToAnalysis(session),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[700],
                  child: CachedNetworkImage(
                    imageUrl: session.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B5CF6),
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Upload info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyzed on ${_formatDate(session.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(178),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Face Shape: ${session.faceShape ?? 'N/A'}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Skin Tone: ${session.skinTone ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
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
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToAnalysis(UploadSession session) {
    if (kIsWeb) {
      // For web, show a demo message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo mode: Photo analysis not available on web'),
        ),
      );
    } else {
      // For mobile, navigate back to the upload screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnalyzeScreen()),
      );
    }
  }
}
