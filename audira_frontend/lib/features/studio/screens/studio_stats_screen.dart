import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/metrics_service.dart';

class StudioStatsScreen extends StatefulWidget {
  const StudioStatsScreen({super.key});

  @override
  State<StudioStatsScreen> createState() => _StudioStatsScreenState();
}

class _StudioStatsScreenState extends State<StudioStatsScreen> {
  final MetricsService _metricsService = MetricsService();
  Map<String, dynamic>? _artistMetrics;
  List<dynamic>? _topSongs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      final metricsResponse =
          await _metricsService.getArtistMetrics(authProvider.currentUser!.id);
      final topSongsResponse = await _metricsService.getArtistTopSongs(
        authProvider.currentUser!.id,
        limit: 5,
      );

      if (metricsResponse.success) {
        _artistMetrics = metricsResponse.data;
      }
      if (topSongsResponse.success) {
        _topSongs = topSongsResponse.data;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artist: ${user?.fullName}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // Overview Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                          'Total Plays',
                          _formatNumber(_artistMetrics?['totalPlays'] ?? 0),
                          Icons.play_circle,
                          AppTheme.primaryBlue),
                      _buildStatCard(
                          'Total Revenue',
                          '\$${(_artistMetrics?['totalRevenue'] ?? 0).toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green),
                      _buildStatCard(
                          'Total Songs',
                          '${_artistMetrics?['totalSongs'] ?? 0}',
                          Icons.music_note,
                          Colors.purple),
                      _buildStatCard(
                          'Total Albums',
                          '${_artistMetrics?['totalAlbums'] ?? 0}',
                          Icons.album,
                          Colors.orange),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 24),

                  const Text('Monthly Performance',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatRow(
                              'This Month Plays',
                              _formatNumber(
                                  _artistMetrics?['playsThisMonth'] ?? 0),
                              AppTheme.primaryBlue),
                          const Divider(),
                          _buildStatRow(
                              'This Month Revenue',
                              '\$${(_artistMetrics?['revenueThisMonth'] ?? 0).toStringAsFixed(2)}',
                              Colors.green),
                          const Divider(),
                          _buildStatRow(
                              'New Followers',
                              '+${_artistMetrics?['newFollowers'] ?? 0}',
                              Colors.purple),
                          const Divider(),
                          _buildStatRow(
                              'Downloads',
                              '${_artistMetrics?['downloads'] ?? 0}',
                              Colors.orange),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),

                  if (_topSongs != null && _topSongs!.isNotEmpty) ...[
                    const Text('Top Performing Songs',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...List.generate(
                      _topSongs!.length,
                      (index) {
                        final song = _topSongs![index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryBlue,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(song['songName'] ?? 'Unknown Song'),
                            subtitle: Text('${song['plays'] ?? 0} plays'),
                            trailing: Text(
                                '\$${(song['revenue'] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            onTap: () {
                              if (song['songId'] != null) {
                                Navigator.pushNamed(context, '/song',
                                    arguments: song['songId']);
                              }
                            },
                          ),
                        ).animate().fadeIn(delay: ((index + 1) * 50).ms);
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
