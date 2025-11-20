package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Summary metrics for an artist
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArtistMetricsSummary {

    // Basic info
    private Long artistId;
    private String artistName;
    private LocalDateTime generatedAt;

    // Plays metrics
    private Long totalPlays;
    private Long playsLast30Days;
    private Double playsGrowthPercentage; // Comparison with previous period

    // Rating metrics
    private Double averageRating;
    private Long totalRatings;
    private Double ratingsGrowthPercentage;

    // Sales metrics
    private Long totalSales;
    private BigDecimal totalRevenue;
    private Long salesLast30Days;
    private BigDecimal revenueLast30Days;
    private Double salesGrowthPercentage;
    private Double revenueGrowthPercentage;

    // Comments metrics
    private Long totalComments;
    private Long commentsLast30Days;
    private Double commentsGrowthPercentage;

    // Content metrics
    private Long totalSongs;
    private Long totalAlbums;
    private Long totalCollaborations;

    // Top performing
    private Long mostPlayedSongId;
    private String mostPlayedSongName;
    private Long mostPlayedSongPlays;
}
