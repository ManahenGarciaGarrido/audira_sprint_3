import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/user.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  /// Get a user by ID
  Future<ApiResponse<User>> getUserById(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.userByIdUrl}/$userId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear usuario: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get current user profile
  Future<ApiResponse<User>> getCurrentUserProfile() async {
    final response = await _apiClient.get(
      AppConstants.userProfileUrl,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear perfil: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get all users
  Future<ApiResponse<List<User>>> getAllUsers() async {
    final response = await _apiClient.get(
      AppConstants.allUsersUrl,
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> usersJson = response.data as List<dynamic>;
        final users = usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: users);
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear usuarios: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get user's followers
  Future<ApiResponse<List<User>>> getUserFollowers(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.userByIdUrl}/$userId/followers',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> usersJson = response.data as List<dynamic>;
        final users = usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: users);
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear seguidores: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get users that a user is following
  Future<ApiResponse<List<User>>> getUserFollowing(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.userByIdUrl}/$userId/following',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> usersJson = response.data as List<dynamic>;
        final users = usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: users);
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear siguiendo: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get artists that a user is following
  Future<ApiResponse<List<User>>> getFollowedArtists(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.userByIdUrl}/$userId/following/artists',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> usersJson = response.data as List<dynamic>;
        final artists = usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: artists);
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al parsear artistas: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Follow a user
  Future<ApiResponse<User>> followUser(int userId, int targetUserId) async {
    final response = await _apiClient.post(
      '${AppConstants.userByIdUrl}/$userId/follow/$targetUserId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al seguir usuario: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Unfollow a user
  Future<ApiResponse<User>> unfollowUser(int userId, int targetUserId) async {
    final response = await _apiClient.delete(
      '${AppConstants.userByIdUrl}/$userId/follow/$targetUserId',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al dejar de seguir: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiClient.put(
      AppConstants.userProfileUrl,
      body: updates,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al actualizar perfil: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }
}
