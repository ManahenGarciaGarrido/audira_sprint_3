import 'package:equatable/equatable.dart';

/// Collaboration status enum
/// GA01-154: Añadir/aceptar colaboradores
enum CollaborationStatus {
  pending,
  accepted,
  rejected;

  String toJson() => name.toUpperCase();

  static CollaborationStatus fromJson(String json) {
    return CollaborationStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == json.toUpperCase(),
      orElse: () => CollaborationStatus.pending,
    );
  }
}

/// Collaborator model representing collaborations on songs/albums
/// GA01-154: Añadir/aceptar colaboradores - status, invitedBy, albumId
/// GA01-155: Definir porcentaje de ganancias - revenuePercentage
class Collaborator extends Equatable {
  final int id;
  final int? songId;
  final int? albumId; // GA01-154: Support album collaborations
  final int artistId;
  final String role; // feature, producer, composer, etc.
  final CollaborationStatus status; // GA01-154: Invitation status
  final int invitedBy; // GA01-154: User who created the invitation
  final double revenuePercentage; // GA01-155: Percentage of revenue (0-100)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Collaborator({
    required this.id,
    this.songId,
    this.albumId,
    required this.artistId,
    required this.role,
    required this.status,
    required this.invitedBy,
    required this.revenuePercentage,
    this.createdAt,
    this.updatedAt,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      id: json['id'] as int,
      songId: json['songId'] as int?,
      albumId: json['albumId'] as int?,
      artistId: json['artistId'] as int,
      role: json['role'] as String,
      status: json['status'] != null
          ? CollaborationStatus.fromJson(json['status'] as String)
          : CollaborationStatus.pending,
      invitedBy: json['invitedBy'] as int,
      revenuePercentage: (json['revenuePercentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (songId != null) 'songId': songId,
      if (albumId != null) 'albumId': albumId,
      'artistId': artistId,
      'role': role,
      'status': status.toJson(),
      'invitedBy': invitedBy,
      'revenuePercentage': revenuePercentage,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Check if collaboration is for a song
  bool get isForSong => songId != null;

  /// Check if collaboration is for an album
  bool get isForAlbum => albumId != null;

  /// Get the entity ID (song or album)
  int? get entityId => songId ?? albumId;

  /// Get the entity type
  String get entityType => songId != null ? 'SONG' : 'ALBUM';

  /// Check if collaboration is pending
  bool get isPending => status == CollaborationStatus.pending;

  /// Check if collaboration is accepted
  bool get isAccepted => status == CollaborationStatus.accepted;

  /// Check if collaboration is rejected
  bool get isRejected => status == CollaborationStatus.rejected;

  Collaborator copyWith({
    int? id,
    int? songId,
    int? albumId,
    int? artistId,
    String? role,
    CollaborationStatus? status,
    int? invitedBy,
    double? revenuePercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Collaborator(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      revenuePercentage: revenuePercentage ?? this.revenuePercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        songId,
        albumId,
        artistId,
        role,
        status,
        invitedBy,
        revenuePercentage,
        createdAt,
        updatedAt,
      ];
}
