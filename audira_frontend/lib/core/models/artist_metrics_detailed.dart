import 'package:equatable/equatable.dart';

/// Detailed metrics for an artist with timeline data
/// GA01-109: Vista detallada (por fecha/gráfico básico)
class ArtistMetricsDetailed extends Equatable {
  final int artistId;
  final String artistName;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyMetric> dailyMetrics;
  final int totalPlays;
  final int totalSales;
  final double totalRevenue;
  final int totalComments;
  final double averageRating;

  const ArtistMetricsDetailed({
    required this.artistId,
    required this.artistName,
    required this.startDate,
    required this.endDate,
    required this.dailyMetrics,
    required this.totalPlays,
    required this.totalSales,
    required this.totalRevenue,
    required this.totalComments,
    required this.averageRating,
  });

  factory ArtistMetricsDetailed.fromJson(Map<String, dynamic> json) {
    return ArtistMetricsDetailed(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      dailyMetrics: (json['dailyMetrics'] as List)
          .map((e) => DailyMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPlays: json['totalPlays'] as int,
      totalSales: json['totalSales'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalComments: json['totalComments'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        artistId,
        artistName,
        startDate,
        endDate,
        dailyMetrics,
        totalPlays,
        totalSales,
        totalRevenue,
        totalComments,
        averageRating,
      ];
}

/// Daily metric data point for charts
class DailyMetric extends Equatable {
  final DateTime date;
  final int plays;
  final int sales;
  final double revenue;
  final int comments;
  final double averageRating;

  const DailyMetric({
    required this.date,
    required this.plays,
    required this.sales,
    required this.revenue,
    required this.comments,
    required this.averageRating,
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      date: DateTime.parse(json['date'] as String),
      plays: json['plays'] as int,
      sales: json['sales'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      comments: json['comments'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [date, plays, sales, revenue, comments, averageRating];
}
