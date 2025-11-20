package io.audira.catalog.controller;

import io.audira.catalog.dto.CollaborationRequest;
import io.audira.catalog.dto.UpdateRevenueRequest;
import io.audira.catalog.model.Collaborator;
import io.audira.catalog.service.CollaboratorService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Controller for managing collaborations
 * GA01-154: Añadir/aceptar colaboradores
 * GA01-155: Definir porcentaje de ganancias
 */
@RestController
@RequestMapping("/api/collaborators")
@CrossOrigin(origins = "*")
public class CollaboratorController {

    @Autowired
    private CollaboratorService collaboratorService;

    // ===== Existing endpoints =====

    @GetMapping
    public ResponseEntity<List<Collaborator>> getAllCollaborators() {
        return ResponseEntity.ok(collaboratorService.getAllCollaborators());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Collaborator> getCollaboratorById(@PathVariable Long id) {
        return collaboratorService.getCollaboratorById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/song/{songId}")
    public ResponseEntity<List<Collaborator>> getCollaboratorsBySongId(@PathVariable Long songId) {
        return ResponseEntity.ok(collaboratorService.getCollaboratorsBySongId(songId));
    }

    @GetMapping("/artist/{artistId}")
    public ResponseEntity<List<Collaborator>> getCollaboratorsByArtistId(@PathVariable Long artistId) {
        return ResponseEntity.ok(collaboratorService.getCollaboratorsByArtistId(artistId));
    }

    @PostMapping
    public ResponseEntity<Collaborator> createCollaborator(@RequestBody Collaborator collaborator) {
        Collaborator created = collaboratorService.createCollaborator(collaborator);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PostMapping("/batch")
    public ResponseEntity<List<Collaborator>> createCollaborators(@RequestBody List<Collaborator> collaborators) {
        List<Collaborator> created = collaboratorService.createCollaborators(collaborators);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Collaborator> updateCollaborator(
            @PathVariable Long id,
            @RequestBody Collaborator collaboratorDetails) {
        try {
            Collaborator updated = collaboratorService.updateCollaborator(id, collaboratorDetails);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCollaborator(@PathVariable Long id) {
        collaboratorService.deleteCollaborator(id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/song/{songId}")
    public ResponseEntity<Void> deleteCollaboratorsBySongId(@PathVariable Long songId) {
        collaboratorService.deleteCollaboratorsBySongId(songId);
        return ResponseEntity.noContent().build();
    }

    // ===== GA01-154: New endpoints for collaboration invitations =====

    /**
     * Invite an artist to collaborate
     * GA01-154: Añadir/aceptar colaboradores
     */
    @PostMapping("/invite")
    public ResponseEntity<Collaborator> inviteCollaborator(
            @Valid @RequestBody CollaborationRequest request,
            @RequestParam Long inviterId) {
        try {
            Collaborator collaboration = collaboratorService.inviteCollaborator(request, inviterId);
            return ResponseEntity.status(HttpStatus.CREATED).body(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Accept a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @PutMapping("/{id}/accept")
    public ResponseEntity<Collaborator> acceptCollaboration(
            @PathVariable Long id,
            @RequestParam Long artistId) {
        try {
            Collaborator collaboration = collaboratorService.acceptCollaboration(id, artistId);
            return ResponseEntity.ok(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Reject a collaboration invitation
     * GA01-154: Añadir/aceptar colaboradores
     */
    @PutMapping("/{id}/reject")
    public ResponseEntity<Collaborator> rejectCollaboration(
            @PathVariable Long id,
            @RequestParam Long artistId) {
        try {
            Collaborator collaboration = collaboratorService.rejectCollaboration(id, artistId);
            return ResponseEntity.ok(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Get pending collaboration invitations for an artist
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/pending/{artistId}")
    public ResponseEntity<List<Collaborator>> getPendingInvitations(@PathVariable Long artistId) {
        List<Collaborator> invitations = collaboratorService.getPendingInvitations(artistId);
        return ResponseEntity.ok(invitations);
    }

    /**
     * Get collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/album/{albumId}")
    public ResponseEntity<List<Collaborator>> getCollaboratorsByAlbumId(@PathVariable Long albumId) {
        List<Collaborator> collaborators = collaboratorService.getCollaboratorsByAlbumId(albumId);
        return ResponseEntity.ok(collaborators);
    }

    /**
     * Get accepted collaborations for a song
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/song/{songId}/accepted")
    public ResponseEntity<List<Collaborator>> getAcceptedCollaboratorsBySongId(@PathVariable Long songId) {
        List<Collaborator> collaborators = collaboratorService.getAcceptedCollaboratorsBySongId(songId);
        return ResponseEntity.ok(collaborators);
    }

    /**
     * Get accepted collaborations for an album
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/album/{albumId}/accepted")
    public ResponseEntity<List<Collaborator>> getAcceptedCollaboratorsByAlbumId(@PathVariable Long albumId) {
        List<Collaborator> collaborators = collaboratorService.getAcceptedCollaboratorsByAlbumId(albumId);
        return ResponseEntity.ok(collaborators);
    }

    /**
     * Get collaborations created by a user
     * GA01-154: Añadir/aceptar colaboradores
     */
    @GetMapping("/inviter/{inviterId}")
    public ResponseEntity<List<Collaborator>> getCollaborationsByInviter(@PathVariable Long inviterId) {
        List<Collaborator> collaborations = collaboratorService.getCollaborationsByInviter(inviterId);
        return ResponseEntity.ok(collaborations);
    }

    // ===== GA01-155: New endpoints for revenue percentage =====

    /**
     * Update revenue percentage for a collaboration
     * GA01-155: Definir porcentaje de ganancias
     */
    @PutMapping("/{id}/revenue")
    public ResponseEntity<Collaborator> updateRevenuePercentage(
            @PathVariable Long id,
            @Valid @RequestBody UpdateRevenueRequest request,
            @RequestParam Long userId) {
        try {
            Collaborator collaboration = collaboratorService.updateRevenuePercentage(id, request, userId);
            return ResponseEntity.ok(collaboration);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Get total revenue percentage for a song
     * GA01-155: Definir porcentaje de ganancias
     */
    @GetMapping("/song/{songId}/revenue-total")
    public ResponseEntity<Map<String, BigDecimal>> getTotalRevenuePercentageForSong(@PathVariable Long songId) {
        BigDecimal total = collaboratorService.getTotalRevenuePercentageForSong(songId);
        return ResponseEntity.ok(Map.of("totalPercentage", total));
    }

    /**
     * Get total revenue percentage for an album
     * GA01-155: Definir porcentaje de ganancias
     */
    @GetMapping("/album/{albumId}/revenue-total")
    public ResponseEntity<Map<String, BigDecimal>> getTotalRevenuePercentageForAlbum(@PathVariable Long albumId) {
        BigDecimal total = collaboratorService.getTotalRevenuePercentageForAlbum(albumId);
        return ResponseEntity.ok(Map.of("totalPercentage", total));
    }

    /**
     * Delete collaborations by album ID
     * GA01-154: Añadir/aceptar colaboradores
     */
    @DeleteMapping("/album/{albumId}")
    public ResponseEntity<Void> deleteCollaboratorsByAlbumId(@PathVariable Long albumId) {
        collaboratorService.deleteCollaboratorsByAlbumId(albumId);
        return ResponseEntity.noContent().build();
    }
}
