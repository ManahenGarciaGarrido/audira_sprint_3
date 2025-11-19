package io.audira.community.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Entidad Rating para el sistema de valoraciones
 * GA01-128: Puntuación de 1-5 estrellas
 * GA01-129: Comentario opcional (500 chars)
 * GA01-130: Editar/eliminar valoración
 */
@Entity
@Table(name = "ratings",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "entity_type", "entity_id"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Rating {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario que realiza la valoración
     */
    @NotNull(message = "User ID is required")
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /**
     * Tipo de entidad valorada (ARTIST, SONG, ALBUM, USER, etc.)
     */
    @NotNull(message = "Entity type is required")
    @Column(name = "entity_type", nullable = false, length = 50)
    private String entityType;

    /**
     * ID de la entidad valorada
     */
    @NotNull(message = "Entity ID is required")
    @Column(name = "entity_id", nullable = false)
    private Long entityId;

    /**
     * GA01-128: Puntuación de 1-5 estrellas
     */
    @NotNull(message = "Rating value is required")
    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    @Column(nullable = false)
    private Integer rating;

    /**
     * GA01-129: Comentario opcional (máximo 500 caracteres)
     */
    @Size(max = 500, message = "Comment cannot exceed 500 characters")
    @Column(length = 500)
    private String comment;

    /**
     * Fecha de creación
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Fecha de última actualización (para edición - GA01-130)
     */
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /**
     * Indica si la valoración está activa
     */
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
}
