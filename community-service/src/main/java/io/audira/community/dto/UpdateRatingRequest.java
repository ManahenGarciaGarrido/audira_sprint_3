package io.audira.community.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para actualizar una valoración existente
 * GA01-130: Editar valoración
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateRatingRequest {

    /**
     * GA01-128: Puntuación de 1-5 estrellas (opcional en actualización)
     */
    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    private Integer rating;

    /**
     * GA01-129: Comentario opcional (máximo 500 caracteres)
     */
    @Size(max = 500, message = "Comment cannot exceed 500 characters")
    private String comment;
}
