import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});

  void operator [](String other) {}
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  final String baseUrl = AppConstants.apiGatewayUrl;

  Future<String?> _getAuthToken() async {
    return await _storage.read(key: AppConstants.authTokenKey);
  }

  Map<String, String> _getHeaders({bool includeAuth = true, String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      String? token;
      if (requiresAuth) {
        token = await _getAuthToken();
        if (token == null) {
          return ApiResponse(
            success: false,
            error: AppConstants.errorUnauthorizedMessage,
            statusCode: 401,
          );
        }
      }

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth, token: token),
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: '${AppConstants.errorNetworkMessage}: $e',
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      String? token;
      if (requiresAuth) {
        token = await _getAuthToken();
        if (token == null) {
          return ApiResponse(
            success: false,
            error: AppConstants.errorUnauthorizedMessage,
            statusCode: 401,
          );
        }
      }

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParameters);

      final response = await http.post(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth, token: token),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: '${AppConstants.errorNetworkMessage}: $e',
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      String? token;
      if (requiresAuth) {
        token = await _getAuthToken();
        if (token == null) {
          return ApiResponse(
            success: false,
            error: AppConstants.errorUnauthorizedMessage,
            statusCode: 401,
          );
        }
      }

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParameters);

      final response = await http.put(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth, token: token),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: '${AppConstants.errorNetworkMessage}: $e',
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      String? token;
      if (requiresAuth) {
        token = await _getAuthToken();
        if (token == null) {
          return ApiResponse(
            success: false,
            error: AppConstants.errorUnauthorizedMessage,
            statusCode: 401,
          );
        }
      }

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParameters);

      final response = await http.delete(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth, token: token),
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: '${AppConstants.errorNetworkMessage}: $e',
      );
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      String? token;
      if (requiresAuth) {
        token = await _getAuthToken();
        if (token == null) {
          return ApiResponse(
            success: false,
            error: AppConstants.errorUnauthorizedMessage,
            statusCode: 401,
          );
        }
      }

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParameters);

      final response = await http.patch(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth, token: token),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: '${AppConstants.errorNetworkMessage}: $e',
      );
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final data =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return ApiResponse(
          success: true,
          data: data as T?,
          statusCode: statusCode,
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear respuesta: $e',
          statusCode: statusCode,
        );
      }
    } else if (statusCode == 401) {
      return ApiResponse(
        success: false,
        error: AppConstants.errorUnauthorizedMessage,
        statusCode: statusCode,
      );
    } else if (statusCode >= 500) {
      return ApiResponse(
        success: false,
        error: AppConstants.errorServerMessage,
        statusCode: statusCode,
      );
    } else {
      String errorMessage = AppConstants.errorUnknownMessage;
      try {
        final errorData = jsonDecode(response.body);
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        // Si no se puede parsear el error, usar el mensaje por defecto
      }
      return ApiResponse(
        success: false,
        error: errorMessage,
        statusCode: statusCode,
      );
    }
  }

  // Método para subir archivos usando multipart/form-data
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath,
    String fileFieldName, {
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
    Function(int, int)? onProgress,
  }) async {
    try {
      String? token;
      if (requiresAuth) {
        token = await _getAuthToken();
        if (token == null) {
          return ApiResponse(
            success: false,
            error: AppConstants.errorUnauthorizedMessage,
            statusCode: 401,
          );
        }
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Agregar headers
      if (requiresAuth && token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Agregar archivo
      request.files.add(await http.MultipartFile.fromPath(
        fileFieldName,
        filePath,
      ));

      // Agregar campos adicionales
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: '${AppConstants.errorNetworkMessage}: $e',
      );
    }
  }
}
