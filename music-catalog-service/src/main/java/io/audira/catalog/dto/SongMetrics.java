package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Metrics for a specific song
 * Used in both GA01-108 and GA01-109
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SongMetrics {

    private Long songId;
    private String songName;
    private String artistName;

    // Performance metrics
    private Long totalPlays;
    private Double averageRating;
    private Long totalRatings;
    private Long totalComments;

    // Sales metrics
    private Long totalSales;
    private Double totalRevenue;

    // Ranking
    private Integer rankInArtistCatalog; // Position among artist's songs
}
