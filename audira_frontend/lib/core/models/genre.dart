import 'package:equatable/equatable.dart';

class Genre extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? color;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Genre({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.color,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
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
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'color': color,
      'icon': icon,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Genre copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        color,
        icon,
        createdAt,
        updatedAt,
      ];
}
