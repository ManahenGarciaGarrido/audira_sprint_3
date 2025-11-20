import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class StudioDashboardScreen extends StatelessWidget {
  const StudioDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Studio'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.mic, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Your Studio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your music and track your success',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 24),
          _buildStudioCard(
            context,
            icon: Icons.upload_file,
            title: 'Upload Song',
            subtitle: 'Add a new song to your catalog',
            color: Colors.purple,
            route: '/studio/upload-song',
          ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 12),
          _buildStudioCard(
            context,
            icon: Icons.album,
            title: 'Upload Album',
            subtitle: 'Create and publish a new album',
            color: Colors.blue,
            route: '/studio/upload-album',
          ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 12),
          _buildStudioCard(
            context,
            icon: Icons.bar_chart,
            title: 'View Statistics',
            subtitle: 'Track your plays, followers, and earnings',
            color: Colors.green,
            route: '/studio/stats',
          ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 12),
          _buildStudioCard(
            context,
            icon: Icons.library_music,
            title: 'My Catalog',
            subtitle: 'View and manage your songs and albums',
            color: Colors.orange,
            route: '/studio/catalog',
          ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 12),
          _buildStudioCard(
            context,
            icon: Icons.people,
            title: 'Collaborations',
            subtitle: 'Manage collaborators and revenue sharing',
            color: Colors.pink,
            route: '/studio/collaborations',
          ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 12),
          _buildStudioCard(
            context,
            icon: Icons.file_upload,
            title: '🧪 Test File Upload',
            subtitle: 'Test audio/image upload and compression',
            color: Colors.teal,
            route: '/studio/file-demo',
          ).animate(delay: 600.ms).fadeIn().slideX(begin: -0.2),
        ],
      ),
    );
  }

  Widget _buildStudioCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
