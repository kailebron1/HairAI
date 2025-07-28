import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/supabase_service.dart';

class ExploreStylesScreen extends StatefulWidget {
  const ExploreStylesScreen({super.key});

  @override
  State<ExploreStylesScreen> createState() => _ExploreStylesScreenState();
}

class _ExploreStylesScreenState extends State<ExploreStylesScreen> {
  bool _loading = true;
  String? _error;
  List<HairstyleData> _all = [];
  final Set<int> _liked = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await SupabaseService.initialize();
      final ids = await SupabaseService.fetchSavedStyleIds();
      final styles = await SupabaseService.getHairstyles();
      if (!mounted) return;
      setState(() {
        _liked.addAll(ids);
        _all = styles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleLike(HairstyleData h) async {
    setState(() {
      if (_liked.contains(h.id)) {
        _liked.remove(h.id);
      } else {
        _liked.add(h.id!);
      }
    });
    if (h.id != null) {
      if (_liked.contains(h.id)) {
        await SupabaseService.saveStyle(h.id!);
      } else {
        await SupabaseService.unsaveStyle(h.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final short = _all
        .where((h) => (h.hairLength ?? '').toLowerCase() == 'short')
        .toList();
    final medium = _all
        .where((h) => (h.hairLength ?? '').toLowerCase() == 'medium')
        .toList();
    final long = _all
        .where((h) => (h.hairLength ?? '').toLowerCase() == 'long')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Explore All Styles',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            )
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Short', short),
                  _buildSection('Medium', medium),
                  _buildSection('Long', long),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<HairstyleData> items) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final h = items[index];
              return Container(
                width: 260,
                margin: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : 16,
                ),
                child: _buildCard(h),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(HairstyleData h) {
    final liked = _liked.contains(h.id);
    return GestureDetector(
      onTap: () => _toggleLike(h),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: liked ? const Color(0xFF8B5CF6) : const Color(0xFF374151),
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
                  imageUrl: h.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      h.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? const Color(0xFF8B5CF6) : Colors.white54,
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
