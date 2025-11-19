import '../api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CompressionService {
  final String baseUrl;

  CompressionService(this.baseUrl);

  Future<ApiResponse<Map<String, dynamic>>> compressMultipleFiles(
      List<String> filePaths) async {
    try {
      final uri = Uri.parse('$baseUrl/api/files/compress');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'filePaths': filePaths,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: Map<String, dynamic>.from(data),
          statusCode: 200,
        );
      }

      return ApiResponse(
        success: false,
        error: 'Error al comprimir archivos',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Excepción: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> compressSingleFile(
      String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/api/files/compress/single');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'filePath': filePath,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: Map<String, dynamic>.from(data),
          statusCode: 200,
        );
      }

      return ApiResponse(
        success: false,
        error: 'Error al comprimir archivo',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Excepción: $e',
      );
    }
  }
}
