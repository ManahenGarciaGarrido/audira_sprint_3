import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/models/playlist.dart';
import '../../../config/routes.dart';

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
    _tabController = TabController(length: 5, vsync: this);
    // Listen to tab changes to update FAB visibility
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
                    Tab(text: 'Descargas'),
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
                            ? _buildEmptyPlaylistsState(context)
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _playlists.length,
                                itemBuilder: (context, index) {
                                  final playlist = _playlists[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    color: AppTheme.surfaceBlack,
                                    child: ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.playlist_play, color: Colors.white),
                                      ),
                                      title: Text(
                                        playlist.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Icon(
                                            playlist.isPublic ? Icons.public : Icons.lock,
                                            size: 12,
                                            color: AppTheme.textGrey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${playlist.songCount} ${playlist.songCount == 1 ? "canción" : "canciones"}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.textGrey,
                                                ),
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        color: AppTheme.textGrey,
                                      ),
                                      onTap: () async {
                                        final result = await Navigator.pushNamed(
                                          context,
                                          '/playlist',
                                          arguments: playlist.id,
                                        );
                                        if (result == true) {
                                          _loadPlaylists();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),

                    // Favorites
                    _buildFavoritesTab(libraryProvider),

                    // Downloads
                    // GA01-137: Registro de descargas
                    _buildDownloadsTab(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _tabController.index == 2 && authProvider.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/playlist/create');
                if (result == true) {
                  _loadPlaylists();
                }
              },
              backgroundColor: AppTheme.primaryBlue,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Playlist'),
            )
          : null,
    );
  }

  Widget _buildEmptyPlaylistsState(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_play,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay playlists',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera playlist y organiza\ntu música favorita',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (authProvider.isAuthenticated)
            ElevatedButton.icon(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/playlist/create');
                if (result == true) {
                  _loadPlaylists();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
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

  Widget _buildDownloadsTab(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final downloads = downloadProvider.downloadedSongs;

        if (downloads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.download_outlined,
                  size: 80,
                  color: AppTheme.textGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No tienes descargas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Las canciones que descargues aparecerán aquí',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.downloads);
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explorar música'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${downloads.length} canciones descargadas',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.downloads);
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver todas'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: downloads.length > 5 ? 5 : downloads.length,
                itemBuilder: (context, index) {
                  final download = downloads[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppTheme.surfaceBlack,
                    child: ListTile(
                      leading: download.coverImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                download.coverImageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 50,
                                  height: 50,
                                  color: AppTheme.darkBlue,
                                  child: const Icon(Icons.music_note,
                                      color: Colors.white),
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.darkBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Colors.white),
                            ),
                      title: Text(
                        download.songName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            download.artistName,
                            style: const TextStyle(color: AppTheme.textGrey),
                          ),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: AppTheme.textGrey)),
                          const SizedBox(width: 8),
                          Text(
                            download.fileSizeFormatted,
                            style: const TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_done,
                            color: Colors.green[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: AppTheme.textGrey,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.downloads);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
