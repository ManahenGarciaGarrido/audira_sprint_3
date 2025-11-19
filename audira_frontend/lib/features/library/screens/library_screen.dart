import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/models/playlist.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PlaylistService _playlistService = PlaylistService();

  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Schedule loading after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlaylists();
      _loadLibrary();
    });
  }

  Future<void> _loadLibrary() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await libraryProvider.loadLibrary(authProvider.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    setState(() => _isLoading = true);

    final response =
        await _playlistService.getUserPlaylists(authProvider.currentUser!.id);
    if (response.success && response.data != null) {
      _playlists = response.data!;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca'),
        centerTitle: true,
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, child) {
          return Column(
            children: [
              Material(
                color: AppTheme.surfaceBlack,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppTheme.primaryBlue,
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.textGrey,
                  tabs: const [
                    Tab(text: 'Canciones'),
                    Tab(text: 'Álbumes'),
                    Tab(text: 'Playlists'),
                    Tab(text: 'Favoritos'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Songs
                    _buildSongsTab(libraryProvider),

                    // Albums
                    _buildAlbumsTab(libraryProvider),

                    // Playlists
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _playlists.isEmpty
                            ? _buildEmptyState('Playlists', Icons.playlist_play)
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _playlists.length,
                                itemBuilder: (context, index) {
                                  final playlist = _playlists[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.playlist_play),
                                      ),
                                      title: Text(playlist.name),
                                      subtitle: Text(
                                        '${playlist.songCount} canciones',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textGrey,
                                            ),
                                      ),
                                      trailing: Icon(
                                        playlist.isPublic ? Icons.public : Icons.lock,
                                        color: AppTheme.textGrey,
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/playlist',
                                          arguments: playlist.id,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),

                    // Favorites
                    _buildFavoritesTab(libraryProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSongsTab(LibraryProvider libraryProvider) {
    final songs = libraryProvider.purchasedSongs;

    if (songs.isEmpty) {
      return _buildEmptyState('Canciones', Icons.music_note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note),
            ),
            title: Text(song.name),
            subtitle: Text(
              song.artistName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
            ),
            trailing: Text(
              '\$${song.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/song',
                arguments: song.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab(LibraryProvider libraryProvider) {
    final albums = libraryProvider.purchasedAlbums;

    if (albums.isEmpty) {
      return _buildEmptyState('Álbumes', Icons.album);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.album),
            ),
            title: Text(album.name),
            subtitle: Text(
              'Artista ID: ${album.artistId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
            ),
            trailing: Text(
              '\$${album.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/album',
                arguments: album.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab(LibraryProvider libraryProvider) {
    final favoriteSongs = libraryProvider.favoriteSongs;
    final favoriteAlbums = libraryProvider.favoriteAlbums;

    if (favoriteSongs.isEmpty && favoriteAlbums.isEmpty) {
      return _buildEmptyState('Favoritos', Icons.favorite);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (favoriteSongs.isNotEmpty) ...[
          Text(
            'Canciones favoritas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...favoriteSongs.map((song) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note),
                  ),
                  title: Text(song.name),
                  subtitle: Text(
                    song.artistName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                  ),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/song',
                      arguments: song.id,
                    );
                  },
                ),
              )),
          const SizedBox(height: 24),
        ],
        if (favoriteAlbums.isNotEmpty) ...[
          Text(
            'Álbumes favoritos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...favoriteAlbums.map((album) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.album),
                  ),
                  title: Text(album.name),
                  subtitle: Text(
                    'Artista ID: ${album.artistId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                  ),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/album',
                      arguments: album.id,
                    );
                  },
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay $title',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tus $title aparecerán aquí',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGrey,
                ),
          ),
        ],
      ),
    );
  }
}
