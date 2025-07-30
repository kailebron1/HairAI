import 'package:flutter/material.dart';
import 'my_uploads_screen.dart';
import 'saved_styles_screen.dart';
import 'saved_guides_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFF8B5CF6), size: 24),
            SizedBox(width: 8),
            Text('Profile', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HairStyle AI User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your personal hair consultant',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Menu items
            _buildMenuSection([
              _MenuItemData(
                icon: Icons.history,
                title: 'My Uploads',
                subtitle: 'View your uploaded photos and analysis history',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyUploadsScreen(),
                  ),
                ),
              ),
              _MenuItemData(
                icon: Icons.favorite,
                title: 'Saved Styles',
                subtitle: 'Your favorite hairstyles and recommendations',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedStylesScreen(),
                  ),
                ),
              ),
              _MenuItemData(
                icon: Icons.book,
                title: 'Implementation Guides',
                subtitle: 'Your personalized hairstyle guides',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedGuidesScreen(),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            _buildMenuSection([
              _MenuItemData(
                icon: Icons.person_outline,
                title: 'Personal Profile',
                subtitle: 'Manage your hair profile and preferences',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ),
              ),
              _MenuItemData(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Learn more about HairStyle AI',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            _buildMenuSection([
              _MenuItemData(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                isDestructive: true,
                onTap: () => _showSignOutDialog(context),
              ),
            ]),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2025 HairStyle AI',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              _buildMenuItem(item),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.white.withAlpha(25),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item.isDestructive
              ? Colors.red.withAlpha(25)
              : const Color(0xFF8B5CF6).withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.icon,
          color: item.isDestructive ? Colors.red : const Color(0xFF8B5CF6),
          size: 20,
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: item.isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: TextStyle(
          color: item.isDestructive
              ? Colors.red.withAlpha(178)
              : Colors.white.withAlpha(178),
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: item.isDestructive
            ? Colors.red.withAlpha(128)
            : Colors.white.withAlpha(128),
        size: 16,
      ),
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual sign out logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sign out functionality coming soon'),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}
