import 'package:audira_frontend/core/api/api_client.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/song.dart';

class DiscoveryService {
  static final DiscoveryService _instance = DiscoveryService._internal();
  factory DiscoveryService() => _instance;
  DiscoveryService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Search songs 
  Future<ApiResponse<Map<String, dynamic>>> searchSongs(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/discovery/search/songs',
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'size': size.toString(),
        },
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final List<dynamic> content = data['content'] as List;
        final songs = content.map((json) => Song.fromJson(json)).toList();

        return ApiResponse(
          success: true,
          data: {
            'songs': songs,
            'currentPage': data['currentPage'],
            'totalItems': data['totalItems'],
            'totalPages': data['totalPages'],
            'hasMore': data['hasMore'],
          },
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to search songs',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Search albums 
  Future<ApiResponse<Map<String, dynamic>>> searchAlbums(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/discovery/search/albums',
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'size': size.toString(),
        },
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final List<dynamic> content = data['content'] as List;
        final albums = content.map((json) => Album.fromJson(json)).toList();

        return ApiResponse(
          success: true,
          data: {
            'albums': albums,
            'currentPage': data['currentPage'],
            'totalItems': data['totalItems'],
            'totalPages': data['totalPages'],
            'hasMore': data['hasMore'],
          },
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to search albums',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get trending songs
  Future<ApiResponse<List<Song>>> getTrendingSongs({int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/api/discovery/trending/songs',
        queryParameters: {'limit': limit.toString()},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final songs = data.map((json) => Song.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: songs,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch trending songs',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get trending albums
  Future<ApiResponse<List<Album>>> getTrendingAlbums({int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/api/discovery/trending/albums',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final albums = data.map((json) => Album.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: albums,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch trending albums',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get latest album releases
  Future<ApiResponse<List<Album>>> getLatestReleases({int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/api/albums/latest-releases',
        queryParameters: {'limit': limit.toString()},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final albums = data.map((json) => Album.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: albums,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch latest releases',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get recommendations for user
  Future<ApiResponse<Map<String, dynamic>>> getRecommendations(
      int userId) async {
    try {
      final response = await _apiClient.get(
        '/api/discovery/recommendations',
        queryParameters: {'userId': userId.toString()},
      );

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch recommendations',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
}
