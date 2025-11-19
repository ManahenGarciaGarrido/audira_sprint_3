import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../api/services/playlist_service.dart';
import '../api/services/library_service.dart';
import '../api/services/music_service.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';

class LibraryProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  final LibraryService _libraryService = LibraryService();
  final MusicService _musicService = MusicService();

  List<Song> _favoriteSongs = [];
  List<Album> _favoriteAlbums = [];
  bool _isFavoritesLoading = false;

  List<Playlist> _playlists = [];
  bool _isPlaylistsLoading = false;

  List<Song> _purchasedSongs = [];
  List<Album> _purchasedAlbums = [];
  bool _isLibraryLoading = false;

  List<Song> get favoriteSongs => _favoriteSongs;
  List<Album> get favoriteAlbums => _favoriteAlbums;
  List<Playlist> get playlists => _playlists;
  List<Song> get purchasedSongs => _purchasedSongs;
  List<Album> get purchasedAlbums => _purchasedAlbums;
  bool get isFavoritesLoading => _isFavoritesLoading;
  bool get isPlaylistsLoading => _isPlaylistsLoading;
  bool get isLibraryLoading => _isLibraryLoading;

  Future<void> loadFavorites(int userId) async {
    _isFavoritesLoading = true;
    notifyListeners();

    try {
      // Using empty lists for now
      _favoriteSongs = [];
      _favoriteAlbums = [];
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isFavoritesLoading = false;
      notifyListeners();
    }
  }

  bool isSongFavorite(int songId) {
    return _favoriteSongs.any((song) => song.id == songId);
  }

  bool isAlbumFavorite(int albumId) {
    return _favoriteAlbums.any((album) => album.id == albumId);
  }

  Future<void> toggleSongFavorite(int userId, Song song) async {
    try {
      final isFavorite = isSongFavorite(song.id);

      if (isFavorite) {
        _favoriteSongs.removeWhere((s) => s.id == song.id);
      } else {
        _favoriteSongs.add(song);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling song favorite: $e');
      rethrow;
    }
  }

  Future<void> toggleAlbumFavorite(int userId, Album album) async {
    try {
      final isFavorite = isAlbumFavorite(album.id);

      if (isFavorite) {
        _favoriteAlbums.removeWhere((a) => a.id == album.id);
      } else {
        _favoriteAlbums.add(album);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling album favorite: $e');
      rethrow;
    }
  }

  Future<void> loadPlaylists(int userId) async {
    _isPlaylistsLoading = true;
    notifyListeners();

    try {
      final response = await _playlistService.getUserPlaylists(userId);
      if (response.success && response.data != null) {
        _playlists = response.data!;
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      _isPlaylistsLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist?> createPlaylist({
    required int userId,
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final Map<String, dynamic> playlistData = {
        'userId': userId,
        'name': name,
        'description': description,
        'isPublic': isPublic,
      };

      final response = await _playlistService.createPlaylist(playlistData);

      if (response.success && response.data != null) {
        _playlists.add(response.data!);
        notifyListeners();
        return response.data;
      }

      return null;
    } catch (e) {
      debugPrint('Error creating playlist: $e');
      rethrow;
    }
  }

  Future<void> updatePlaylist({
    required int playlistId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final response = await _playlistService.updatePlaylist(
        playlistId: playlistId,
        name: name,
        description: description,
        isPublic: isPublic,
      );

      if (response.success && response.data != null) {
        final index = _playlists.indexWhere((p) => p.id == playlistId);
        if (index != -1) {
          _playlists[index] = response.data!;
          notifyListeners();
        }
      }
      debugPrint(
          "FUNCIONALIDAD 'updatePlaylist' PENDIENTE DE IMPLEMENTAR EN PlaylistService");
      throw UnimplementedError(
          "updatePlaylist no está implementado en PlaylistService");
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      rethrow;
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      final response = await _playlistService.deletePlaylist(playlistId);

      if (response.success) {
        _playlists.removeWhere((p) => p.id == playlistId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      rethrow;
    }
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    try {
      final response = await _playlistService.addSongToPlaylist(
        playlistId,
        songId,
      );

      if (response.success) {
        final playlistResponse =
            await _playlistService.getPlaylistById(playlistId);
        if (playlistResponse.success && playlistResponse.data != null) {
          final index = _playlists.indexWhere((p) => p.id == playlistId);
          if (index != -1) {
            _playlists[index] = playlistResponse.data!;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error adding song to playlist: $e');
      rethrow;
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      final response = await _playlistService.removeSongFromPlaylist(
        playlistId,
        songId,
      );

      if (response.success) {
        final index = _playlists.indexWhere((p) => p.id == playlistId);
        if (index != -1) {
          _playlists[index].songIds.removeWhere((id) => id == songId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error removing song from playlist: $e');
      rethrow;
    }
  }

  // Save purchased content to local storage
  Future<void> _savePurchasedContentToLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save songs
      final songsJson = jsonEncode(_purchasedSongs.map((s) => s.toJson()).toList());
      await prefs.setString('purchased_songs_$userId', songsJson);

      // Save albums
      final albumsJson = jsonEncode(_purchasedAlbums.map((a) => a.toJson()).toList());
      await prefs.setString('purchased_albums_$userId', albumsJson);

      debugPrint('Purchased content saved to local storage');
    } catch (e) {
      debugPrint('Error saving purchased content to local storage: $e');
    }
  }

  // Load purchased content from local storage
  Future<void> _loadPurchasedContentFromLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load songs
      final songsJson = prefs.getString('purchased_songs_$userId');
      if (songsJson != null) {
        final songsList = jsonDecode(songsJson) as List;
        _purchasedSongs = songsList.map((s) => Song.fromJson(s)).toList();
      }

      // Load albums
      final albumsJson = prefs.getString('purchased_albums_$userId');
      if (albumsJson != null) {
        final albumsList = jsonDecode(albumsJson) as List;
        _purchasedAlbums = albumsList.map((a) => Album.fromJson(a)).toList();
      }

      debugPrint('Purchased content loaded from local storage: ${_purchasedSongs.length} songs, ${_purchasedAlbums.length} albums');
    } catch (e) {
      debugPrint('Error loading purchased content from local storage: $e');
    }
  }

  // Clear purchased content from local storage
  Future<void> _clearPurchasedContentFromLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('purchased_songs_$userId');
      await prefs.remove('purchased_albums_$userId');
    } catch (e) {
      debugPrint('Error clearing purchased content from local storage: $e');
    }
  }

  Future<void> loadLibrary(int userId) async {
    _isLibraryLoading = true;
    notifyListeners();

    try {
      // Load from local storage first (for offline capability)
      await _loadPurchasedContentFromLocal(userId);

      // Sync with server to get the latest purchased items
      debugPrint('Loading library from server for user: $userId');
      final response = await _libraryService.getUserLibrary(userId);

      if (response.success && response.data != null) {
        final library = response.data!;
        debugPrint('Library loaded from server: ${library.totalItems} items');

        // Clear current lists
        _purchasedSongs.clear();
        _purchasedAlbums.clear();

        // Load full song and album details for each purchased item
        for (var item in library.songs) {
          final songResponse = await _musicService.getSongById(item.itemId);
          if (songResponse.success && songResponse.data != null) {
            _purchasedSongs.add(songResponse.data!);
          }
        }

        for (var item in library.albums) {
          final albumResponse = await _musicService.getAlbumById(item.itemId);
          if (albumResponse.success && albumResponse.data != null) {
            _purchasedAlbums.add(albumResponse.data!);
          }
        }

        // Save to local storage as backup
        await _savePurchasedContentToLocal(userId);

        debugPrint('Library loaded: ${_purchasedSongs.length} songs, ${_purchasedAlbums.length} albums');
      } else {
        debugPrint('Failed to load library from server: ${response.error}');
        // Keep using the local cache if server fails
      }
    } catch (e) {
      debugPrint('Error loading library: $e');
      // Keep using the local cache if error occurs
    } finally {
      _isLibraryLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPurchasedSong(Song song, {int? userId}) async {
    if (!_purchasedSongs.any((s) => s.id == song.id)) {
      _purchasedSongs.add(song);
      if (userId != null) {
        await _savePurchasedContentToLocal(userId);
      }
      notifyListeners();
    }
  }

  Future<void> addPurchasedAlbum(Album album, {int? userId}) async {
    if (!_purchasedAlbums.any((a) => a.id == album.id)) {
      _purchasedAlbums.add(album);
      if (userId != null) {
        await _savePurchasedContentToLocal(userId);
      }
      notifyListeners();
    }
  }

  Future<void> addPurchasedContent(List<Song> songs, List<Album> albums, {int? userId}) async {
    bool changed = false;
    for (final song in songs) {
      if (!_purchasedSongs.any((s) => s.id == song.id)) {
        _purchasedSongs.add(song);
        changed = true;
      }
    }
    for (final album in albums) {
      if (!_purchasedAlbums.any((a) => a.id == album.id)) {
        _purchasedAlbums.add(album);
        changed = true;
      }
    }
    if (changed) {
      if (userId != null) {
        await _savePurchasedContentToLocal(userId);
      }
      notifyListeners();
    }
  }

  bool isSongPurchased(int songId) {
    return _purchasedSongs.any((song) => song.id == songId);
  }

  bool isAlbumPurchased(int albumId) {
    return _purchasedAlbums.any((album) => album.id == albumId);
  }

  Future<void> clearLibrary({int? userId}) async {
    _favoriteSongs.clear();
    _favoriteAlbums.clear();
    _playlists.clear();
    _purchasedSongs.clear();
    _purchasedAlbums.clear();
    if (userId != null) {
      await _clearPurchasedContentFromLocal(userId);
    }
    notifyListeners();
  }
}
