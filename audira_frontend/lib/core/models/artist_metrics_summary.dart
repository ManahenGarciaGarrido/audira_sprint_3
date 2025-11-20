import 'package:equatable/equatable.dart';

/// Summary metrics for an artist
/// GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
class ArtistMetricsSummary extends Equatable {
  final int artistId;
  final String artistName;
  final DateTime generatedAt;

  // Plays metrics
  final int totalPlays;
  final int playsLast30Days;
  final double playsGrowthPercentage;

  // Rating metrics
  final double averageRating;
  final int totalRatings;
  final double ratingsGrowthPercentage;

  // Sales metrics
  final int totalSales;
  final double totalRevenue;
  final int salesLast30Days;
  final double revenueLast30Days;
  final double salesGrowthPercentage;
  final double revenueGrowthPercentage;

  // Comments metrics
  final int totalComments;
  final int commentsLast30Days;
  final double commentsGrowthPercentage;

  // Content metrics
  final int totalSongs;
  final int totalAlbums;
  final int totalCollaborations;

  // Top performing
  final int? mostPlayedSongId;
  final String? mostPlayedSongName;
  final int? mostPlayedSongPlays;

  const ArtistMetricsSummary({
    required this.artistId,
    required this.artistName,
    required this.generatedAt,
    required this.totalPlays,
    required this.playsLast30Days,
    required this.playsGrowthPercentage,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingsGrowthPercentage,
    required this.totalSales,
    required this.totalRevenue,
    required this.salesLast30Days,
    required this.revenueLast30Days,
    required this.salesGrowthPercentage,
    required this.revenueGrowthPercentage,
    required this.totalComments,
    required this.commentsLast30Days,
    required this.commentsGrowthPercentage,
    required this.totalSongs,
    required this.totalAlbums,
    required this.totalCollaborations,
    this.mostPlayedSongId,
    this.mostPlayedSongName,
    this.mostPlayedSongPlays,
  });

  factory ArtistMetricsSummary.fromJson(Map<String, dynamic> json) {
    return ArtistMetricsSummary(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      totalPlays: json['totalPlays'] as int,
      playsLast30Days: json['playsLast30Days'] as int,
      playsGrowthPercentage: (json['playsGrowthPercentage'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
      totalRatings: json['totalRatings'] as int,
      ratingsGrowthPercentage: (json['ratingsGrowthPercentage'] as num).toDouble(),
      totalSales: json['totalSales'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      salesLast30Days: json['salesLast30Days'] as int,
      revenueLast30Days: (json['revenueLast30Days'] as num).toDouble(),
      salesGrowthPercentage: (json['salesGrowthPercentage'] as num).toDouble(),
      revenueGrowthPercentage: (json['revenueGrowthPercentage'] as num).toDouble(),
      totalComments: json['totalComments'] as int,
      commentsLast30Days: json['commentsLast30Days'] as int,
      commentsGrowthPercentage: (json['commentsGrowthPercentage'] as num).toDouble(),
      totalSongs: json['totalSongs'] as int,
      totalAlbums: json['totalAlbums'] as int,
      totalCollaborations: json['totalCollaborations'] as int,
      mostPlayedSongId: json['mostPlayedSongId'] as int?,
      mostPlayedSongName: json['mostPlayedSongName'] as String?,
      mostPlayedSongPlays: json['mostPlayedSongPlays'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        artistId,
        artistName,
        generatedAt,
        totalPlays,
        playsLast30Days,
        playsGrowthPercentage,
        averageRating,
        totalRatings,
        ratingsGrowthPercentage,
        totalSales,
        totalRevenue,
        salesLast30Days,
        revenueLast30Days,
        salesGrowthPercentage,
        revenueGrowthPercentage,
        totalComments,
        commentsLast30Days,
        commentsGrowthPercentage,
        totalSongs,
        totalAlbums,
        totalCollaborations,
        mostPlayedSongId,
        mostPlayedSongName,
        mostPlayedSongPlays,
      ];
}
