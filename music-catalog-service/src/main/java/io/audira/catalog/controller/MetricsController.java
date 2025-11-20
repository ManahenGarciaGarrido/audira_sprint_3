package io.audira.catalog.controller;

import io.audira.catalog.dto.ArtistMetricsDetailed;
import io.audira.catalog.dto.ArtistMetricsSummary;
import io.audira.catalog.dto.SongMetrics;
import io.audira.catalog.service.MetricsService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Controller for artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 * GA01-109: Vista detallada (por fecha/gráfico básico)
 */
@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class MetricsController {

    private final MetricsService metricsService;

    /**
     * Get summary metrics for an artist
     * GA01-108: Resumen rápido
     *
     * @param artistId Artist ID
     * @return Summary with plays, ratings, sales, comments, and growth
     */
    @GetMapping("/artists/{artistId}")
    public ResponseEntity<ArtistMetricsSummary> getArtistMetricsSummary(
            @PathVariable Long artistId
    ) {
        ArtistMetricsSummary metrics = metricsService.getArtistMetricsSummary(artistId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Get detailed metrics with timeline for an artist
     * GA01-109: Vista detallada (por fecha/gráfico básico)
     *
     * @param artistId Artist ID
     * @param startDate Start date (optional, defaults to 30 days ago)
     * @param endDate End date (optional, defaults to today)
     * @return Detailed metrics with daily breakdown for charts
     */
    @GetMapping("/artists/{artistId}/detailed")
    public ResponseEntity<ArtistMetricsDetailed> getArtistMetricsDetailed(
            @PathVariable Long artistId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        // Default to last 30 days if not specified
        if (startDate == null) {
            startDate = LocalDate.now().minusDays(30);
        }
        if (endDate == null) {
            endDate = LocalDate.now();
        }

        ArtistMetricsDetailed metrics = metricsService.getArtistMetricsDetailed(
                artistId, startDate, endDate
        );
        return ResponseEntity.ok(metrics);
    }

    /**
     * Get metrics for a specific song
     *
     * @param songId Song ID
     * @return Song metrics
     */
    @GetMapping("/songs/{songId}")
    public ResponseEntity<SongMetrics> getSongMetrics(
            @PathVariable Long songId
    ) {
        SongMetrics metrics = metricsService.getSongMetrics(songId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Get top songs for an artist (for compatibility with existing frontend)
     * GA01-108: Part of summary
     *
     * @param artistId Artist ID
     * @param limit Number of top songs to return
     * @return List of top songs by plays
     */
    @GetMapping("/artists/{artistId}/top-songs")
    public ResponseEntity<?> getArtistTopSongs(
            @PathVariable Long artistId,
            @RequestParam(defaultValue = "10") int limit
    ) {
        // TODO: Implement properly
        // For now, return empty to maintain compatibility
        return ResponseEntity.ok(new java.util.ArrayList<>());
    }
}
