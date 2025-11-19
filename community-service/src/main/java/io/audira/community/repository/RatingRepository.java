package io.audira.community.repository;

import io.audira.community.model.Rating;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio para la entidad Rating
 * GA01-128, GA01-129, GA01-130
 */
@Repository
public interface RatingRepository extends JpaRepository<Rating, Long> {

    /**
     * Buscar valoración específica de un usuario para una entidad
     */
    Optional<Rating> findByUserIdAndEntityTypeAndEntityId(Long userId, String entityType, Long entityId);

    /**
     * Obtener todas las valoraciones de un usuario
     */
    List<Rating> findByUserIdAndIsActiveTrue(Long userId);

    /**
     * Obtener todas las valoraciones de una entidad
     */
    List<Rating> findByEntityTypeAndEntityIdAndIsActiveTrue(String entityType, Long entityId);

    /**
     * Obtener todas las valoraciones de un usuario para un tipo de entidad
     */
    List<Rating> findByUserIdAndEntityTypeAndIsActiveTrue(Long userId, String entityType);

    /**
     * Calcular promedio de valoraciones para una entidad
     */
    @Query("SELECT AVG(r.rating) FROM Rating r WHERE r.entityType = :entityType AND r.entityId = :entityId AND r.isActive = true")
    Double calculateAverageRating(@Param("entityType") String entityType, @Param("entityId") Long entityId);

    /**
     * Contar valoraciones de una entidad
     */
    Long countByEntityTypeAndEntityIdAndIsActiveTrue(String entityType, Long entityId);

    /**
     * Contar valoraciones por número de estrellas
     */
    @Query("SELECT COUNT(r) FROM Rating r WHERE r.entityType = :entityType AND r.entityId = :entityId AND r.rating = :stars AND r.isActive = true")
    Long countByRatingStars(@Param("entityType") String entityType, @Param("entityId") Long entityId, @Param("stars") Integer stars);

    /**
     * Verificar si un usuario ya ha valorado una entidad
     */
    boolean existsByUserIdAndEntityTypeAndEntityIdAndIsActiveTrue(Long userId, String entityType, Long entityId);

    /**
     * Obtener valoraciones recientes de una entidad (ordenadas por fecha)
     */
    List<Rating> findByEntityTypeAndEntityIdAndIsActiveTrueOrderByCreatedAtDesc(String entityType, Long entityId);

    /**
     * Obtener valoraciones con comentarios de una entidad
     */
    @Query("SELECT r FROM Rating r WHERE r.entityType = :entityType AND r.entityId = :entityId AND r.comment IS NOT NULL AND r.comment != '' AND r.isActive = true ORDER BY r.createdAt DESC")
    List<Rating> findRatingsWithComments(@Param("entityType") String entityType, @Param("entityId") Long entityId);

    /**
     * Buscar valoración por ID y usuario (para validar ownership en edición/eliminación)
     */
    Optional<Rating> findByIdAndUserId(Long id, Long userId);
}
