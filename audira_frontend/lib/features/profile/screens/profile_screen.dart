import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    debugPrint(user?.toString());

    if (user == null) {
      return const Center(
        child: Text('Usuario no disponible'),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header with Stack (Banner + Profile Picture)
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner Background
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: user.bannerImageUrl == null
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.8),
                          AppTheme.primaryBlue.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: user.bannerImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user.bannerImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: -0.2),

            // Profile Picture - Positioned overlapping the banner
            Positioned(
              bottom: -50,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryBlue,
                  child: user.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.profileImageUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                ),
              ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
            ),

            // Badges and Role - Top right
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      user.role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (user.verifiedArtist == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3),
            ),
          ],
        ),

        // User Info Section - Below the avatar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2),

              const SizedBox(height: 4),

              // Username
              Row(
                children: [
                  Text(
                    '@${user.username}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                  ),
                  if (user.isArtist && user.artistName != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textGrey,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),

              const SizedBox(height: 16),

              // Social Media Links - Lista vertical
              if (user.twitterUrl != null ||
                  user.instagramUrl != null ||
                  user.facebookUrl != null ||
                  user.youtubeUrl != null ||
                  user.spotifyUrl != null ||
                  user.tiktokUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user.twitterUrl != null)
                      _buildSocialMediaLink(
                        context: context,
                        icon: Icons.alternate_email,
                        label: 'Twitter/X',
                        color: const Color(0xFF1DA1F2),
                        url: user.twitterUrl!,
                      ),
                    if (user.instagramUrl != null)
                      _buildSocialMediaLink(
                        context: context,
                        icon: Icons.camera_alt,
                        label: 'Instagram',
                        color: const Color(0xFFE4405F),
                        url: user.instagramUrl!,
                      ),
                    if (user.facebookUrl != null)
                      _buildSocialMediaLink(
                        context: context,
                        icon: Icons.facebook,
                        label: 'Facebook',
                        color: const Color(0xFF1877F2),
                        url: user.facebookUrl!,
                      ),
                    if (user.youtubeUrl != null)
                      _buildSocialMediaLink(
                        context: context,
                        icon: Icons.play_circle_outline,
                        label: 'YouTube',
                        color: const Color(0xFFFF0000),
                        url: user.youtubeUrl!,
                      ),
                    if (user.spotifyUrl != null)
                      _buildSocialMediaLink(
                        context: context,
                        icon: Icons.music_note_outlined,
                        label: 'Spotify',
                        color: const Color(0xFF1DB954),
                        url: user.spotifyUrl!,
                      ),
                    if (user.tiktokUrl != null)
                      _buildSocialMediaLink(
                        context: context,
                        icon: Icons.video_library_outlined,
                        label: 'TikTok',
                        color: Colors.black,
                        url: user.tiktokUrl!,
                      ),
                    const SizedBox(height: 8),
                  ],
                ).animate().fadeIn(delay: 420.ms).slideX(begin: -0.2),

              const SizedBox(height: 8),

              // Stats Row
              Row(
                children: [
                  _buildCompactStat(
                    context,
                    '${user.followerIds.length}',
                    'Seguidores',
                  ),
                  const SizedBox(width: 24),
                  _buildCompactStat(
                    context,
                    '${user.followingIds.length}',
                    'Siguiendo',
                  ),
                ],
              ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.2),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Profile Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                if (user.bio != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Bio'),
                    subtitle: Text(user.bio!),
                  ),
                ],
                if (user.location != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Ubicación'),
                    subtitle: Text(user.location!),
                  ),
                ],
                if (user.website != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.link_outlined),
                    title: const Text('Sitio web'),
                    subtitle: Text(user.website!),
                  ),
                ],
                if (user.isArtist && user.artistBio != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.music_note_outlined),
                    title: const Text('Artist Bio'),
                    subtitle: Text(user.artistBio!),
                  ),
                ],
                if (user.isArtist && user.recordLabel != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.album_outlined),
                    title: const Text('Record Label'),
                    subtitle: Text(user.recordLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/profile/edit');
                },
              ),

              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('Estadísticas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/stats');
                },
              ),

              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('Historial de Compras'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/profile/purchase-history');
                },
              ),

              ListTile(
                leading: const Icon(Icons.people_outlined),
                title: const Text('Artistas Seguidos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/profile/followed-artists');
                },
              ),

              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Cambiar Contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/profile/change-password');
                },
              ),

              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configuración'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings - Coming soon'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Logout
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                  ),
                  child: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(BuildContext context, String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaLink({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
