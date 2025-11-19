import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(10),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _buildAdminCard(
            context,
            icon: Icons.music_note,
            title: 'Manage Songs',
            subtitle: 'Add, edit, delete songs',
            color: Colors.purple,
            route: '/admin/songs',
          ).animate(delay: 0.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.album,
            title: 'Manage Albums',
            subtitle: 'Add, edit, delete albums',
            color: Colors.blue,
            route: '/admin/albums',
          )
              .animate(delay: 100.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.category,
            title: 'Manage Genres',
            subtitle: 'Add, edit, delete genres',
            color: Colors.green,
            route: '/admin/genres',
          )
              .animate(delay: 200.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.people,
            title: 'Manage Users',
            subtitle: 'View and manage users',
            color: Colors.orange,
            route: '/admin/users',
          )
              .animate(delay: 300.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.help,
            title: 'Manage FAQs',
            subtitle: 'Add, edit, delete FAQs',
            color: Colors.teal,
            route: '/admin/faqs',
          )
              .animate(delay: 400.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.email,
            title: 'View Contacts',
            subtitle: 'See contact messages',
            color: Colors.pink,
            route: '/admin/contacts',
          )
              .animate(delay: 500.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.shopping_bag,
            title: 'Manage Orders',
            subtitle: 'View and manage orders',
            color: Colors.amber,
            route: '/admin/orders',
          )
              .animate(delay: 600.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.bar_chart,
            title: 'Statistics',
            subtitle: 'View global statistics',
            color: Colors.red,
            route: '/admin/stats',
          )
              .animate(delay: 700.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.7),
                color.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
