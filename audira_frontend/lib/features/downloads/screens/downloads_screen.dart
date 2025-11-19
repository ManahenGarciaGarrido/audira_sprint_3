// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/models/downloaded_song.dart';
import '../../../core/models/song.dart';
import '../../../config/theme.dart';

/// Pantalla de descargas
/// GA01-137: Registro de descargas
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _clearAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas las descargas'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las descargas? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final downloadProvider = context.read<DownloadProvider>();
      final success = await downloadProvider.clearAllDownloads();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Todas las descargas eliminadas'
                  : 'Error al eliminar descargas',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showDownloadStats() {
    final downloadProvider = context.read<DownloadProvider>();
    final stats = downloadProvider.getDownloadStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Descargas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total de descargas:', '${stats['totalDownloads']}'),
            _buildStatRow('Espacio utilizado:', '${stats['totalSizeMB']} MB'),
            const SizedBox(height: 16),
            if (stats['formats'] != null && (stats['formats'] as Map).isNotEmpty)
              ...[
                const Text(
                  'Formatos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((stats['formats'] as Map<String, int>).entries.map(
                  (e) => _buildStatRow('  ${e.key.toUpperCase()}:', '${e.value}'),
                )),
              ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();

    final downloadedSongs = _searchQuery.isEmpty
        ? downloadProvider.getDownloadedSongsSorted()
        : downloadProvider.searchDownloadedSongs(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar descargas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Descargas'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          if (downloadedSongs.isNotEmpty && !_isSearching)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'stats') {
                  _showDownloadStats();
                } else if (value == 'clear') {
                  _clearAllDownloads();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart),
                      SizedBox(width: 12),
                      Text('Estadísticas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Eliminar todo', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: downloadedSongs.isEmpty
          ? _buildEmptyState()
          : _buildDownloadsList(downloadedSongs),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty
                ? Icons.download_outlined
                : Icons.search_off,
            size: 80,
            color: Colors.grey,
          ).animate().scale(duration: 300.ms),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No tienes descargas'
                : 'No se encontraron descargas',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Las canciones que descargues aparecerán aquí'
                : 'Intenta con otra búsqueda',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsList(List<DownloadedSong> songs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final downloadedSong = songs[index];
        return _buildDownloadedSongCard(downloadedSong);
      },
    );
  }

  Widget _buildDownloadedSongCard(DownloadedSong downloadedSong) {
    final audioProvider = context.watch<AudioProvider>();
    final isPlaying = audioProvider.currentSong?.id == downloadedSong.songId &&
        audioProvider.isPlaying;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _playSong(downloadedSong),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: downloadedSong.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: downloadedSong.coverImageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
              ),
              const SizedBox(width: 12),
              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      downloadedSong.songName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      downloadedSong.artistName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.storage_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          downloadedSong.fileSizeFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.music_note,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          downloadedSong.format.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            timeago.format(
                              downloadedSong.downloadedAt,
                              locale: 'es',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play button
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: AppTheme.primaryBlue,
                  size: 32,
                ),
                onPressed: () => _playSong(downloadedSong),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteDownload(downloadedSong),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  Future<void> _playSong(DownloadedSong downloadedSong) async {
    // Convertir DownloadedSong a Song para reproducir
    final song = Song(
      id: downloadedSong.songId,
      artistId: 0, // No disponible en DownloadedSong
      artistName: downloadedSong.artistName,
      name: downloadedSong.songName,
      duration: downloadedSong.duration,
      price: 0,
      coverImageUrl: downloadedSong.coverImageUrl,
      audioUrl: downloadedSong.localFilePath, // Usar archivo local
    );

    final audioProvider = context.read<AudioProvider>();
    await audioProvider.playSong(song);
  }

  Future<void> _deleteDownload(DownloadedSong downloadedSong) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar descarga'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la descarga de "${downloadedSong.songName}"?',
        ),
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
      final downloadProvider = context.read<DownloadProvider>();
      final success = await downloadProvider.deleteDownload(downloadedSong.songId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Descarga eliminada'
                  : 'Error al eliminar la descarga',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
