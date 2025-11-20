import '../api_client.dart';
import '../../../config/constants.dart';
import '../../models/collaborator.dart';

/// Service for managing collaborations
/// GA01-154: Añadir/aceptar colaboradores
/// GA01-155: Definir porcentaje de ganancias
class CollaborationService {
  final ApiClient _apiClient = ApiClient();

  /// Get all collaborations for an artist
  /// GA01-154: View all collaborations
  Future<ApiResponse<List<Collaborator>>> getArtistCollaborations(
      int artistId) async {
    final response = await _apiClient.get(
      '${AppConstants.collaborationsUrl}/artist/$artistId',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      final collaborations = (response.data as List)
          .map((json) => Collaborator.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: collaborations);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get pending invitations for an artist
  /// GA01-154: View pending invitations
  Future<ApiResponse<List<Collaborator>>> getPendingInvitations(
      int artistId) async {
    final response = await _apiClient.get(
      '${AppConstants.collaborationsUrl}/artist/$artistId/pending',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      final invitations = (response.data as List)
          .map((json) => Collaborator.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: invitations);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get collaborations for a specific song
  /// GA01-154: View song collaborations
  Future<ApiResponse<List<Collaborator>>> getSongCollaborations(
      int songId) async {
    final response = await _apiClient.get(
      '${AppConstants.collaborationsUrl}/song/$songId',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      final collaborations = (response.data as List)
          .map((json) => Collaborator.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: collaborations);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get collaborations for a specific album
  /// GA01-154: View album collaborations
  Future<ApiResponse<List<Collaborator>>> getAlbumCollaborations(
      int albumId) async {
    final response = await _apiClient.get(
      '${AppConstants.collaborationsUrl}/album/$albumId',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      final collaborations = (response.data as List)
          .map((json) => Collaborator.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: collaborations);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Invite an artist to collaborate on a song
  /// GA01-154: Añadir colaboradores
  Future<ApiResponse<Collaborator>> inviteCollaboratorToSong({
    required int songId,
    required int artistId,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '${AppConstants.collaborationsUrl}/invite',
      body: {
        'songId': songId,
        'artistId': artistId,
        'role': role,
      },
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: Collaborator.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Invite an artist to collaborate on an album
  /// GA01-154: Añadir colaboradores
  Future<ApiResponse<Collaborator>> inviteCollaboratorToAlbum({
    required int albumId,
    required int artistId,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '${AppConstants.collaborationsUrl}/invite',
      body: {
        'albumId': albumId,
        'artistId': artistId,
        'role': role,
      },
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: Collaborator.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Accept a collaboration invitation
  /// GA01-154: Aceptar colaboradores
  Future<ApiResponse<Collaborator>> acceptInvitation(int collaborationId) async {
    final response = await _apiClient.post(
      '${AppConstants.collaborationsUrl}/$collaborationId/accept',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: Collaborator.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Reject a collaboration invitation
  /// GA01-154: Rechazar colaboradores
  Future<ApiResponse<Collaborator>> rejectInvitation(int collaborationId) async {
    final response = await _apiClient.post(
      '${AppConstants.collaborationsUrl}/$collaborationId/reject',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: Collaborator.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Update revenue percentage for a collaboration
  /// GA01-155: Definir porcentaje de ganancias
  Future<ApiResponse<Collaborator>> updateRevenuePercentage({
    required int collaborationId,
    required double percentage,
  }) async {
    final response = await _apiClient.put(
      '${AppConstants.collaborationsUrl}/$collaborationId/revenue',
      body: {
        'revenuePercentage': percentage,
      },
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: Collaborator.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get total revenue percentage for a song
  /// GA01-155: View total revenue distribution
  Future<ApiResponse<double>> getSongTotalRevenue(int songId) async {
    final response = await _apiClient.get(
      '${AppConstants.collaborationsUrl}/song/$songId/total-revenue',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      final percentage = (response.data as num).toDouble();
      return ApiResponse(success: true, data: percentage);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get total revenue percentage for an album
  /// GA01-155: View total revenue distribution
  Future<ApiResponse<double>> getAlbumTotalRevenue(int albumId) async {
    final response = await _apiClient.get(
      '${AppConstants.collaborationsUrl}/album/$albumId/total-revenue',
      requiresAuth: true,
    );
    if (response.success && response.data != null) {
      final percentage = (response.data as num).toDouble();
      return ApiResponse(success: true, data: percentage);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Delete a collaboration
  /// GA01-154: Remove collaborator
  Future<ApiResponse<void>> deleteCollaboration(int collaborationId) async {
    return await _apiClient.delete(
      '${AppConstants.collaborationsUrl}/$collaborationId',
      requiresAuth: true,
    );
  }
}
