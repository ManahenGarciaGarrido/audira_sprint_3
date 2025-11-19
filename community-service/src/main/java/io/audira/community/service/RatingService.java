package io.audira.community.service;

import io.audira.community.client.CommerceClient;
import io.audira.community.dto.*;
import io.audira.community.exception.RatingException;
import io.audira.community.model.Rating;
import io.audira.community.repository.RatingRepository;
import io.audira.community.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Servicio para gestión de valoraciones
 * GA01-128: Puntuación de 1-5 estrellas
 * GA01-129: Comentario opcional (500 chars)
 * GA01-130: Editar/eliminar valoración
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RatingService {

    private final RatingRepository ratingRepository;
    private final UserRepository userRepository;
    private final CommerceClient commerceClient;

    /**
     * GA01-128, GA01-129: Crear o actualizar valoración
     * Si el usuario ya tiene una valoración para la entidad, la actualiza
     * Verifica que el usuario haya comprado el producto antes de permitir valorar
     */
    @Transactional
    public RatingDTO createOrUpdateRating(Long userId, CreateRatingRequest request) {
        log.info("Creating/updating rating for user {} on {} {}", userId, request.getEntityType(), request.getEntityId());

        // Validaciones
        validateRatingValue(request.getRating());
        validateComment(request.getComment());

        // Buscar si ya existe una valoración
        Rating rating = ratingRepository
                .findByUserIdAndEntityTypeAndEntityId(userId, request.getEntityType(), request.getEntityId())
                .orElse(null);

        // Si es una nueva valoración (no actualización), verificar que haya comprado el producto
        if (rating == null) {
            String entityType = request.getEntityType().toUpperCase();

            // Solo verificar compra para SONG y ALBUM
            if ("SONG".equals(entityType) || "ALBUM".equals(entityType)) {
                boolean hasPurchased = commerceClient.hasPurchasedItem(
                    userId,
                    entityType,
                    request.getEntityId()
                );

                if (!hasPurchased) {
                    log.warn("User {} attempted to rate {} {} without purchasing it",
                        userId, entityType, request.getEntityId());
                    throw new RatingException.ProductNotPurchasedException(entityType, request.getEntityId());
                }

                log.info("User {} has purchased {} {} - allowing rating",
                    userId, entityType, request.getEntityId());
            }
        }

        if (rating != null) {
            // Actualizar valoración existente
            log.info("Updating existing rating {} for user {}", rating.getId(), userId);
            rating.setRating(request.getRating());
            rating.setComment(request.getComment());
            rating.setIsActive(true);
        } else {
            // Crear nueva valoración
            rating = new Rating();
            rating.setUserId(userId);
            rating.setEntityType(request.getEntityType().toUpperCase());
            rating.setEntityId(request.getEntityId());
            rating.setRating(request.getRating());
            rating.setComment(request.getComment());
            rating.setIsActive(true);
        }

        Rating savedRating = ratingRepository.save(rating);
        log.info("Rating saved successfully: {}", savedRating.getId());

        return convertToDTO(savedRating);
    }

    /**
     * GA01-130: Actualizar valoración existente
     */
    @Transactional
    public RatingDTO updateRating(Long ratingId, Long userId, UpdateRatingRequest request) {
        log.info("Updating rating {} by user {}", ratingId, userId);

        Rating rating = ratingRepository.findByIdAndUserId(ratingId, userId)
                .orElseThrow(() -> new RatingException.RatingNotFoundException(ratingId));

        // Validar ownership
        if (!rating.getUserId().equals(userId)) {
            throw new RatingException.UnauthorizedRatingAccessException();
        }

        // Actualizar campos si están presentes
        if (request.getRating() != null) {
            validateRatingValue(request.getRating());
            rating.setRating(request.getRating());
        }

        if (request.getComment() != null) {
            validateComment(request.getComment());
            rating.setComment(request.getComment());
        }

        Rating updatedRating = ratingRepository.save(rating);
        log.info("Rating {} updated successfully", ratingId);

        return convertToDTO(updatedRating);
    }

    /**
     * GA01-130: Eliminar valoración (soft delete)
     */
    @Transactional
    public void deleteRating(Long ratingId, Long userId) {
        log.info("Deleting rating {} by user {}", ratingId, userId);

        Rating rating = ratingRepository.findByIdAndUserId(ratingId, userId)
                .orElseThrow(() -> new RatingException.RatingNotFoundException(ratingId));

        // Validar ownership
        if (!rating.getUserId().equals(userId)) {
            throw new RatingException.UnauthorizedRatingAccessException();
        }

        // Soft delete
        rating.setIsActive(false);
        ratingRepository.save(rating);

        log.info("Rating {} deleted successfully", ratingId);
    }

    /**
     * Obtener valoraciones de un usuario
     */
    @Transactional(readOnly = true)
    public List<RatingDTO> getUserRatings(Long userId) {
        log.info("Getting ratings for user {}", userId);
        List<Rating> ratings = ratingRepository.findByUserIdAndIsActiveTrue(userId);
        return ratings.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Obtener valoraciones de una entidad
     */
    @Transactional(readOnly = true)
    public List<RatingDTO> getEntityRatings(String entityType, Long entityId) {
        log.info("Getting ratings for {} {}", entityType, entityId);
        List<Rating> ratings = ratingRepository
                .findByEntityTypeAndEntityIdAndIsActiveTrueOrderByCreatedAtDesc(
                        entityType.toUpperCase(), entityId);

        return ratings.stream()
                .map(this::convertToDTOWithUserInfo)
                .collect(Collectors.toList());
    }

    /**
     * Obtener valoraciones con comentarios de una entidad
     */
    @Transactional(readOnly = true)
    public List<RatingDTO> getEntityRatingsWithComments(String entityType, Long entityId) {
        log.info("Getting ratings with comments for {} {}", entityType, entityId);
        List<Rating> ratings = ratingRepository.findRatingsWithComments(
                entityType.toUpperCase(), entityId);

        return ratings.stream()
                .map(this::convertToDTOWithUserInfo)
                .collect(Collectors.toList());
    }

    /**
     * Obtener estadísticas de valoraciones de una entidad
     */
    @Transactional(readOnly = true)
    public RatingStatsDTO getEntityRatingStats(String entityType, Long entityId) {
        log.info("Getting rating stats for {} {}", entityType, entityId);

        String entityTypeUpper = entityType.toUpperCase();
        Double average = ratingRepository.calculateAverageRating(entityTypeUpper, entityId);
        Long total = ratingRepository.countByEntityTypeAndEntityIdAndIsActiveTrue(entityTypeUpper, entityId);

        RatingStatsDTO stats = new RatingStatsDTO(entityTypeUpper, entityId, average, total);

        // Obtener distribución de estrellas
        stats.setFiveStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 5));
        stats.setFourStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 4));
        stats.setThreeStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 3));
        stats.setTwoStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 2));
        stats.setOneStar(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 1));

        return stats;
    }

    /**
     * Obtener valoración de un usuario para una entidad específica
     */
    @Transactional(readOnly = true)
    public RatingDTO getUserEntityRating(Long userId, String entityType, Long entityId) {
        log.info("Getting rating for user {} on {} {}", userId, entityType, entityId);

        return ratingRepository
                .findByUserIdAndEntityTypeAndEntityId(userId, entityType.toUpperCase(), entityId)
                .filter(Rating::getIsActive)
                .map(this::convertToDTO)
                .orElse(null);
    }

    /**
     * Verificar si un usuario ha valorado una entidad
     */
    @Transactional(readOnly = true)
    public boolean hasUserRatedEntity(Long userId, String entityType, Long entityId) {
        return ratingRepository.existsByUserIdAndEntityTypeAndEntityIdAndIsActiveTrue(
                userId, entityType.toUpperCase(), entityId);
    }

    // Métodos privados de validación y conversión

    private void validateRatingValue(Integer rating) {
        if (rating == null || rating < 1 || rating > 5) {
            throw new RatingException.InvalidRatingValueException();
        }
    }

    private void validateComment(String comment) {
        if (comment != null && comment.length() > 500) {
            throw new RatingException.InvalidCommentLengthException();
        }
    }

    private RatingDTO convertToDTO(Rating rating) {
        return new RatingDTO(rating);
    }

    private RatingDTO convertToDTOWithUserInfo(Rating rating) {
        RatingDTO dto = new RatingDTO(rating);

        // Obtener información del usuario
        userRepository.findById(rating.getUserId()).ifPresent(user -> {
            dto.setUserName(user.getUsername());
            dto.setUserProfileImageUrl(user.getProfileImageUrl());
        });

        return dto;
    }
}
