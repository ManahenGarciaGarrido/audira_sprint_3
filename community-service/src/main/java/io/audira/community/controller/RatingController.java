package io.audira.community.controller;

import io.audira.community.dto.*;
import io.audira.community.exception.RatingException;
import io.audira.community.security.UserPrincipal;
import io.audira.community.service.RatingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controlador REST para valoraciones
 * GA01-128: Puntuación de 1-5 estrellas
 * GA01-129: Comentario opcional (500 chars)
 * GA01-130: Editar/eliminar valoración
 */
@RestController
@RequestMapping("/api/ratings")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class RatingController {

    private final RatingService ratingService;

    /**
     * GA01-128, GA01-129: Crear o actualizar valoración
     * POST /api/ratings
     */
    @PostMapping
    public ResponseEntity<?> createRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody CreateRatingRequest request) {
        try {
            RatingDTO rating = ratingService.createOrUpdateRating(currentUser.getId(), request);
            return ResponseEntity.status(HttpStatus.CREATED).body(rating);
        } catch (RatingException e) {
            log.error("Error creating rating: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error creating rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Internal server error"));
        }
    }

    /**
     * GA01-130: Actualizar valoración existente
     * PUT /api/ratings/{ratingId}
     */
    @PutMapping("/{ratingId}")
    public ResponseEntity<?> updateRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable Long ratingId,
            @Valid @RequestBody UpdateRatingRequest request) {
        try {
            RatingDTO rating = ratingService.updateRating(ratingId, currentUser.getId(), request);
            return ResponseEntity.ok(rating);
        } catch (RatingException.RatingNotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (RatingException.UnauthorizedRatingAccessException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", e.getMessage()));
        } catch (RatingException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error updating rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Internal server error"));
        }
    }

    /**
     * GA01-130: Eliminar valoración
     * DELETE /api/ratings/{ratingId}
     */
    @DeleteMapping("/{ratingId}")
    public ResponseEntity<?> deleteRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable Long ratingId) {
        try {
            ratingService.deleteRating(ratingId, currentUser.getId());
            return ResponseEntity.noContent().build();
        } catch (RatingException.RatingNotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (RatingException.UnauthorizedRatingAccessException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error deleting rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Internal server error"));
        }
    }

    /**
     * Obtener todas las valoraciones de un usuario
     * GET /api/ratings/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<RatingDTO>> getUserRatings(@PathVariable Long userId) {
        try {
            List<RatingDTO> ratings = ratingService.getUserRatings(userId);
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting user ratings", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtener todas las valoraciones del usuario actual
     * GET /api/ratings/my-ratings
     */
    @GetMapping("/my-ratings")
    public ResponseEntity<List<RatingDTO>> getMyRatings(
            @AuthenticationPrincipal UserPrincipal currentUser) {
        try {
            List<RatingDTO> ratings = ratingService.getUserRatings(currentUser.getId());
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting my ratings", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtener todas las valoraciones de una entidad
     * GET /api/ratings/entity/{entityType}/{entityId}
     */
    @GetMapping("/entity/{entityType}/{entityId}")
    public ResponseEntity<List<RatingDTO>> getEntityRatings(
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            List<RatingDTO> ratings = ratingService.getEntityRatings(entityType, entityId);
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting entity ratings", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtener valoraciones con comentarios de una entidad
     * GET /api/ratings/entity/{entityType}/{entityId}/with-comments
     */
    @GetMapping("/entity/{entityType}/{entityId}/with-comments")
    public ResponseEntity<List<RatingDTO>> getEntityRatingsWithComments(
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            List<RatingDTO> ratings = ratingService.getEntityRatingsWithComments(entityType, entityId);
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting entity ratings with comments", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtener estadísticas de valoraciones de una entidad
     * GET /api/ratings/entity/{entityType}/{entityId}/stats
     */
    @GetMapping("/entity/{entityType}/{entityId}/stats")
    public ResponseEntity<RatingStatsDTO> getEntityRatingStats(
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            RatingStatsDTO stats = ratingService.getEntityRatingStats(entityType, entityId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            log.error("Error getting rating stats", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtener valoración de un usuario para una entidad específica
     * GET /api/ratings/user/{userId}/entity/{entityType}/{entityId}
     */
    @GetMapping("/user/{userId}/entity/{entityType}/{entityId}")
    public ResponseEntity<RatingDTO> getUserEntityRating(
            @PathVariable Long userId,
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            RatingDTO rating = ratingService.getUserEntityRating(userId, entityType, entityId);
            if (rating == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(rating);
        } catch (Exception e) {
            log.error("Error getting user entity rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtener mi valoración para una entidad específica
     * GET /api/ratings/my-rating/entity/{entityType}/{entityId}
     */
    @GetMapping("/my-rating/entity/{entityType}/{entityId}")
    public ResponseEntity<RatingDTO> getMyEntityRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            RatingDTO rating = ratingService.getUserEntityRating(currentUser.getId(), entityType, entityId);
            if (rating == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(rating);
        } catch (Exception e) {
            log.error("Error getting my entity rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Verificar si he valorado una entidad
     * GET /api/ratings/has-rated/entity/{entityType}/{entityId}
     */
    @GetMapping("/has-rated/entity/{entityType}/{entityId}")
    public ResponseEntity<Map<String, Boolean>> hasRatedEntity(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            boolean hasRated = ratingService.hasUserRatedEntity(currentUser.getId(), entityType, entityId);
            return ResponseEntity.ok(Map.of("hasRated", hasRated));
        } catch (Exception e) {
            log.error("Error checking if user has rated entity", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
