// ignore_for_file: empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';
import '../../config/constants.dart';
import '../models/user.dart';
import '../models/artist.dart';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json;
    final role = userJson['role'] as String;

    User user;
    if (role == AppConstants.roleArtist) {
      user = Artist.fromJson(userJson);
    } else {
      user = User.fromJson(userJson);
    }

    return AuthResponse(
      token: json['token'] as String,
      user: user,
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<ApiResponse<AuthResponse>> register({
    required String email,
    required String username,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? artistName,
  }) async {
    try {
      final body = {
        'email': email,
        'username': username,
        'password': password,
        'role': role,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (artistName != null && role == AppConstants.roleArtist)
          'artistName': artistName,
      };

      final response = await _apiClient.post(
        AppConstants.authRegisterUrl,
        body: body,
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final authResponse =
            AuthResponse.fromJson(response.data as Map<String, dynamic>);
        await _saveAuthData(authResponse);

        return ApiResponse(
          success: true,
          data: authResponse,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error al registrar: $e',
      );
    }
  }

  Future<ApiResponse<AuthResponse>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final body = {
        'emailOrUsername': emailOrUsername,
        'password': password,
      };

      final response = await _apiClient.post(
        AppConstants.authLoginUrl,
        body: body,
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final authResponse =
            AuthResponse.fromJson(response.data as Map<String, dynamic>);
        await _saveAuthData(authResponse);

        return ApiResponse(
          success: true,
          data: authResponse,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error al iniciar sesión: $e',
      );
    }
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _storage.write(
      key: AppConstants.authTokenKey,
      value: authResponse.token,
    );
    await _storage.write(
      key: AppConstants.userIdKey,
      value: authResponse.user.id.toString(),
    );
    await _storage.write(
      key: AppConstants.userRoleKey,
      value: authResponse.user.role,
    );
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(authResponse.user.toJson()),
    );
  }

  Future<User?> getCurrentUser() async {
    try {
      final userData = await _storage.read(key: AppConstants.userDataKey);
      if (userData != null) {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        final role = userJson['role'] as String;

        if (role == AppConstants.roleArtist) {
          return Artist.fromJson(userJson);
        }
        return User.fromJson(userJson);
      }
    } catch (e) {}
    return null;
  }

  Future<String?> getCurrentUserId() async {
    return await _storage.read(key: AppConstants.userIdKey);
  }

  Future<String?> getCurrentUserRole() async {
    return await _storage.read(key: AppConstants.userRoleKey);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConstants.authTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null;
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.authTokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
    await _storage.delete(key: AppConstants.userRoleKey);
    await _storage.delete(key: AppConstants.userDataKey);
  }

  Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await _apiClient.get(AppConstants.userProfileUrl);

      if (response.success && response.data != null) {
        final userJson = response.data as Map<String, dynamic>;
        final role = userJson['role'] as String;

        User user;
        if (role == AppConstants.roleArtist) {
          user = Artist.fromJson(userJson);
        } else {
          user = User.fromJson(userJson);
        }

        // Update stored user data
        await _storage.write(
          key: AppConstants.userDataKey,
          value: jsonEncode(user.toJson()),
        );

        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error al obtener perfil: $e',
      );
    }
  }

  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> updates) async {
    try {
      debugPrint('🟦 AuthService.updateProfile - Enviando request');
      final response = await _apiClient.put(
        AppConstants.userProfileUrl,
        body: updates,
      );

      debugPrint('🟦 AuthService - Response recibido: success=${response.success}, data=${response.data != null}');

      if (response.success && response.data != null) {
        final userJson = response.data as Map<String, dynamic>;
        debugPrint('🟦 AuthService - userJson keys: ${userJson.keys.toList()}');
        debugPrint('🟦 AuthService - twitterUrl en JSON: ${userJson['twitterUrl']}');

        final role = userJson['role'] as String;

        User user;
        if (role == AppConstants.roleArtist) {
          user = Artist.fromJson(userJson);
        } else {
          user = User.fromJson(userJson);
        }

        debugPrint('🟦 AuthService - User creado, twitterUrl: ${user.twitterUrl}');

        // Update stored user data
        await _storage.write(
          key: AppConstants.userDataKey,
          value: jsonEncode(user.toJson()),
        );

        debugPrint('🟦 AuthService - Retornando ApiResponse con user');
        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      }

      debugPrint('🔴 AuthService - Response no exitoso o sin data');
      return ApiResponse(
        success: false,
        error: response.error,
        statusCode: response.statusCode,
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 AuthService - Exception: $e');
      debugPrint('🔴 StackTrace: $stackTrace');
      return ApiResponse(
        success: false,
        error: 'Error al actualizar perfil: $e',
      );
    }
  }

  Future<ApiResponse<List<User>>> getAllUsers() async {
    try {
      // Asume que la llamada a 'get' sin 'requiresAuth: false' usa autenticación por defecto
      final response = await _apiClient.get(AppConstants.allUsersUrl);

      if (response.success && response.data != null) {
        // Espera que la API devuelva una lista de objetos de usuario
        final List<dynamic> userListData = response.data as List<dynamic>;

        // Mapea la lista de JSON a una lista de objetos User/Artist
        final List<User> users = userListData.map((userData) {
          final userJson = userData as Map<String, dynamic>;
          final role = userJson['role'] as String;

          if (role == AppConstants.roleArtist) {
            return Artist.fromJson(userJson);
          } else {
            return User.fromJson(userJson);
          }
        }).toList();

        return ApiResponse(
          success: true,
          data: users,
          statusCode: response.statusCode,
        );
      }

      // Maneja la respuesta de error de la API
      return ApiResponse(
        success: false,
        error: response.error ?? 'Error desconocido al obtener usuarios',
        statusCode: response.statusCode,
      );
    } catch (e) {
      // Maneja excepciones de red o de parseo
      return ApiResponse(
        success: false,
        error: 'Excepción al obtener usuarios: $e',
      );
    }
  } 

  /// Upload profile image
  Future<ApiResponse<User>> uploadProfileImage(
      File imageFile, int userId) async {
    try {
      final uri = Uri.parse(
          '${AppConstants.apiGatewayUrl}/api/users/profile/image');

      final request = http.MultipartRequest('POST', uri);
      request.fields['userId'] = userId.toString();

      final token = await getAuthToken();
      if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
      } else {
          // Manejar el caso de token nulo si es necesario
          throw Exception('No hay token de autenticación disponible.');
      }

      // Determinar el content-type basándose en la extensión
      String? contentType;
      final extension = imageFile.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>;
        final role = userJson['role'] as String;

        User user;
        if (role == AppConstants.roleArtist) {
          user = Artist.fromJson(userJson);
        } else {
          user = User.fromJson(userJson);
        }

        // Update stored user data
        await _storage.write(
          key: AppConstants.userDataKey,
          value: jsonEncode(user.toJson()),
        );

        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: errorData['error'] ?? 'Error al subir imagen',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error al subir imagen: $e',
      );
    }
  }

  /// Upload banner image
  Future<ApiResponse<User>> uploadBannerImage(
      File imageFile, int userId) async {
    try {
      final uri = Uri.parse(
          '${AppConstants.apiGatewayUrl}/api/users/profile/banner');

      final request = http.MultipartRequest('POST', uri);
      request.fields['userId'] = userId.toString();

      final token = await getAuthToken();
      if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
      } else {
          throw Exception('No hay token de autenticación disponible.');
      }

      // Determinar el content-type basándose en la extensión
      String? contentType;
      final extension = imageFile.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>;
        final role = userJson['role'] as String;

        User user;
        if (role == AppConstants.roleArtist) {
          user = Artist.fromJson(userJson);
        } else {
          user = User.fromJson(userJson);
        }

        // Update stored user data
        await _storage.write(
          key: AppConstants.userDataKey,
          value: jsonEncode(user.toJson()),
        );

        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: errorData['error'] ?? 'Error al subir banner',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error al subir banner: $e',
      );
    }
  }

  /// Change password
  Future<ApiResponse<void>> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      Uri.parse('${AppConstants.apiGatewayUrl}/api/users/change-password')
          .replace(queryParameters: {'userId': userId.toString()});

      final body = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      final response = await _apiClient.post(
        '/api/users/change-password?userId=$userId',
        body: body,
        requiresAuth: false,
      );

      if (response.success) {
        return ApiResponse(
          success: true,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error al cambiar contraseña: $e',
      );
    }
  }
}
