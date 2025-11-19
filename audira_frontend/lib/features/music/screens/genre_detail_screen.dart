import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/genre.dart';
import 'package:audira_frontend/core/models/song.dart';
import 'package:audira_frontend/features/common/widgets/album_list_item.dart';
import 'package:audira_frontend/features/common/widgets/song_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GenreDetailScreen extends StatefulWidget {
  final int genreId;

  const GenreDetailScreen({super.key, required this.genreId});

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();

  Genre? _genre;
  List<Song> _songs = [];
  List<Album> _albums = [];

  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGenreDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGenreDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load genre
      final genreResponse = await _musicService.getGenreById(widget.genreId);
      if (genreResponse.success && genreResponse.data != null) {
        _genre = genreResponse.data;

        // Load songs in this genre
        final songsResponse =
            await _musicService.getSongsByGenre(widget.genreId);
        if (songsResponse.success && songsResponse.data != null) {
          _songs = songsResponse.data!;
        }

        // Load albums in this genre
        final albumsResponse =
            await _musicService.getAlbumsByGenre(widget.genreId);
        if (albumsResponse.success && albumsResponse.data != null) {
          _albums = albumsResponse.data!;
        }
      } else {
        _error = genreResponse.error ?? 'Failed to load genre';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _genre == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Genre not found'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_genre!.name),
      ),
      body: Column(
        children: [
          _buildGenreHeader(),
          _buildTabs(),
        ],
      ),
    );
  }

  Widget _buildGenreHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Genre icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _genre!.color != null
                  ? Color(int.parse(_genre!.color!.replaceFirst('#', '0xff')))
                  : AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _genre!.icon != null
                  ? Text(
                      _genre!.icon!,
                      style: const TextStyle(fontSize: 32),
                    )
                  : const Icon(Icons.music_note, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _genre!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_genre!.description != null &&
                    _genre!.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _genre!.description!,
                    style: TextStyle(color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_songs.length} songs',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_albums.length} albums',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTabs() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(text: 'Songs (${_songs.length})'),
              Tab(text: 'Albums (${_albums.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(),
                _buildAlbumsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return const Center(child: Text('No songs in this genre'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return SongListItem(
          song: song,
          onTap: () {
            Navigator.pushNamed(context, '/song', arguments: song.id);
          },
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) {
      return const Center(child: Text('No albums in this genre'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return AlbumListItem(
          album: album,
          onTap: () {
            Navigator.pushNamed(context, '/album', arguments: album.id);
          },
        );
      },
    );
  }
}
