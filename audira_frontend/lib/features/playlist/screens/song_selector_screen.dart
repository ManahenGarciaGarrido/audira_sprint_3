import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/auth_provider.dart';

/// Pantalla para seleccionar canciones para añadir a una playlist
/// GA01-114: Añadir canciones a playlist
class SongSelectorScreen extends StatefulWidget {
  final List<int> currentSongIds; // Canciones ya en la playlist
  final String playlistName;

  const SongSelectorScreen({
    super.key,
    this.currentSongIds = const [],
    required this.playlistName,
  });

  @override
  State<SongSelectorScreen> createState() => _SongSelectorScreenState();
}

class _SongSelectorScreenState extends State<SongSelectorScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();

  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  final Set<int> _selectedSongIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllSongs();
      if (response.success && response.data != null) {
        // Filtrar canciones que NO están en la playlist
        _allSongs = response.data!
            .where((song) => !widget.currentSongIds.contains(song.id))
            .toList();
        _filteredSongs = _allSongs;
      } else {
        _error = response.error ?? 'Failed to load songs';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _allSongs;
      } else {
        _filteredSongs = _allSongs.where((song) {
          return song.name.toLowerCase().contains(query.toLowerCase()) ||
              song.artistName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleSongSelection(int songId) {
    setState(() {
      if (_selectedSongIds.contains(songId)) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });
  }

  void _confirmSelection() {
    // Obtener las canciones seleccionadas
    final selectedSongs = _filteredSongs
        .where((song) => _selectedSongIds.contains(song.id))
        .toList();
    Navigator.pop(context, selectedSongs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Añadir canciones'),
            Text(
              'a "${widget.playlistName}"',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          ],
        ),
        actions: [
          if (_selectedSongIds.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Añadir (${_selectedSongIds.length})',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSongs,
              decoration: InputDecoration(
                hintText: 'Buscar canciones...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSongs('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Selected count chip
          if (_selectedSongIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedSongIds.length} canción${_selectedSongIds.length == 1 ? "" : "es"} seleccionada${_selectedSongIds.length == 1 ? "" : "s"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedSongIds.clear());
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.5, end: 0),

          // Songs list
          Expanded(
            child: _buildSongsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllSongs,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.music_note
                  : Icons.search_off,
              size: 64,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay canciones disponibles'
                  : 'No se encontraron canciones',
              style: const TextStyle(fontSize: 18, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        final isSelected = _selectedSongIds.contains(song.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : null,
          child: ListTile(
            leading: Stack(
              alignment: Alignment.center,
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
                                const Icon(Icons.music_note),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.music_note),
                          )
                        : Container(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            child: const Icon(Icons.music_note),
                          ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            title: Text(
              song.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryBlue : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.artistName),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      song.durationFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    Text(
                      song.price.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () {
                    final audioProvider = context.read<AudioProvider>();
                    final authProvider = context.read<AuthProvider>();
                    audioProvider.playSong(
                      song,
                      isUserAuthenticated: authProvider.isAuthenticated,
                    );
                  },
                  tooltip: 'Vista previa',
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSongSelection(song.id),
                  activeColor: AppTheme.primaryBlue,
                ),
              ],
            ),
            onTap: () => _toggleSongSelection(song.id),
          ),
        ).animate(delay: (index * 30).ms).fadeIn().slideX(begin: -0.1);
      },
    );
  }
}
