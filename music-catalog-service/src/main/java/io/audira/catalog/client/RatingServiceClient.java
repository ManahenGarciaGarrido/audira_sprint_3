package io.audira.catalog.client;

import io.audira.catalog.dto.RatingStatsDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

/**
 * REST client for communication with Community Service (Rating management)
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RatingServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.community.url:http://172.16.0.4:9001}")
    private String communityServiceUrl;

    /**
     * Get rating statistics for an entity
     *
     * @param entityType Type of entity (SONG, ALBUM, ARTIST)
     * @param entityId Entity ID
     * @return RatingStatsDTO with rating statistics
     */
    public RatingStatsDTO getEntityRatingStats(String entityType, Long entityId) {
        String url = String.format(
            "%s/api/ratings/stats/%s/%d",
            communityServiceUrl,
            entityType.toUpperCase(),
            entityId
        );

        try {
            log.debug("Fetching rating stats for {} {} from URL: {}", entityType, entityId, url);
            RatingStatsDTO stats = restTemplate.getForObject(url, RatingStatsDTO.class);

            if (stats == null) {
                log.warn("Received null response from rating service for {} {}", entityType, entityId);
                return createFallbackStats(entityType, entityId);
            }

            log.debug("Rating stats retrieved successfully: {} {} - avg: {}, total: {}",
                    entityType, entityId, stats.getAverageRating(), stats.getTotalRatings());
            return stats;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching rating stats for {} {}. Status: {}",
                    entityType, entityId, e.getStatusCode());
            return createFallbackStats(entityType, entityId);

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing rating service at {} for {} {}",
                    url, entityType, entityId);
            return createFallbackStats(entityType, entityId);

        } catch (Exception e) {
            log.error("Unexpected error fetching rating stats for {} {}", entityType, entityId, e);
            return createFallbackStats(entityType, entityId);
        }
    }

    /**
     * Get rating statistics for multiple songs of an artist
     *
     * @param artistId Artist ID
     * @return Combined rating statistics for all artist's songs
     */
    public RatingStatsDTO getArtistRatingStats(Long artistId) {
        return getEntityRatingStats("ARTIST", artistId);
    }

    /**
     * Create fallback stats when the service is unavailable
     */
    private RatingStatsDTO createFallbackStats(String entityType, Long entityId) {
        return RatingStatsDTO.builder()
                .entityType(entityType.toUpperCase())
                .entityId(entityId)
                .averageRating(0.0)
                .totalRatings(0L)
                .fiveStars(0L)
                .fourStars(0L)
                .threeStars(0L)
                .twoStars(0L)
                .oneStar(0L)
                .build();
    }
}
