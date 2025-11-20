import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../models/genre.dart';
import '../../models/collaborator.dart';
import '../../models/artist.dart';

class MusicService {
  final ApiClient _apiClient = ApiClient();

  // Songs
  Future<ApiResponse<List<Song>>> getAllSongs() async {
    final response = await _apiClient.get(AppConstants.songsUrl, requiresAuth: false);
    if (response.success && response.data != null) {
      final songs = (response.data as List).map((json) => Song.fromJson(json)).toList();
      return ApiResponse(success: true, data: songs);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Song>> getSongById(int id) async {
    final response = await _apiClient.get('${AppConstants.songsUrl}/$id', requiresAuth: false);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Song.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<List<Song>>> getSongsByArtist(int artistId) async {
    final response = await _apiClient.get('${AppConstants.songsUrl}/artist/$artistId', requiresAuth: false);
    if (response.success && response.data != null) {
      final songs = (response.data as List).map((json) => Song.fromJson(json)).toList();
      return ApiResponse(success: true, data: songs);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<List<Song>>> getSongsByGenre(int genreId) async {
    final response = await _apiClient.get('${AppConstants.songsUrl}/genre/$genreId', requiresAuth: false);
    if (response.success && response.data != null) {
      final songs = (response.data as List).map((json) => Song.fromJson(json)).toList();
      return ApiResponse(success: true, data: songs);
    }
    return ApiResponse(success: false, error: response.error);
  }

  // Albums
  Future<ApiResponse<List<Album>>> getAllAlbums() async {
    final response = await _apiClient.get(AppConstants.albumsUrl, requiresAuth: false);
    if (response.success && response.data != null) {
      final albums = (response.data as List).map((json) => Album.fromJson(json)).toList();
      return ApiResponse(success: true, data: albums);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Album>> getAlbumById(int id) async {
    final response = await _apiClient.get('${AppConstants.albumsUrl}/$id', requiresAuth: false);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Album.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<List<Album>>> getAlbumsByArtist(int artistId) async {
    final response = await _apiClient.get('${AppConstants.albumsUrl}/artist/$artistId', requiresAuth: false);
    if (response.success && response.data != null) {
      final albums = (response.data as List).map((json) => Album.fromJson(json)).toList();
      return ApiResponse(success: true, data: albums);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<List<Album>>> getAlbumsByGenre(int genreId) async {
    final response = await _apiClient.get('${AppConstants.albumsUrl}/genre/$genreId', requiresAuth: false);
    if (response.success && response.data != null) {
      final albums = (response.data as List).map((json) => Album.fromJson(json)).toList();
      return ApiResponse(success: true, data: albums);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<List<Song>>> getAlbumSongs(int albumId) async {
    final response = await _apiClient.get('${AppConstants.songsUrl}/album/$albumId', requiresAuth: false);
    if (response.success && response.data != null) {
      final songs = (response.data as List).map((json) => Song.fromJson(json)).toList();
      return ApiResponse(success: true, data: songs);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<List<Song>>> getSongsByAlbum(int albumId) async {
    return getAlbumSongs(albumId);
  }

  // Genres
  Future<ApiResponse<List<Genre>>> getAllGenres() async {
    final response = await _apiClient.get(AppConstants.genresUrl, requiresAuth: false);
    if (response.success && response.data != null) {
      final genres = (response.data as List).map((json) => Genre.fromJson(json)).toList();
      return ApiResponse(success: true, data: genres);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Genre>> getGenreById(int id) async {
    final response = await _apiClient.get('${AppConstants.genresUrl}/$id', requiresAuth: false);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Genre.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  // Collaborators
  Future<ApiResponse<List<Collaborator>>> getSongCollaborators(int songId) async {
    final response = await _apiClient.get('${AppConstants.collaborationsUrl}/song/$songId', requiresAuth: false);
    if (response.success && response.data != null) {
      final collaborators = (response.data as List).map((json) => Collaborator.fromJson(json)).toList();
      return ApiResponse(success: true, data: collaborators);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<List<Collaborator>>> getCollaboratorsBySongId(int songId) async {
    return getSongCollaborators(songId);
  }

  // Create Song (Artist only)
  Future<ApiResponse<Song>> createSong(Map<String, dynamic> songData) async {
    final response = await _apiClient.post(AppConstants.songsUrl, body: songData);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Song.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  // Create Album (Artist only)
  Future<ApiResponse<Album>> createAlbum(Map<String, dynamic> albumData) async {
    final response = await _apiClient.post(AppConstants.albumsUrl, body: albumData);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Album.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  // GA01-151: Update Song (Artist only)
  Future<ApiResponse<Song>> updateSong(int id, Map<String, dynamic> songData) async {
    final response = await _apiClient.put('${AppConstants.songsUrl}/$id', body: songData);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Song.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  // Update Album (Artist only)
  Future<ApiResponse<Album>> updateAlbum(int id, Map<String, dynamic> albumData) async {
    final response = await _apiClient.put('${AppConstants.albumsUrl}/$id', body: albumData);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Album.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  // Publish/Unpublish Album (Artist only)
  Future<ApiResponse<Album>> publishAlbum(int id, bool published) async {
    final response = await _apiClient.patch(
      '${AppConstants.albumsUrl}/$id/publish?published=$published',
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Album.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  // GA01-152: Publish/Unpublish Song (Artist only)
  Future<ApiResponse<Song>> publishSong(int id, bool published) async {
    final response = await _apiClient.patch(
      '${AppConstants.songsUrl}/$id/publish?published=$published',
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Song.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  // Upload Album Cover (Artist only)
  Future<ApiResponse<String>> uploadAlbumCover(int albumId, String filePath) async {
    final response = await _apiClient.uploadFile(
      '${AppConstants.albumsUrl}/$albumId/cover',
      filePath,
      'file',
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data as String);
    }
    return ApiResponse(success: false, error: response.error);
  }

  // Delete methods (Admin only)
  Future<ApiResponse<void>> deleteSong(int id) async {
    final response = await _apiClient.delete('${AppConstants.songsUrl}/$id');
    return ApiResponse(success: response.success, error: response.error);
  }

  Future<ApiResponse<void>> deleteAlbum(int id) async {
    final response = await _apiClient.delete('${AppConstants.albumsUrl}/$id');
    return ApiResponse(success: response.success, error: response.error);
  }

  Future<ApiResponse<void>> deleteGenre(int id) async {
    final response = await _apiClient.delete('${AppConstants.genresUrl}/$id');
    return ApiResponse(success: response.success, error: response.error);
  }

  // Artists
  Future<ApiResponse<Artist>> getArtistById(int id) async {
    final response = await _apiClient.get('/api/users/$id', requiresAuth: false);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Artist.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }
}
