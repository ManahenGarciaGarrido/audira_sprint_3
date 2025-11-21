package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for rating statistics from community-service
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RatingStatsDTO {
    private String entityType;
    private Long entityId;
    private Double averageRating;
    private Long totalRatings;
    private Long fiveStars;
    private Long fourStars;
    private Long threeStars;
    private Long twoStars;
    private Long oneStar;
}
