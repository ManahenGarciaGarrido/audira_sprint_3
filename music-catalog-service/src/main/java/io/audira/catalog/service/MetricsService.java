package io.audira.catalog.service;

import io.audira.catalog.dto.ArtistMetricsDetailed;
import io.audira.catalog.dto.ArtistMetricsSummary;
import io.audira.catalog.dto.SongMetrics;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.Collaborator;
import io.audira.catalog.model.CollaborationStatus;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.CollaboratorRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for calculating artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 * GA01-109: Vista detallada (por fecha/gráfico básico)
 */
@Service
@RequiredArgsConstructor
public class MetricsService {

    private static final Logger logger = LoggerFactory.getLogger(MetricsService.class);

    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final CollaboratorRepository collaboratorRepository;

    // TODO: Inject these services when implementing full integration
    // private final RatingService ratingService; // From community-service
    // private final OrderService orderService; // From commerce-service
    // private final CommentService commentService; // From community-service

    /**
     * Get summary metrics for an artist
     * GA01-108: Resumen rápido
     */
    public ArtistMetricsSummary getArtistMetricsSummary(Long artistId) {
        logger.info("Calculating metrics summary for artist {}", artistId);

        // Get artist's songs
        List<Song> artistSongs = songRepository.findByArtistId(artistId);

        // Get artist's albums
        List<Album> artistAlbums = albumRepository.findByArtistId(artistId);

        // Get collaborations
        List<Collaborator> collaborations = collaboratorRepository.findByArtistIdAndStatus(
                artistId, CollaborationStatus.ACCEPTED
        );

        // Calculate plays metrics
        Long totalPlays = artistSongs.stream()
                .mapToLong(Song::getPlays)
                .sum();

        // Find most played song
        Optional<Song> mostPlayedSong = artistSongs.stream()
                .max(Comparator.comparing(Song::getPlays));

        // Calculate growth (mock data - in real implementation, query historical data)
        // TODO: Implement historical tracking for accurate growth calculations
        Double playsGrowth = calculateMockGrowth(totalPlays);

        // TODO: Integrate with community-service for real ratings data
        Double averageRating = 4.2; // Mock data
        Long totalRatings = (long) (artistSongs.size() * 15); // Mock data
        Double ratingsGrowth = 5.3; // Mock data

        // TODO: Integrate with commerce-service for real sales data
        Long totalSales = totalPlays / 10; // Mock: 10% conversion
        BigDecimal totalRevenue = BigDecimal.valueOf(totalSales * 0.99); // Mock: $0.99 per sale
        Long salesLast30Days = totalSales / 12; // Mock
        BigDecimal revenueLast30Days = totalRevenue.divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_UP);
        Double salesGrowth = 8.7; // Mock data
        Double revenueGrowth = 8.7; // Mock data

        // TODO: Integrate with community-service for real comments data
        Long totalComments = (long) (artistSongs.size() * 8); // Mock data
        Long commentsLast30Days = totalComments / 6; // Mock
        Double commentsGrowth = 12.4; // Mock data

        return ArtistMetricsSummary.builder()
                .artistId(artistId)
                .artistName("Artist #" + artistId) // TODO: Get from user service
                .generatedAt(LocalDateTime.now())
                // Plays
                .totalPlays(totalPlays)
                .playsLast30Days(totalPlays / 4) // Mock: 25% in last 30 days
                .playsGrowthPercentage(playsGrowth)
                // Ratings
                .averageRating(averageRating)
                .totalRatings(totalRatings)
                .ratingsGrowthPercentage(ratingsGrowth)
                // Sales
                .totalSales(totalSales)
                .totalRevenue(totalRevenue)
                .salesLast30Days(salesLast30Days)
                .revenueLast30Days(revenueLast30Days)
                .salesGrowthPercentage(salesGrowth)
                .revenueGrowthPercentage(revenueGrowth)
                // Comments
                .totalComments(totalComments)
                .commentsLast30Days(commentsLast30Days)
                .commentsGrowthPercentage(commentsGrowth)
                // Content
                .totalSongs((long) artistSongs.size())
                .totalAlbums((long) artistAlbums.size())
                .totalCollaborations((long) collaborations.size())
                // Top performing
                .mostPlayedSongId(mostPlayedSong.map(Song::getId).orElse(null))
                .mostPlayedSongName(mostPlayedSong.map(Song::getTitle).orElse("N/A"))
                .mostPlayedSongPlays(mostPlayedSong.map(Song::getPlays).orElse(0L))
                .build();
    }

    /**
     * Get detailed metrics with timeline for an artist
     * GA01-109: Vista detallada
     */
    public ArtistMetricsDetailed getArtistMetricsDetailed(
            Long artistId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        logger.info("Calculating detailed metrics for artist {} from {} to {}",
                artistId, startDate, endDate);

        // Validate date range
        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        // Get artist's songs
        List<Song> artistSongs = songRepository.findByArtistId(artistId);
        Long totalPlays = artistSongs.stream().mapToLong(Song::getPlays).sum();

        // Generate daily metrics for chart
        // TODO: In real implementation, query actual historical data from a metrics table
        List<ArtistMetricsDetailed.DailyMetric> dailyMetrics = generateDailyMetrics(
                startDate, endDate, totalPlays
        );

        // Calculate period totals
        Long periodPlays = dailyMetrics.stream()
                .mapToLong(ArtistMetricsDetailed.DailyMetric::getPlays)
                .sum();

        Long periodSales = dailyMetrics.stream()
                .mapToLong(ArtistMetricsDetailed.DailyMetric::getSales)
                .sum();

        BigDecimal periodRevenue = dailyMetrics.stream()
                .map(ArtistMetricsDetailed.DailyMetric::getRevenue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Long periodComments = dailyMetrics.stream()
                .mapToLong(ArtistMetricsDetailed.DailyMetric::getComments)
                .sum();

        Double averageRating = dailyMetrics.stream()
                .mapToDouble(m -> m.getAverageRating() != null ? m.getAverageRating() : 0.0)
                .filter(r -> r > 0)
                .average()
                .orElse(0.0);

        return ArtistMetricsDetailed.builder()
                .artistId(artistId)
                .artistName("Artist #" + artistId) // TODO: Get from user service
                .startDate(startDate)
                .endDate(endDate)
                .dailyMetrics(dailyMetrics)
                .totalPlays(periodPlays)
                .totalSales(periodSales)
                .totalRevenue(periodRevenue)
                .totalComments(periodComments)
                .averageRating(averageRating)
                .build();
    }

    /**
     * Get metrics for a specific song
     */
    public SongMetrics getSongMetrics(Long songId) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new RuntimeException("Song not found: " + songId));

        // Get artist's all songs to calculate rank
        List<Song> artistSongs = songRepository.findByArtistId(song.getArtistId());
        List<Song> sortedByPlays = artistSongs.stream()
                .sorted(Comparator.comparing(Song::getPlays).reversed())
                .collect(Collectors.toList());

        int rank = sortedByPlays.indexOf(song) + 1;

        // TODO: Integrate with other services for real data
        Long mockSales = song.getPlays() / 10;
        Double mockRevenue = mockSales * 0.99;

        return SongMetrics.builder()
                .songId(song.getId())
                .songName(song.getTitle())
                .artistName("Artist #" + song.getArtistId())
                .totalPlays(song.getPlays())
                .averageRating(4.1) // Mock
                .totalRatings(45L) // Mock
                .totalComments(12L) // Mock
                .totalSales(mockSales)
                .totalRevenue(mockRevenue)
                .rankInArtistCatalog(rank)
                .build();
    }

    /**
     * Generate mock daily metrics for demonstration
     * TODO: Replace with real historical data from a metrics tracking table
     */
    private List<ArtistMetricsDetailed.DailyMetric> generateDailyMetrics(
            LocalDate startDate,
            LocalDate endDate,
            Long totalPlays
    ) {
        List<ArtistMetricsDetailed.DailyMetric> metrics = new ArrayList<>();
        LocalDate currentDate = startDate;
        long daysInRange = endDate.toEpochDay() - startDate.toEpochDay() + 1;

        // Distribute total plays across days with some variation
        Random random = new Random(42); // Fixed seed for consistent mock data

        while (!currentDate.isAfter(endDate)) {
            // Generate mock data with some randomness
            long dailyPlays = (totalPlays / daysInRange) + random.nextInt(100);
            long dailySales = dailyPlays / 10;
            BigDecimal dailyRevenue = BigDecimal.valueOf(dailySales * 0.99)
                    .setScale(2, RoundingMode.HALF_UP);
            long dailyComments = random.nextInt(5);
            double dailyRating = 3.5 + random.nextDouble() * 1.5; // 3.5 to 5.0

            metrics.add(ArtistMetricsDetailed.DailyMetric.builder()
                    .date(currentDate)
                    .plays(dailyPlays)
                    .sales(dailySales)
                    .revenue(dailyRevenue)
                    .comments(dailyComments)
                    .averageRating(Math.round(dailyRating * 10.0) / 10.0)
                    .build());

            currentDate = currentDate.plusDays(1);
        }

        return metrics;
    }

    /**
     * Calculate mock growth percentage
     * TODO: Replace with real calculation from historical data
     */
    private Double calculateMockGrowth(Long currentValue) {
        if (currentValue == 0) return 0.0;
        // Mock: growth between 0% and 20%
        Random random = new Random(currentValue);
        return random.nextDouble() * 20.0;
    }
}
