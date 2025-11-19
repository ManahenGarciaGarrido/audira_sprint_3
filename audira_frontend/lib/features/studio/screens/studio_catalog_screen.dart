// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';

class StudioCatalogScreen extends StatefulWidget {
  const StudioCatalogScreen({super.key});

  @override
  State<StudioCatalogScreen> createState() => _StudioCatalogScreenState();
}

class _StudioCatalogScreenState extends State<StudioCatalogScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  late TabController _tabController;

  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistId = authProvider.currentUser!.id;

      final songsResponse = await _musicService.getSongsByArtist(artistId);
      if (songsResponse.success && songsResponse.data != null) {
        _songs = songsResponse.data!;
      }

      final albumsResponse = await _musicService.getAlbumsByArtist(artistId);
      if (albumsResponse.success && albumsResponse.data != null) {
        _albums = albumsResponse.data!;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSong(int songId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: const Text('Are you sure? This action cannot be undone.'),
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
        final response = await _musicService.deleteSong(songId);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song deleted successfully')),
          );
          _loadCatalog();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAlbum(int albumId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: const Text(
            'Are you sure? This will also remove all songs in the album.'),
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
        final response = await _musicService.deleteAlbum(albumId);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Album deleted successfully')),
          );
          _loadCatalog();
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
        title: const Text('My Catalog'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Songs', icon: Icon(Icons.music_note)),
            Tab(text: 'Albums', icon: Icon(Icons.album)),
          ],
        ),
      ),
      body: _isLoading
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
                        onPressed: _loadCatalog,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSongsList(),
                    _buildAlbumsList(),
                  ],
                ),
    );
  }

  Widget _buildSongsList() {
    if (_songs.isEmpty) {
      return const Center(child: Text('No songs yet. Upload your first song!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.music_note, color: Colors.white),
            ),
            title: Text(song.name),
            subtitle: Text(
                '\$${song.price.toStringAsFixed(2)} • ${song.durationFormatted}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit - Coming soon')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSong(song.id),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildAlbumsList() {
    if (_albums.isEmpty) {
      return const Center(
          child: Text('No albums yet. Create your first album!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.album, color: Colors.white),
            ),
            title: Text(album.name),
            subtitle: Text('\$${album.price.toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit - Coming soon')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAlbum(album.id),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }
}
