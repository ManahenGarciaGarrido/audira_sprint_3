package io.audira.catalog.service;

import io.audira.catalog.dto.CollaborationRequest;
import io.audira.catalog.dto.UpdateRevenueRequest;
import io.audira.catalog.model.Collaborator;
import io.audira.catalog.model.CollaborationStatus;
import io.audira.catalog.repository.CollaboratorRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Service for managing collaborations
 * GA01-154: Añadir/aceptar colaboradores
 * GA01-155: Definir porcentaje de ganancias
 */
@Service
public class CollaboratorService {

    private static final Logger logger = LoggerFactory.getLogger(CollaboratorService.class);

    @Autowired
    private CollaboratorRepository collaboratorRepository;

    // ===== Existing methods =====

    public List<Collaborator> getAllCollaborators() {
        return collaboratorRepository.findAll();
    }

    public Optional<Collaborator> getCollaboratorById(Long id) {
        return collaboratorRepository.findById(id);
    }

    public List<Collaborator> getCollaboratorsBySongId(Long songId) {
        return collaboratorRepository.findBySongId(songId);
    }

    public List<Collaborator> getCollaboratorsByArtistId(Long artistId) {
        return collaboratorRepository.findByArtistId(artistId);
    }

    public Collaborator createCollaborator(Collaborator collaborator) {
        return collaboratorRepository.save(collaborator);
    }

    @Transactional
    public List<Collaborator> createCollaborators(List<Collaborator> collaborators) {
        return collaboratorRepository.saveAll(collaborators);
    }

    public Collaborator updateCollaborator(Long id, Collaborator collaboratorDetails) {
        Collaborator collaborator = collaboratorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Collaborator not found with id: " + id));

        collaborator.setSongId(collaboratorDetails.getSongId());
        collaborator.setArtistId(collaboratorDetails.getArtistId());
        collaborator.setRole(collaboratorDetails.getRole());

        return collaboratorRepository.save(collaborator);
    }

    public void deleteCollaborator(Long id) {
        collaboratorRepository.deleteById(id);
    }

    @Transactional
    public void deleteCollaboratorsBySongId(Long songId) {
        collaboratorRepository.deleteBySongId(songId);
    }

    // ===== GA01-154: New methods for collaboration invitations =====

    /**
     * Invite an artist to collaborate on a song or album
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public Collaborator inviteCollaborator(CollaborationRequest request, Long inviterId) {
        // Validate that either songId or albumId is provided
        if (request.getSongId() == null && request.getAlbumId() == null) {
            throw new IllegalArgumentException("Either songId or albumId must be provided");
        }
        if (request.getSongId() != null && request.getAlbumId() != null) {
            throw new IllegalArgumentException("Cannot specify both songId and albumId");
        }

        // Check if collaboration already exists
        List<Collaborator> existing;
        if (request.getSongId() != null) {
            existing = collaboratorRepository.findBySongId(request.getSongId());
        } else {
            existing = collaboratorRepository.findByAlbumId(request.getAlbumId());
        }

        boolean alreadyExists = existing.stream()
                .anyMatch(c -> c.getArtistId().equals(request.getArtistId()));

        if (alreadyExists) {
            throw new IllegalArgumentException("Collaboration already exists for this artist");
        }

        Collaborator collaborator = Collaborator.builder()
                .songId(request.getSongId())
                .albumId(request.getAlbumId())
                .artistId(request.getArtistId())
                .role(request.getRole())
                .status(CollaborationStatus.PENDING)
                .invitedBy(inviterId)
                .revenuePercentage(BigDecimal.ZERO)
                .build();

        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Collaboration invitation created: {} invited artist {} for {} {}",
                inviterId, request.getArtistId(),
                saved.isForSong() ? "song" : "album",
                saved.getEntityId());

        return saved;
    }

    /**
     * Accept a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public Collaborator acceptCollaboration(Long collaborationId, Long artistId) {
        Collaborator collaborator = collaboratorRepository.findById(collaborationId)
                .orElseThrow(() -> new RuntimeException("Collaboration not found with id: " + collaborationId));

        // Verify the artist is the one being invited
        if (!collaborator.getArtistId().equals(artistId)) {
            throw new IllegalArgumentException("You are not authorized to accept this collaboration");
        }

        // Verify status is PENDING
        if (collaborator.getStatus() != CollaborationStatus.PENDING) {
            throw new IllegalArgumentException("Collaboration is not in pending status");
        }

        collaborator.setStatus(CollaborationStatus.ACCEPTED);
        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Collaboration accepted: artist {} accepted collaboration {} for {} {}",
                artistId, collaborationId,
                saved.isForSong() ? "song" : "album",
                saved.getEntityId());

        return saved;
    }

    /**
     * Reject a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public Collaborator rejectCollaboration(Long collaborationId, Long artistId) {
        Collaborator collaborator = collaboratorRepository.findById(collaborationId)
                .orElseThrow(() -> new RuntimeException("Collaboration not found with id: " + collaborationId));

        // Verify the artist is the one being invited
        if (!collaborator.getArtistId().equals(artistId)) {
            throw new IllegalArgumentException("You are not authorized to reject this collaboration");
        }

        // Verify status is PENDING
        if (collaborator.getStatus() != CollaborationStatus.PENDING) {
            throw new IllegalArgumentException("Collaboration is not in pending status");
        }

        collaborator.setStatus(CollaborationStatus.REJECTED);
        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Collaboration rejected: artist {} rejected collaboration {} for {} {}",
                artistId, collaborationId,
                saved.isForSong() ? "song" : "album",
                saved.getEntityId());

        return saved;
    }

    /**
     * Get pending collaboration invitations for an artist
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getPendingInvitations(Long artistId) {
        return collaboratorRepository.findByArtistIdAndStatus(artistId, CollaborationStatus.PENDING);
    }

    /**
     * Get collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getCollaboratorsByAlbumId(Long albumId) {
        return collaboratorRepository.findByAlbumId(albumId);
    }

    /**
     * Get accepted collaborations for a song
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getAcceptedCollaboratorsBySongId(Long songId) {
        return collaboratorRepository.findBySongIdAndStatus(songId, CollaborationStatus.ACCEPTED);
    }

    /**
     * Get accepted collaborations for an album
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getAcceptedCollaboratorsByAlbumId(Long albumId) {
        return collaboratorRepository.findByAlbumIdAndStatus(albumId, CollaborationStatus.ACCEPTED);
    }

    /**
     * Get collaborations created by a user
     * GA01-154: Añadir/aceptar colaboradores
     */
    public List<Collaborator> getCollaborationsByInviter(Long inviterId) {
        return collaboratorRepository.findByInvitedBy(inviterId);
    }

    // ===== GA01-155: New methods for revenue percentage =====

    /**
     * Update revenue percentage for a collaboration
     * GA01-155: Definir porcentaje de ganancias
     */
    @Transactional
    public Collaborator updateRevenuePercentage(Long collaborationId, UpdateRevenueRequest request, Long userId) {
        Collaborator collaborator = collaboratorRepository.findById(collaborationId)
                .orElseThrow(() -> new RuntimeException("Collaboration not found with id: " + collaborationId));

        // Verify the user is the one who created the invitation
        if (!collaborator.getInvitedBy().equals(userId)) {
            throw new IllegalArgumentException("Only the creator can update revenue percentage");
        }

        // Verify collaboration is accepted
        if (collaborator.getStatus() != CollaborationStatus.ACCEPTED) {
            throw new IllegalArgumentException("Can only set revenue percentage for accepted collaborations");
        }

        // Validate total revenue percentage doesn't exceed 100%
        BigDecimal currentTotal = calculateTotalRevenuePercentage(
                collaborator.getSongId(),
                collaborator.getAlbumId(),
                collaborationId
        );

        BigDecimal newTotal = currentTotal.add(request.getRevenuePercentage());
        if (newTotal.compareTo(BigDecimal.valueOf(100)) > 0) {
            throw new IllegalArgumentException(
                    String.format("Total revenue percentage would exceed 100%%. Current: %.2f%%, Requested: %.2f%%, Total would be: %.2f%%",
                            currentTotal, request.getRevenuePercentage(), newTotal)
            );
        }

        collaborator.setRevenuePercentage(request.getRevenuePercentage());
        Collaborator saved = collaboratorRepository.save(collaborator);

        logger.info("Revenue percentage updated: collaboration {} set to {}%",
                collaborationId, request.getRevenuePercentage());

        return saved;
    }

    /**
     * Calculate total revenue percentage for a song or album (excluding specific collaboration)
     * GA01-155: Definir porcentaje de ganancias
     */
    private BigDecimal calculateTotalRevenuePercentage(Long songId, Long albumId, Long excludeCollaborationId) {
        List<Collaborator> collaborators;

        if (songId != null) {
            collaborators = collaboratorRepository.findBySongIdAndStatus(songId, CollaborationStatus.ACCEPTED);
        } else if (albumId != null) {
            collaborators = collaboratorRepository.findByAlbumIdAndStatus(albumId, CollaborationStatus.ACCEPTED);
        } else {
            return BigDecimal.ZERO;
        }

        return collaborators.stream()
                .filter(c -> !c.getId().equals(excludeCollaborationId))
                .map(Collaborator::getRevenuePercentage)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /**
     * Get total revenue percentage for a song
     * GA01-155: Definir porcentaje de ganancias
     */
    public BigDecimal getTotalRevenuePercentageForSong(Long songId) {
        return calculateTotalRevenuePercentage(songId, null, null);
    }

    /**
     * Get total revenue percentage for an album
     * GA01-155: Definir porcentaje de ganancias
     */
    public BigDecimal getTotalRevenuePercentageForAlbum(Long albumId) {
        return calculateTotalRevenuePercentage(null, albumId, null);
    }

    /**
     * Delete collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    @Transactional
    public void deleteCollaboratorsByAlbumId(Long albumId) {
        collaboratorRepository.deleteByAlbumId(albumId);
    }
}
