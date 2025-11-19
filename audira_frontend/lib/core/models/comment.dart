import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final int id;
  final int userId;
  final String entityType;
  final int entityId;
  final String content;
  final int? parentCommentId;
  final int likesCount;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.content,
    this.parentCommentId,
    this.likesCount = 0,
    this.isEdited = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as int,
      content: json['content'] as String,
      parentCommentId: json['parentCommentId'] as int?,
      likesCount: json['likesCount'] as int? ?? 0,
      isEdited: json['isEdited'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      'likesCount': likesCount,
      'isEdited': isEdited,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Comment copyWith({
    int? id,
    int? userId,
    String? entityType,
    int? entityId,
    String? content,
    int? parentCommentId,
    int? likesCount,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likesCount: likesCount ?? this.likesCount,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        entityType,
        entityId,
        content,
        parentCommentId,
        likesCount,
        isEdited,
        createdAt,
        updatedAt,
      ];
}
