import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/discovery_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/genre.dart';
import '../../common/widgets/song_card.dart';
import '../../common/widgets/album_card.dart';
import '../../common/widgets/genre_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  final DiscoveryService _discoveryService = DiscoveryService();

  List<Song> _featuredSongs = [];
  List<Album> _featuredAlbums = [];
  List<Genre> _genres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Solo mostrar contenido publicado en la pantalla de inicio
    final songsResponse = await _musicService.getTopPublishedSongs();
    final albumsResponse = await _musicService.getRecentPublishedAlbums();
    final genresResponse = await _musicService.getAllGenres();

    if (songsResponse.success && songsResponse.data != null) {
      _featuredSongs = songsResponse.data!.take(10).toList();
    }

    if (albumsResponse.success && albumsResponse.data != null) {
      _featuredAlbums = albumsResponse.data!.take(10).toList();
    }

    if (genresResponse.success && genresResponse.data != null) {
      _genres = genresResponse.data!;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Section
          Text(
            'Descubre nueva música',
            style: Theme.of(context).textTheme.displaySmall,
          ).animate().fadeIn().slideY(),

          const SizedBox(height: 8),

          Text(
            'Explora canciones y álbumes destacados',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGrey,
                ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // Genres
          if (_genres.isNotEmpty) ...[
            Text(
              'Géneros',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GenreChip(genre: _genres[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Featured Songs
          if (_featuredSongs.isNotEmpty) ...[
            Text(
              'Canciones destacadas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredSongs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SongCard(song: _featuredSongs[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Featured Albums
          if (_featuredAlbums.isNotEmpty) ...[
            Text(
              'Últimos Lanzamientos',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredAlbums.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AlbumCard(album: _featuredAlbums[index]),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
