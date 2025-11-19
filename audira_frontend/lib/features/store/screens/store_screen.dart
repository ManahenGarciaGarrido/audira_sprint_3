import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../common/widgets/song_list_item.dart';
import '../../common/widgets/album_list_item.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MusicService _musicService = MusicService();

  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final songsResponse = await _musicService.getAllSongs();
    final albumsResponse = await _musicService.getAllAlbums();

    if (songsResponse.success && songsResponse.data != null) {
      _songs = songsResponse.data!;
    }

    if (albumsResponse.success && albumsResponse.data != null) {
      _albums = albumsResponse.data!;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.surfaceBlack,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textGrey,
            tabs: const [
              Tab(text: 'Canciones'),
              Tab(text: 'Álbumes'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Songs Tab
                    _songs.isEmpty
                        ? const Center(
                            child: Text('No hay canciones disponibles'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _songs.length,
                            itemBuilder: (context, index) {
                              return SongListItem(song: _songs[index]);
                            },
                          ),

                    // Albums Tab
                    _albums.isEmpty
                        ? const Center(
                            child: Text('No hay álbumes disponibles'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _albums.length,
                            itemBuilder: (context, index) {
                              return AlbumListItem(album: _albums[index]);
                            },
                          ),
                  ],
                ),
        ),
      ],
    );
  }
}
