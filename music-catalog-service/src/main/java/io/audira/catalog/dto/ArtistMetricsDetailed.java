package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Detailed metrics for an artist with timeline data
 * GA01-109: Vista detallada (por fecha/gráfico básico)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArtistMetricsDetailed {

    // Basic info
    private Long artistId;
    private String artistName;
    private LocalDate startDate;
    private LocalDate endDate;

    // Timeline data (for charts)
    private List<DailyMetric> dailyMetrics;

    // Summary for the period
    private Long totalPlays;
    private Long totalSales;
    private BigDecimal totalRevenue;
    private Long totalComments;
    private Double averageRating;

    /**
     * Daily metric data point for charts
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyMetric {
        private LocalDate date;
        private Long plays;
        private Long sales;
        private BigDecimal revenue;
        private Long comments;
        private Double averageRating; // Average for that day
    }
}
