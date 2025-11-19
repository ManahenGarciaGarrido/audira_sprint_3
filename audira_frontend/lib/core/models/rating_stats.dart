import 'package:equatable/equatable.dart';

/// Modelo para estadísticas de valoraciones
class RatingStats extends Equatable {
  final String entityType;
  final int entityId;
  final double averageRating;
  final int totalRatings;
  final int fiveStars;
  final int fourStars;
  final int threeStars;
  final int twoStars;
  final int oneStar;

  const RatingStats({
    required this.entityType,
    required this.entityId,
    required this.averageRating,
    required this.totalRatings,
    this.fiveStars = 0,
    this.fourStars = 0,
    this.threeStars = 0,
    this.twoStars = 0,
    this.oneStar = 0,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as int,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] as int? ?? 0,
      fiveStars: json['fiveStars'] as int? ?? 0,
      fourStars: json['fourStars'] as int? ?? 0,
      threeStars: json['threeStars'] as int? ?? 0,
      twoStars: json['twoStars'] as int? ?? 0,
      oneStar: json['oneStar'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'fiveStars': fiveStars,
      'fourStars': fourStars,
      'threeStars': threeStars,
      'twoStars': twoStars,
      'oneStar': oneStar,
    };
  }

  @override
  List<Object?> get props => [
        entityType,
        entityId,
        averageRating,
        totalRatings,
        fiveStars,
        fourStars,
        threeStars,
        twoStars,
        oneStar,
      ];
}
