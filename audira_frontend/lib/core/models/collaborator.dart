import 'package:equatable/equatable.dart';

class Collaborator extends Equatable {
  final int id;
  final int songId;
  final int artistId;
  final String role; // feature, producer, etc.
  final DateTime? createdAt;

  const Collaborator({
    required this.id,
    required this.songId,
    required this.artistId,
    required this.role,
    this.createdAt,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      id: json['id'] as int,
      songId: json['songId'] as int,
      artistId: json['artistId'] as int,
      role: json['role'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songId': songId,
      'artistId': artistId,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, songId, artistId, role, createdAt];
}
