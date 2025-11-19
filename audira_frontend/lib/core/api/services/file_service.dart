import '../api_client.dart';

class FileUploadResponse {
  final String message;
  final String fileUrl;
  final String filePath;
  final String fileName;
  final int fileSize;

  FileUploadResponse({
    required this.message,
    required this.fileUrl,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      message: json['message'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
    );
  }
}

class FileCompressionResponse {
  final String message;
  final String zipFileUrl;
  final String zipFilePath;
  final int filesCompressed;
  final int originalSize;
  final int compressedSize;
  final String compressionRatio;

  FileCompressionResponse({
    required this.message,
    required this.zipFileUrl,
    required this.zipFilePath,
    this.filesCompressed = 1,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
  });

  factory FileCompressionResponse.fromJson(Map<String, dynamic> json) {
    return FileCompressionResponse(
      message: json['message'] ?? '',
      zipFileUrl: json['zipFileUrl'] ?? '',
      zipFilePath: json['zipFilePath'] ?? '',
      filesCompressed: json['filesCompressed'] ?? 1,
      originalSize: json['originalSize'] ?? 0,
      compressedSize: json['compressedSize'] ?? 0,
      compressionRatio: json['compressionRatio'] ?? '0%',
    );
  }
}

class FileService {
  final ApiClient _apiClient = ApiClient();

  /// Upload audio file (.mp3, .wav, .flac, .midi)
  Future<ApiResponse<FileUploadResponse>> uploadAudioFile(
    String filePath,{
    int? songId,
    Function(int, int)? onProgress,
  }) async {
    final Map<String, String> additionalFields = {};
    if (songId != null) {
        additionalFields['songId'] = songId.toString();
    }

    final response = await _apiClient.uploadFile(
      '/api/files/upload/audio',
      filePath,
      'file',
      additionalFields: additionalFields.isNotEmpty ? additionalFields : null, // <-- MODIFICADO
      requiresAuth: false,
      onProgress: onProgress,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FileUploadResponse.fromJson(
              response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear respuesta: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Upload image file (.jpg, .png, .webp)
  Future<ApiResponse<FileUploadResponse>> uploadImageFile(
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    final response = await _apiClient.uploadFile(
      '/api/files/upload/image',
      filePath,
      'file',
      requiresAuth: false,
      onProgress: onProgress,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FileUploadResponse.fromJson(
              response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear respuesta: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Upload banner image
  Future<ApiResponse<FileUploadResponse>> uploadBannerImage(
    String filePath,
    int userId, {
    Function(int, int)? onProgress,
  }) async {
    final response = await _apiClient.uploadFile(
      '/api/files/upload/banner-image',
      filePath,
      'file',
      additionalFields: {'userId': userId.toString()},
      requiresAuth: false,
      onProgress: onProgress,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FileUploadResponse.fromJson(
              response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear respuesta: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Compress multiple files
  Future<ApiResponse<FileCompressionResponse>> compressFiles(
    List<String> filePaths,
  ) async {
    final response = await _apiClient.post(
      '/api/files/compress',
      body: {'filePaths': filePaths},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FileCompressionResponse.fromJson(
              response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear respuesta: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Compress single file
  Future<ApiResponse<FileCompressionResponse>> compressSingleFile(
    String filePath,
  ) async {
    final response = await _apiClient.post(
      '/api/files/compress/single',
      body: {'filePath': filePath},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FileCompressionResponse.fromJson(
              response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear respuesta: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get file URL for playback or display
  String getFileUrl(String filePath) {
    return '${_apiClient.baseUrl}/api/files/$filePath';
  }
}
