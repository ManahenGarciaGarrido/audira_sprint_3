// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:audira_frontend/core/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/models/user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;
  String _selectedRoleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _authService.getAllUsers();
      if (response.success && response.data != null) {
        setState(() {
          _users = response.data!;
          _applyFilters();
        });
      } else {
        setState(() => _error = response.error ?? 'Failed to load users');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = _users;

    // Apply role filter
    if (_selectedRoleFilter != 'ALL') {
      filtered =
          filtered.where((user) => user.role == _selectedRoleFilter).toList();
    }

    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((user) =>
              user.username.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.fullName.toLowerCase().contains(query))
          .toList();
    }

    setState(() => _filteredUsers = filtered);
  }

  Future<void> _changeUserRole(User user) async {
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['USER', 'ARTIST', 'ADMIN'].map((role) {
            return RadioListTile<String>(
              title: Text(role),
              value: role,
              groupValue: user.role,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedRole != null && selectedRole != user.role) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role changed to $selectedRole')),
      );
      _loadUsers();
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    final action = user.isActive ? 'deactivate' : 'activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} User'),
        content: Text('Are you sure you want to $action this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${action}d successfully')),
      );
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedRoleFilter = value);
              _applyFilters();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('All Roles')),
              const PopupMenuItem(value: 'USER', child: Text('Users')),
              const PopupMenuItem(value: 'ARTIST', child: Text('Artists')),
              const PopupMenuItem(value: 'ADMIN', child: Text('Admins')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffix: Text(
                    _selectedRoleFilter != 'ALL' ? _selectedRoleFilter : ''),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user.role == 'ADMIN'
                                        ? Colors.red
                                        : user.role == 'ARTIST'
                                            ? AppTheme.primaryBlue
                                            : Colors.grey,
                                    child: Text(
                                      user.username[0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user.fullName),
                                  subtitle:
                                      Text('${user.email}\n@${user.username}'),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(user.role),
                                        backgroundColor: AppTheme.primaryBlue,
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      PopupMenuButton(
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'role',
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons.admin_panel_settings),
                                                SizedBox(width: 8),
                                                Text('Change Role'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'status',
                                            child: Row(
                                              children: [
                                                Icon(user.isActive
                                                    ? Icons.block
                                                    : Icons.check_circle),
                                                const SizedBox(width: 8),
                                                Text(user.isActive
                                                    ? 'Deactivate'
                                                    : 'Activate'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'role') {
                                            _changeUserRole(user);
                                          } else if (value == 'status') {
                                            _toggleUserStatus(user);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: (index * 50).ms);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
