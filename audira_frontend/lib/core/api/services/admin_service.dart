import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/constants.dart';
import '../../models/api_response.dart';
import '../../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for admin user management operations
/// GA01-164: Buscar/editar usuario (roles, estado)
/// GA01-165: Suspender/reactivar cuentas
class AdminService {
  final String baseUrl = ApiConstants.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get authorization header with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all users (admin endpoint)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> getAllUsersAdmin() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading users: $e');
    }
  }

  /// Get user by ID (admin endpoint)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<User>> getUserByIdAdmin(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading user: $e');
    }
  }

  /// Change user role
  /// GA01-164: Buscar/editar usuario (roles, estado)
  Future<ApiResponse<User>> changeUserRole(int userId, String newRole) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/role'),
        headers: headers,
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error changing user role: $e');
    }
  }

  /// Change user active status
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> changeUserStatus(int userId, bool isActive) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/status'),
        headers: headers,
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error changing user status: $e');
    }
  }

  /// Suspend user account (shortcut)
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> suspendUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/suspend'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error suspending user: $e');
    }
  }

  /// Activate user account (shortcut)
  /// GA01-165: Suspender/reactivar cuentas
  Future<ApiResponse<User>> activateUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/activate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error activating user: $e');
    }
  }

  /// Get user statistics
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<Map<String, dynamic>>> getUserStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final stats = json.decode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(stats);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading statistics: $e');
    }
  }

  /// Search users
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/search?query=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error searching users: $e');
    }
  }

  /// Get users by role
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<List<User>>> getUsersByRole(String role) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/by-role/$role'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error loading users by role: $e');
    }
  }

  /// Verify user email (admin action)
  /// GA01-164: Buscar/editar usuario
  Future<ApiResponse<User>> verifyUserEmail(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/verify'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        return ApiResponse.success(user);
      } else {
        final error = _extractError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Error verifying user: $e');
    }
  }

  /// Extract error message from response
  String _extractError(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      if (data is Map && data.containsKey('error')) {
        return data['error'];
      }
      return 'Error: ${response.statusCode}';
    } catch (e) {
      return 'Error: ${response.statusCode} - ${response.body}';
    }
  }
}
