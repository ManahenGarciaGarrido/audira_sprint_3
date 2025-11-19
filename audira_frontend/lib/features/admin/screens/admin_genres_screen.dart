// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/models/genre.dart';
import '../../../core/api/services/music_service.dart';

class AdminGenresScreen extends StatefulWidget {
  const AdminGenresScreen({super.key});

  @override
  State<AdminGenresScreen> createState() => _AdminGenresScreenState();
}

class _AdminGenresScreenState extends State<AdminGenresScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();

  List<Genre> _genres = [];
  List<Genre> _filteredGenres = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllGenres();
      if (response.success && response.data != null) {
        setState(() {
          _genres = response.data!;
          _filteredGenres = _genres;
        });
      } else {
        setState(() => _error = response.error ?? 'Failed to load genres');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterGenres(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGenres = _genres;
      } else {
        _filteredGenres = _genres
            .where((genre) =>
                genre.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _deleteGenre(int genreId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Genre'),
        content: const Text('Are you sure you want to delete this genre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _musicService.deleteGenre(genreId);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Genre deleted successfully')),
          );
          _loadGenres();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to delete genre'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Genres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showGenreForm(null),
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
                hintText: 'Search genres...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterGenres,
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
                              onPressed: _loadGenres,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredGenres.isEmpty
                        ? const Center(child: Text('No genres found'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: _filteredGenres.length,
                            itemBuilder: (context, index) {
                              final genre = _filteredGenres[index];
                              return Card(
                                child: InkWell(
                                  onTap: () => _showGenreForm(genre),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.music_note,
                                                size: 40,
                                                color: AppTheme.primaryBlue),
                                            const SizedBox(height: 8),
                                            Text(
                                              genre.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          onPressed: () =>
                                              _deleteGenre(genre.id),
                                        ),
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

  void _showGenreForm(Genre? genre) {
    final isEditing = genre != null;
    final nameController = TextEditingController(text: genre?.name ?? '');
    final descriptionController =
        TextEditingController(text: genre?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Genre' : 'Add New Genre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Genre Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Genre name is required')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing
                      ? 'Genre updated successfully'
                      : 'Genre created successfully'),
                ),
              );
              _loadGenres();
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
