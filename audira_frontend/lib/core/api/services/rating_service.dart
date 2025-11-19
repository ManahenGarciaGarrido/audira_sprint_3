import 'package:audira_frontend/core/api/api_client.dart';
import 'package:audira_frontend/core/models/rating.dart';
import 'package:audira_frontend/core/models/rating_stats.dart';
import 'package:audira_frontend/core/models/create_rating_request.dart';

/// Servicio para gestión de valoraciones
/// GA01-128: Puntuación de 1-5 estrellas
/// GA01-129: Comentario opcional (500 chars)
/// GA01-130: Editar/eliminar valoración
class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final ApiClient _apiClient = ApiClient();

  /// GA01-128, GA01-129: Crear o actualizar valoración
  Future<ApiResponse<Rating>> createRating({
    required String entityType,
    required int entityId,
    required int rating,
    String? comment,
  }) async {
    try {
      final request = CreateRatingRequest(
        entityType: entityType,
        entityId: entityId,
        rating: rating,
        comment: comment,
      );

      if (!request.isValid()) {
        return ApiResponse(
          success: false,
          error: 'Rating must be between 1-5 and comment max 500 chars',
        );
      }

      final response = await _apiClient.post(
        '/api/ratings',
        body: request.toJson(),
      );

      if (response.success && response.data != null) {
        final ratingObj = Rating.fromJson(response.data);
        return ApiResponse(
          success: true,
          data: ratingObj,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to create rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// GA01-130: Actualizar valoración existente
  Future<ApiResponse<Rating>> updateRating({
    required int ratingId,
    int? rating,
    String? comment,
  }) async {
    try {
      final request = UpdateRatingRequest(
        rating: rating,
        comment: comment,
      );

      if (!request.isValid()) {
        return ApiResponse(
          success: false,
          error: 'Rating must be between 1-5 and comment max 500 chars',
        );
      }

      final response = await _apiClient.put(
        '/api/ratings/$ratingId',
        body: request.toJson(),
      );

      if (response.success && response.data != null) {
        final ratingObj = Rating.fromJson(response.data);
        return ApiResponse(
          success: true,
          data: ratingObj,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to update rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get user's ratings
  Future<ApiResponse<List<Rating>>> getUserRatings(int userId) async {
    try {
      final response = await _apiClient.get('/api/ratings/user/$userId');

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final ratings = data.map((json) => Rating.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch user ratings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get ratings for an entity (song/album/artist)
  /// No requiere autenticación para permitir que invitados vean valoraciones
  Future<ApiResponse<List<Rating>>> getEntityRatings({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/entity/$entityType/$entityId',
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final ratings = data.map((json) => Rating.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch entity ratings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Obtener mis valoraciones
  Future<ApiResponse<List<Rating>>> getMyRatings() async {
    try {
      final response = await _apiClient.get('/api/ratings/my-ratings');

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final ratings = data.map((json) => Rating.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch my ratings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Obtener valoraciones con comentarios de una entidad
  /// No requiere autenticación para permitir que invitados vean valoraciones
  Future<ApiResponse<List<Rating>>> getEntityRatingsWithComments({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/entity/$entityType/$entityId/with-comments',
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final ratings = data.map((json) => Rating.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch entity ratings with comments',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Obtener estadísticas de valoraciones de una entidad
  /// No requiere autenticación para permitir que invitados vean estadísticas
  Future<ApiResponse<RatingStats>> getEntityRatingStats({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/entity/$entityType/$entityId/stats',
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final stats = RatingStats.fromJson(response.data);
        return ApiResponse(
          success: true,
          data: stats,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch rating stats',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Obtener mi valoración para una entidad específica
  Future<ApiResponse<Rating?>> getMyEntityRating({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/my-rating/entity/$entityType/$entityId',
      );

      if (response.success) {
        if (response.data != null) {
          final rating = Rating.fromJson(response.data);
          return ApiResponse(
            success: true,
            data: rating,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: true,
            data: null,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch my entity rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Verificar si he valorado una entidad
  Future<ApiResponse<bool>> hasRatedEntity({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/has-rated/entity/$entityType/$entityId',
      );

      if (response.success && response.data != null) {
        final hasRated = response.data['hasRated'] as bool? ?? false;
        return ApiResponse(
          success: true,
          data: hasRated,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to check if rated',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get specific user rating for an entity
  Future<ApiResponse<Rating?>> getUserEntityRating({
    required int userId,
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/user/$userId/entity/$entityType/$entityId',
      );

      if (response.success) {
        if (response.data != null) {
          final rating = Rating.fromJson(response.data);
          return ApiResponse(
            success: true,
            data: rating,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: true,
            data: null,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch user rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// GA01-130: Eliminar valoración
  Future<ApiResponse<void>> deleteRating(int ratingId) async {
    try {
      final response = await _apiClient.delete('/api/ratings/$ratingId');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to delete rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
}
