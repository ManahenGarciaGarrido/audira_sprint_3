import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final bool isPublic;
  final List<int> songIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Playlist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.isPublic = false,
    this.songIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get songCount => songIds.length;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      userId: json['userId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      songIds: (json['songIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
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
      'userId': userId,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'isPublic': isPublic,
      'songIds': songIds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Playlist copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? coverImageUrl,
    bool? isPublic,
    List<int>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPublic: isPublic ?? this.isPublic,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        coverImageUrl,
        isPublic,
        songIds,
        createdAt,
        updatedAt,
      ];
}
