import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/metrics_service.dart';

class UserStatsScreen extends StatefulWidget {
  const UserStatsScreen({super.key});

  @override
  State<UserStatsScreen> createState() => _UserStatsScreenState();
}

class _UserStatsScreenState extends State<UserStatsScreen> {
  final MetricsService _metricsService = MetricsService();
  Map<String, dynamic>? _userMetrics;
  List<dynamic>? _listeningHistory;
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
          await _metricsService.getUserMetrics(authProvider.currentUser!.id);
      final historyResponse = await _metricsService.getUserListeningHistory(
        authProvider.currentUser!.id,
        limit: 5,
      );

      if (metricsResponse.success) {
        _userMetrics = metricsResponse.data;
      }
      if (historyResponse.success) {
        _listeningHistory = historyResponse.data;
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
        title: const Text('My Statistics'),
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
                  Text('${user?.fullName}',
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
                          '${_userMetrics?['totalPlays'] ?? 0}',
                          Icons.play_circle,
                          AppTheme.primaryBlue),
                      _buildStatCard(
                          'Purchased Songs',
                          '${_userMetrics?['purchasedSongs'] ?? 0}',
                          Icons.music_note,
                          Colors.purple),
                      _buildStatCard(
                          'Purchased Albums',
                          '${_userMetrics?['purchasedAlbums'] ?? 0}',
                          Icons.album,
                          Colors.orange),
                      _buildStatCard(
                          'Total Spent',
                          '\$${(_userMetrics?['totalSpent'] ?? 0).toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 24),

                  const Text('Listening Activity',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatRow(
                              'This Week',
                              '${_userMetrics?['playsThisWeek'] ?? 0} plays',
                              AppTheme.primaryBlue),
                          const Divider(),
                          _buildStatRow(
                              'This Month',
                              '${_userMetrics?['playsThisMonth'] ?? 0} plays',
                              AppTheme.primaryBlue),
                          const Divider(),
                          _buildStatRow(
                              'Total Listening Time',
                              _formatMinutes(
                                  _userMetrics?['totalListeningTime'] ?? 0),
                              Colors.purple),
                          const Divider(),
                          _buildStatRow(
                              'Avg. Daily Listening',
                              _formatMinutes(
                                  _userMetrics?['avgDailyListening'] ?? 0),
                              Colors.orange),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),

                  if (_userMetrics?['topGenres'] != null &&
                      (_userMetrics!['topGenres'] as List).isNotEmpty) ...[
                    const Text('Top Genres',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: _buildGenresList(_userMetrics!['topGenres']),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 24),

                  if (_listeningHistory != null &&
                      _listeningHistory!.isNotEmpty) ...[
                    const Text('Recently Played',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...List.generate(
                      _listeningHistory!.length,
                      (index) {
                        final item = _listeningHistory![index];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.primaryBlue,
                              child:
                                  Icon(Icons.music_note, color: Colors.white),
                            ),
                            title: Text(item['songName'] ?? 'Unknown Song'),
                            subtitle: Text(
                                '${item['artistName'] ?? 'Unknown Artist'} • ${item['playCount'] ?? 0} plays'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (item['songId'] != null) {
                                Navigator.pushNamed(context, '/song',
                                    arguments: item['songId']);
                              }
                            },
                          ),
                        ).animate().fadeIn(delay: ((index + 1) * 50).ms);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_userMetrics?['topArtists'] != null &&
                      (_userMetrics!['topArtists'] as List).isNotEmpty) ...[
                    const Text('Favorite Artists',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (_userMetrics!['topArtists'] as List).length,
                        itemBuilder: (context, index) {
                          final artist = _userMetrics!['topArtists'][index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () {
                                if (artist['artistId'] != null) {
                                  Navigator.pushNamed(context, '/artist',
                                      arguments: artist['artistId']);
                                }
                              },
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppTheme.primaryBlue,
                                    child: Text(
                                        (artist['artistName'] ?? 'A')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 20, color: Colors.white)),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      artist['artistName'] ?? 'Unknown',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 350.ms),
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

  List<Widget> _buildGenresList(List<dynamic> genres) {
    final colors = [
      Colors.pink,
      Colors.red,
      Colors.blue,
      Colors.purple,
      Colors.orange
    ];
    List<Widget> widgets = [];

    for (int i = 0; i < genres.length; i++) {
      final genre = genres[i];
      final color = colors[i % colors.length];

      if (i > 0) {
        widgets.add(const Divider(height: 1));
      }

      widgets.add(_buildGenreItem(
        genre['genreName'] ?? 'Unknown',
        (genre['percentage'] ?? 0).toInt(),
        color,
      ));
    }

    return widgets;
  }

  Widget _buildGenreItem(String genre, int percentage, Color color) {
    return ListTile(
      title: Text(genre),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[800],
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text('$percentage%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
