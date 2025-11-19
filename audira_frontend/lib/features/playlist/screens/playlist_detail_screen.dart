// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/library_provider.dart';
import 'song_selector_screen.dart';

/// Pantalla de detalle de playlist con funcionalidad completa
/// GA01-114: Añadir / eliminar canciones
/// GA01-116: Ver todas mis listas
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

  /// Añadir canciones a la playlist
  Future<void> _addSongsToPlaylist() async {
    if (_playlist == null) return;

    final currentSongIds = _songs.map((s) => s.id).toList();

    final List<Song>? selectedSongs = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongSelectorScreen(
          currentSongIds: currentSongIds,
          playlistName: _playlist!.name,
        ),
      ),
    );

    if (selectedSongs != null && selectedSongs.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final libraryProvider = context.read<LibraryProvider>();
        for (final song in selectedSongs) {
          await libraryProvider.addSongToPlaylist(widget.playlistId, song.id);
        }
        // Recargar playlist
        await _loadPlaylist();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${selectedSongs.length} canción${selectedSongs.length == 1 ? "" : "es"} añadida${selectedSongs.length == 1 ? "" : "s"}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Eliminar canción de la playlist
  Future<void> _removeSongFromPlaylist(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: const Text('Eliminar canción'),
        content: Text('¿Eliminar "${song.name}" de esta playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _playlistService.removeSongFromPlaylist(
            widget.playlistId, song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canción eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPlaylist();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Eliminar playlist completa
  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Eliminar Playlist'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${_playlist!.name}"?\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final libraryProvider = context.read<LibraryProvider>();
        await libraryProvider.deletePlaylist(widget.playlistId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Mostrar opciones de la playlist
  void _showPlaylistOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlack,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppTheme.primaryBlue),
            title: const Text('Editar playlist'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                context,
                '/playlist/edit',
                arguments: widget.playlistId,
              );
              if (result == true) {
                _loadPlaylist();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.add, color: AppTheme.primaryBlue),
            title: const Text('Añadir canciones'),
            onTap: () {
              Navigator.pop(context);
              _addSongsToPlaylist();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: AppTheme.primaryBlue),
            title: const Text('Compartir'),
            onTap: () async {
              Navigator.pop(context);
              final shareText =
                  '🎵 Mira mi playlist "${_playlist!.name}" en Audira!\n\n'
                  '${_songs.length} canciones\n'
                  '${_playlist!.description ?? ""}\n\n'
                  '¡Escúchala ahora!';

              await Share.share(
                shareText,
                subject: 'Mira esta playlist en Audira',
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar playlist',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deletePlaylist();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    if (_isLoading && _playlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
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
              Text(_error ?? 'Playlist no encontrada'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
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
              icon: const Icon(Icons.more_vert),
              onPressed: _showPlaylistOptions,
              tooltip: 'Opciones',
            ),
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final shareText =
                    '🎵 Mira esta playlist "${_playlist!.name}" en Audira!\n\n'
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
      body: RefreshIndicator(
        onRefresh: _loadPlaylist,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Cover image
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.playlist_play,
                        size: 60, color: Colors.white),
                  ).animate().fadeIn().scale(),

                  const SizedBox(height: 16),

                  // Playlist name
                  Text(
                    _playlist!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 8),

                  // Description
                  if (_playlist!.description != null &&
                      _playlist!.description!.isNotEmpty)
                    Text(
                      _playlist!.description!,
                      style: const TextStyle(color: AppTheme.textGrey),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 8),

                  // Info chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _playlist!.isPublic ? Icons.public : Icons.lock,
                        size: 16,
                        color: AppTheme.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _playlist!.isPublic ? 'Pública' : 'Privada',
                        style: const TextStyle(color: AppTheme.textGrey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.music_note,
                          size: 16, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        '${_songs.length} ${_songs.length == 1 ? "canción" : "canciones"}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_songs.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            audioProvider.playQueue(_songs);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reproduciendo playlist...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Reproducir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                        ).animate().fadeIn(delay: 300.ms).scale(),
                      if (isOwner && _songs.isNotEmpty)
                        const SizedBox(width: 12),
                      if (isOwner)
                        OutlinedButton.icon(
                          onPressed: _addSongsToPlaylist,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ).animate().fadeIn(delay: 320.ms).scale(),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Songs list
            Expanded(
              child: _songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.music_note,
                              size: 64,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay canciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isOwner
                                ? 'Toca "Añadir" para agregar canciones'
                                : 'Esta playlist está vacía',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          color: AppTheme.surfaceBlack,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: song.coverImageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: song.coverImageUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              color: AppTheme.primaryBlue
                                                  .withValues(alpha: 0.2),
                                              child: const Icon(
                                                  Icons.music_note),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              color: AppTheme.primaryBlue
                                                  .withValues(alpha: 0.2),
                                              child: const Icon(
                                                  Icons.music_note),
                                            ),
                                          )
                                        : Container(
                                            color: AppTheme.primaryBlue
                                                .withValues(alpha: 0.2),
                                            child:
                                                const Icon(Icons.music_note),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundBlack,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(song.name),
                            subtitle: Text(
                              '${song.artistName} • ${song.durationFormatted}',
                              style: const TextStyle(color: AppTheme.textGrey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.play_circle_outline),
                                  onPressed: () {
                                    audioProvider.playSong(
                                      song,
                                      isUserAuthenticated:
                                          authProvider.isAuthenticated,
                                    );
                                  },
                                  tooltip: 'Reproducir',
                                ),
                                if (isOwner)
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor:
                                            AppTheme.surfaceBlack,
                                        builder: (context) => Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.info_outline),
                                              title: const Text(
                                                  'Ver detalles'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.pushNamed(
                                                  context,
                                                  '/song',
                                                  arguments: song.id,
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.red),
                                              title: const Text(
                                                'Eliminar de playlist',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _removeSongFromPlaylist(
                                                    song);
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            onTap: () {
                              audioProvider.playSong(
                                song,
                                isUserAuthenticated:
                                    authProvider.isAuthenticated,
                              );
                            },
                          ),
                        ).animate(delay: (index * 50).ms).fadeIn();
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: isOwner && _songs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addSongsToPlaylist,
              backgroundColor: AppTheme.primaryBlue,
              icon: const Icon(Icons.add),
              label: const Text('Añadir canciones'),
            ).animate().fadeIn(delay: 500.ms).scale()
          : null,
    );
  }
}
