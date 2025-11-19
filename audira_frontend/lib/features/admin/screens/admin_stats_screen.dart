import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics refreshed')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Stats
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                    'Total Users', '1,234', Icons.people, AppTheme.primaryBlue),
                _buildStatCard(
                    'Total Songs', '5,678', Icons.music_note, Colors.purple),
                _buildStatCard(
                    'Total Albums', '432', Icons.album, Colors.orange),
                _buildStatCard('Total Revenue', '\$12,345', Icons.attach_money,
                    Colors.green),
              ],
            ).animate().fadeIn(),
            const SizedBox(height: 24),

            // User Statistics
            const Text(
              'User Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Active Users', '987', Colors.green),
                    const Divider(),
                    _buildStatRow(
                        'New Users (This Month)', '123', AppTheme.primaryBlue),
                    const Divider(),
                    _buildStatRow('Artists', '45', Colors.purple),
                    const Divider(),
                    _buildStatRow('Admins', '5', Colors.red),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),

            // Content Statistics
            const Text(
              'Content Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                        'Total Plays', '45,678', AppTheme.primaryBlue),
                    const Divider(),
                    _buildStatRow('Total Downloads', '12,345', Colors.green),
                    const Divider(),
                    _buildStatRow('Playlists Created', '890', Colors.orange),
                    const Divider(),
                    _buildStatRow('Comments', '3,456', Colors.purple),
                    const Divider(),
                    _buildStatRow('Ratings', '5,678', Colors.amber),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),

            // Revenue Statistics
            const Text(
              'Revenue Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Total Sales', '\$12,345', Colors.green),
                    const Divider(),
                    _buildStatRow(
                        'This Month', '\$2,345', AppTheme.primaryBlue),
                    const Divider(),
                    _buildStatRow('Last Month', '\$2,100', AppTheme.textGrey),
                    const Divider(),
                    _buildStatRow('Average Order', '\$15.67', Colors.orange),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),

            // Top Content
            const Text(
              'Top Performing Content',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildTopItem(
                      '1', 'Midnight Dreams', '1,234 plays', Icons.music_note),
                  const Divider(height: 1),
                  _buildTopItem(
                      '2', 'Electric Love', '1,123 plays', Icons.music_note),
                  const Divider(height: 1),
                  _buildTopItem('3', 'Summer Vibes', '987 plays', Icons.album),
                  const Divider(height: 1),
                  _buildTopItem(
                      '4', 'Jazz Collection', '876 plays', Icons.album),
                  const Divider(height: 1),
                  _buildTopItem(
                      '5', 'Blue Notes', '765 plays', Icons.music_note),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
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
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItem(
      String rank, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue,
        child: Text(rank, style: const TextStyle(color: Colors.white)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(icon, color: AppTheme.textGrey),
    );
  }
}
