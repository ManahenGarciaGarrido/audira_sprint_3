import 'package:audira_frontend/core/api/api_client.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Send a contact message
  Future<ApiResponse<Map<String, dynamic>>> sendContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
    int? userId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/contact',
        body: {
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
          if (userId != null) 'userId': userId,
        },
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
        error: response.error ?? 'Failed to send contact message',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get all contact messages (admin only)
  Future<ApiResponse<List<dynamic>>> getAllContactMessages() async {
    try {
      final response = await _apiClient.get('/api/contact');

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: response.data as List<dynamic>,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch contact messages',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get contact message by ID (admin only)
  Future<ApiResponse<Map<String, dynamic>>> getContactMessage(int id) async {
    try {
      final response = await _apiClient.get('/api/contact/$id');

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch contact message',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Mark contact message as read (admin only)
  Future<ApiResponse<void>> markAsRead(int id) async {
    try {
      final response = await _apiClient.patch('/api/contact/$id/read');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to mark message as read',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Delete contact message (admin only)
  Future<ApiResponse<void>> deleteContactMessage(int id) async {
    try {
      final response = await _apiClient.delete('/api/contact/$id');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to delete contact message',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
}
