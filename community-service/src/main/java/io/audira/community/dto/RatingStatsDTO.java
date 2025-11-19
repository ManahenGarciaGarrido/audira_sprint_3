package io.audira.community.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para estadísticas de valoraciones
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RatingStatsDTO {

    private String entityType;
    private Long entityId;

    /**
     * Promedio de valoraciones (1-5)
     */
    private Double averageRating;

    /**
     * Número total de valoraciones
     */
    private Long totalRatings;

    /**
     * Distribución de estrellas
     */
    private Long fiveStars;
    private Long fourStars;
    private Long threeStars;
    private Long twoStars;
    private Long oneStar;

    /**
     * Constructor simplificado
     */
    public RatingStatsDTO(String entityType, Long entityId, Double averageRating, Long totalRatings) {
        this.entityType = entityType;
        this.entityId = entityId;
        this.averageRating = averageRating != null ? Math.round(averageRating * 100.0) / 100.0 : 0.0;
        this.totalRatings = totalRatings != null ? totalRatings : 0L;
    }
}
