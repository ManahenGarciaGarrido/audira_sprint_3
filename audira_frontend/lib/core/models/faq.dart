import 'package:equatable/equatable.dart';

class FAQ extends Equatable {
  final int id;
  final String question;
  final String answer;
  final String category;
  final int displayOrder;
  final bool isActive;
  final int viewCount;
  final int helpfulCount;
  final int notHelpfulCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.displayOrder = 0,
    this.isActive = true,
    this.viewCount = 0,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      viewCount: json['viewCount'] as int? ?? 0,
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      notHelpfulCount: json['notHelpfulCount'] as int? ?? 0,
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
      'question': question,
      'answer': answer,
      'category': category,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'viewCount': viewCount,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        question,
        answer,
        category,
        displayOrder,
        isActive,
        viewCount,
        helpfulCount,
        notHelpfulCount,
        createdAt,
        updatedAt,
      ];
}
