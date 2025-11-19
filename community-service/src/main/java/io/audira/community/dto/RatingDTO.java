package io.audira.community.dto;

import io.audira.community.model.Rating;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO para respuesta de valoración
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RatingDTO {

    private Long id;
    private Long userId;
    private String entityType;
    private Long entityId;
    private Integer rating;
    private String comment;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Boolean isActive;

    /**
     * Información adicional del usuario (opcional)
     */
    private String userName;
    private String userProfileImageUrl;

    /**
     * Constructor desde entidad Rating
     */
    public RatingDTO(Rating rating) {
        this.id = rating.getId();
        this.userId = rating.getUserId();
        this.entityType = rating.getEntityType();
        this.entityId = rating.getEntityId();
        this.rating = rating.getRating();
        this.comment = rating.getComment();
        this.createdAt = rating.getCreatedAt();
        this.updatedAt = rating.getUpdatedAt();
        this.isActive = rating.getIsActive();
    }

    /**
     * Constructor completo con información del usuario
     */
    public RatingDTO(Rating rating, String userName, String userProfileImageUrl) {
        this(rating);
        this.userName = userName;
        this.userProfileImageUrl = userProfileImageUrl;
    }
}
