import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import 'music_service.dart';

class PlaylistService {
  final ApiClient _apiClient = ApiClient();
  final MusicService _musicService = MusicService();

  Future<ApiResponse<List<Playlist>>> getUserPlaylists(int userId) async {
    final response =
        await _apiClient.get('${AppConstants.playlistsUrl}/user/$userId');
    if (response.success && response.data != null) {
      final playlists = (response.data as List)
          .map((json) => Playlist.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: playlists);
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Playlist>> getPlaylistById(int id) async {
    final response = await _apiClient.get('${AppConstants.playlistsUrl}/$id');
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Playlist.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Map<String, dynamic>>> getPlaylistWithSongs(int id) async {
    final playlistResponse = await getPlaylistById(id);
    if (!playlistResponse.success || playlistResponse.data == null) {
      return ApiResponse(success: false, error: playlistResponse.error);
    }

    final playlist = playlistResponse.data!;
    final List<Song> songs = [];

    for (final songId in playlist.songIds) {
      final songResponse = await _musicService.getSongById(songId);
      if (songResponse.success && songResponse.data != null) {
        songs.add(songResponse.data!);
      }
    }

    return ApiResponse(
      success: true,
      data: {'playlist': playlist, 'songs': songs},
    );
  }

  Future<ApiResponse<Playlist>> createPlaylist(
      Map<String, dynamic> playlistData) async {
    final response =
        await _apiClient.post(AppConstants.playlistsUrl, body: playlistData);
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Playlist.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<Playlist>> updatePlaylist({
    required int playlistId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (isPublic != null) body['isPublic'] = isPublic;

      final response = await _apiClient.patch(
        '${AppConstants.playlistsUrl}/$playlistId',
        body: body,
      );

      if (response.success && response.data != null) {
        return ApiResponse(
            success: true,
            data: Playlist.fromJson(response.data),
            statusCode: response.statusCode);
      }

      return ApiResponse(
          success: false,
          error: response.error ?? 'Failed to update playlist',
          statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<Playlist>> addSongToPlaylist(
      int playlistId, int songId) async {
    final response = await _apiClient.post(
      '${AppConstants.playlistsUrl}/$playlistId/songs',
      queryParameters: {'songId': songId.toString()},
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: Playlist.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  Future<ApiResponse<void>> removeSongFromPlaylist(
      int playlistId, int songId) async {
    return await _apiClient
        .delete('${AppConstants.playlistsUrl}/$playlistId/songs/$songId');
  }

  Future<ApiResponse<void>> deletePlaylist(int playlistId) async {
    return await _apiClient.delete('${AppConstants.playlistsUrl}/$playlistId');
  }
}
