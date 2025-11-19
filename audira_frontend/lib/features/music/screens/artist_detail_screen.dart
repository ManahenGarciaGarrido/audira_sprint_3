// ignore_for_file: use_build_context_synchronously

import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/artist.dart';
import 'package:audira_frontend/core/models/song.dart';
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArtistDetailScreen extends StatefulWidget {
  final int artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();

  Artist? _artist;
  List<Song> _songs = [];
  List<Album> _albums = [];

  bool _isLoading = true;
  bool _isFollowing = false;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArtistDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistResponse = await _musicService.getArtistById(widget.artistId);
      if (artistResponse.success && artistResponse.data != null) {
        _artist = artistResponse.data;

        final songsResponse =
            await _musicService.getSongsByArtist(widget.artistId);
        if (songsResponse.success && songsResponse.data != null) {
          _songs = songsResponse.data!;
        }

        final albumsResponse =
            await _musicService.getAlbumsByArtist(widget.artistId);
        if (albumsResponse.success && albumsResponse.data != null) {
          _albums = albumsResponse.data!;
        }

        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAuthenticated) {
          _isFollowing =
              authProvider.currentUser!.followingIds.contains(widget.artistId);
        }
      } else {
        _error = artistResponse.error ?? 'Failed to load artist';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to follow artists')),
      );
      return;
    }

    // Follow/unfollow functionality
    setState(() => _isFollowing = !_isFollowing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? 'Following artist' : 'Unfollowed artist'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _artist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Artist not found'),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _artist!.artistName ?? _artist!.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_artist!.bannerImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: _artist!.bannerImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.surfaceBlack,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.backgroundBlack,
                          ],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildArtistInfo(),
                _buildTabs(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_artist!.profileImageUrl != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: CachedNetworkImageProvider(
                    _artist!.profileImageUrl!,
                  ),
                )
              else
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    (_artist!.artistName ?? _artist!.username)[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_artist!.verifiedArtist)
                      Row(
                        children: const [
                          Icon(Icons.verified, color: Colors.blue, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Verified Artist',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              '${_artist!.followerIds.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Followers',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            Text(
                              '${_songs.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Songs',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            Text(
                              '${_albums.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Albums',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(_isFollowing ? Icons.check : Icons.add),
              label: Text(_isFollowing ? 'Following' : 'Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isFollowing ? AppTheme.darkBlue : AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_artist!.artistBio != null && _artist!.artistBio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _artist!.artistBio!,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
          if (_artist!.recordLabel != null &&
              _artist!.recordLabel!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, size: 16),
                const SizedBox(width: 4),
                Text(
                  _artist!.recordLabel!,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildSongsTab(),
              _buildAlbumsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_songs.isNotEmpty) ...[
            const Text(
              'Popular Songs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._songs.take(5).map((song) => Card(
                  child: ListTile(
                    leading: song.coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: song.coverImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.music_note),
                    title: Text(song.name),
                    subtitle: Text(song.durationFormatted),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      onPressed: () {},
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/song', arguments: song.id);
                    },
                  ),
                )),
          ],
          if (_albums.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Recent Albums',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._albums.take(3).map((album) => Card(
                  child: ListTile(
                    leading: album.coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: album.coverImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.album),
                    title: Text(album.name),
                    subtitle: album.releaseDate != null
                        ? Text(album.releaseDate.toString().split(' ')[0])
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      onPressed: () {},
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/album',
                          arguments: album.id);
                    },
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return const Center(child: Text('No songs available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Card(
          child: ListTile(
            leading: song.coverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: song.coverImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.music_note),
            title: Text(song.name),
            subtitle: Text(song.durationFormatted),
            trailing: Text(
              '\$${song.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/song', arguments: song.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) {
      return const Center(child: Text('No albums available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return Card(
          child: ListTile(
            leading: album.coverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: album.coverImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.album),
            title: Text(album.name),
            subtitle: album.releaseDate != null
                ? Text(album.releaseDate.toString().split(' ')[0])
                : null,
            trailing: Text(
              '\$${album.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/album', arguments: album.id);
            },
          ),
        );
      },
    );
  }
}
