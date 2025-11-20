import '../api_client.dart';
import '../../models/user.dart';

/// Service for admin user management operations
/// GA01-164: Buscar/editar usuario (roles, estado)
/// GA01-165: Suspender/reactivar cuentas
class AdminService {
  final ApiClient _apiClient = ApiClient();

  /// Get all users (admin endpoint)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> getAllUsersAdmin() async {
    final response = await _apiClient.get(
      '/api/admin/users',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> usersJson = response.data as List<dynamic>;
        final users = usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: users);
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear usuarios: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get user by ID (admin endpoint)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<User>> getUserByIdAdmin(int userId) async {
    final response = await _apiClient.get(
      '/api/admin/users/$userId',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear usuario: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Change user role
  /// GA01-164: Buscar/editar usuario (roles, estado)
  Future<ApiResponse<User>> changeUserRole(int userId, String newRole) async {
    final response = await _apiClient.put(
      '/api/admin/users/$userId/role',
      body: {'role': newRole},
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(success: false, error: 'Error al cambiar rol: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Change user active status
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> changeUserStatus(int userId, bool isActive) async {
    final response = await _apiClient.put(
      '/api/admin/users/$userId/status',
      body: {'isActive': isActive},
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al cambiar estado: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Suspend user account (shortcut)
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> suspendUser(int userId) async {
    final response = await _apiClient.put(
      '/api/admin/users/$userId/suspend',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al suspender usuario: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Activate user account (shortcut)
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> activateUser(int userId) async {
    final response = await _apiClient.put(
      '/api/admin/users/$userId/activate',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al activar usuario: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get user statistics
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<Map<String, dynamic>>> getUserStatistics() async {
    final response = await _apiClient.get(
      '/api/admin/users/stats',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al cargar estadísticas: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Search users
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    final response = await _apiClient.get(
      '/api/admin/users/search',
      queryParameters: {'query': query},
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> usersJson = response.data as List<dynamic>;
        final users = usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: users);
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al buscar usuarios: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get users by role
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> getUsersByRole(String role) async {
    final response = await _apiClient.get(
      '/api/admin/users/by-role/$role',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> usersJson = response.data as List<dynamic>;
        final users = usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: users);
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al cargar usuarios por rol: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Verify user email (admin action)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<User>> verifyUserEmail(int userId) async {
    final response = await _apiClient.put(
      '/api/admin/users/$userId/verify',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al verificar usuario: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }
}
