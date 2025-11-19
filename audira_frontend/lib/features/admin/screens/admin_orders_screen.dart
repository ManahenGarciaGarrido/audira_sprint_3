import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 1001,
      'userId': 123,
      'userName': 'John Doe',
      'items': ['Song: Midnight Dreams', 'Album: Summer Vibes'],
      'total': 25.98,
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
    },
    {
      'id': 1002,
      'userId': 456,
      'userName': 'Jane Smith',
      'items': ['Song: Electric Love'],
      'total': 9.99,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'pending',
    },
    {
      'id': 1003,
      'userId': 789,
      'userName': 'Bob Johnson',
      'items': ['Album: Jazz Collection', 'Song: Blue Notes'],
      'total': 34.97,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'completed',
    },
  ];

  String _selectedFilter = 'ALL';

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'ALL') return _orders;
    return _orders
        .where((o) => o['status'] == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('All Orders')),
              const PopupMenuItem(value: 'PENDING', child: Text('Pending')),
              const PopupMenuItem(value: 'COMPLETED', child: Text('Completed')),
              const PopupMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Orders',
                    _orders.length.toString(),
                    Icons.shopping_cart,
                    AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Revenue',
                    '\$${_orders.fold<double>(0, (sum, order) => sum + order['total']).toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredOrders.isEmpty
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(order['status']),
                            child: Text('#${order['id']}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white)),
                          ),
                          title: Text(
                            order['userName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '\$${order['total'].toStringAsFixed(2)} • ${_formatDate(order['date'])}\nStatus: ${order['status'].toUpperCase()}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...order['items']
                                      .map<Widget>((item) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check_circle,
                                                    size: 16,
                                                    color: Colors.green),
                                                const SizedBox(width: 8),
                                                Text(item),
                                              ],
                                            ),
                                          )),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: \$${order['total'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (order['status'] == 'pending')
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              order['status'] = 'completed';
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Order marked as completed'),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.check),
                                          label: const Text('Complete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
