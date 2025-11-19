// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/audio_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();

  Playlist? _playlist;
  List<Song> _songs = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _playlistService.getPlaylistWithSongs(widget.playlistId);
      if (response.success && response.data != null) {
        setState(() {
          _playlist = response.data?['playlist'];
          _songs = response.data?['songs'] ?? [];
        });
      } else {
        setState(() => _error = response.error ?? 'Failed to load playlist');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: Text('Remove "${song.name}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _playlistService.removeSongFromPlaylist(
            widget.playlistId, song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song removed from playlist')),
        );
        _loadPlaylist();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _playlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Playlist not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isOwner = authProvider.currentUser?.id == _playlist!.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist!.name),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(context, '/playlist/edit/${_playlist!.id}');
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final shareText = '🎵 Mira mi playlist "${_playlist!.name}" en Audira!\n\n'
                  '${_songs.length} canciones\n'
                  '${_playlist!.description ?? ""}\n\n'
                  '¡Escúchala ahora!';

              await Share.share(
                shareText,
                subject: 'Mira esta playlist en Audira',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.playlist_play,
                      size: 60, color: Colors.white),
                ).animate().fadeIn().scale(),
                const SizedBox(height: 16),
                Text(
                  _playlist!.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                if (_playlist!.description != null &&
                    _playlist!.description!.isNotEmpty)
                  Text(
                    _playlist!.description!,
                    style: const TextStyle(color: AppTheme.textGrey),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  '${_songs.length} songs',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 16),
                if (_songs.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      audioProvider.playQueue(_songs);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Playing playlist...')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                  ).animate().fadeIn(delay: 300.ms).scale(),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _songs.isEmpty
                ? const Center(child: Text('No songs in this playlist'))
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(song.name),
                          subtitle: Text(song.durationFormatted),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_circle_outline),
                                onPressed: () {
                                  audioProvider.playSong(song);
                                },
                              ),
                              if (isOwner)
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _removeSongFromPlaylist(song),
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
