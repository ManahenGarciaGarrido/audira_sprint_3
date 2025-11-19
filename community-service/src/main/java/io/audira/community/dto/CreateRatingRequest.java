package io.audira.community.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para crear una nueva valoración
 * GA01-128, GA01-129
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateRatingRequest {

    @NotNull(message = "Entity type is required")
    @NotBlank(message = "Entity type cannot be blank")
    private String entityType;

    @NotNull(message = "Entity ID is required")
    @Min(value = 1, message = "Entity ID must be positive")
    private Long entityId;

    /**
     * GA01-128: Puntuación de 1-5 estrellas
     */
    @NotNull(message = "Rating is required")
    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    private Integer rating;

    /**
     * GA01-129: Comentario opcional (máximo 500 caracteres)
     */
    @Size(max = 500, message = "Comment cannot exceed 500 characters")
    private String comment;
}
