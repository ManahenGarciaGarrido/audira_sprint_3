import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminContactsScreen extends StatefulWidget {
  const AdminContactsScreen({super.key});

  @override
  State<AdminContactsScreen> createState() => _AdminContactsScreenState();
}

class _AdminContactsScreenState extends State<AdminContactsScreen> {
  final List<Map<String, dynamic>> _contacts = [
    {
      'id': 1,
      'name': 'John Doe',
      'email': 'john@example.com',
      'subject': 'Payment Issue',
      'message': 'I have a problem with my recent payment...',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'pending',
    },
    {
      'id': 2,
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'subject': 'Feature Request',
      'message': 'Would love to see a dark mode option...',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'resolved',
    },
  ];

  String _selectedFilter = 'ALL';

  List<Map<String, dynamic>> get _filteredContacts {
    if (_selectedFilter == 'ALL') return _contacts;
    return _contacts
        .where((c) => c['status'] == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Messages'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('All Messages')),
              const PopupMenuItem(value: 'PENDING', child: Text('Pending')),
              const PopupMenuItem(value: 'RESOLVED', child: Text('Resolved')),
            ],
          ),
        ],
      ),
      body: _filteredContacts.isEmpty
          ? const Center(child: Text('No contact messages'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: contact['status'] == 'pending'
                          ? Colors.orange
                          : Colors.green,
                      child: Icon(
                        contact['status'] == 'pending'
                            ? Icons.pending
                            : Icons.check_circle,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      contact['subject'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${contact['name']} • ${contact['email']}\n${_formatDate(contact['date'])}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(contact['message']),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (contact['status'] == 'pending')
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        contact['status'] = 'resolved';
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Message marked as resolved'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text('Mark as Resolved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // Reply functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reply - Coming soon'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.reply),
                                  label: const Text('Reply'),
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
