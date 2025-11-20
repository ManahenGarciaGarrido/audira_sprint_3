package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Collaborator entity representing artist collaborations on songs/albums
 * GA01-154: Añadir/aceptar colaboradores - status, invitedBy, albumId
 * GA01-155: Definir porcentaje de ganancias - revenuePercentage
 */
@Entity
@Table(name = "collaborators")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Collaborator {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "song_id")
    private Long songId;

    @Column(name = "album_id")
    private Long albumId; // GA01-154: Support album collaborations

    @Column(name = "artist_id", nullable = false)
    private Long artistId; // The collaborator artist ID

    @Column(nullable = false, length = 100)
    private String role; // feature, producer, composer, etc.

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private CollaborationStatus status = CollaborationStatus.PENDING; // GA01-154: Invitation status

    @Column(name = "invited_by", nullable = false)
    private Long invitedBy; // GA01-154: ID of user who created the invitation

    @Column(name = "revenue_percentage", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal revenuePercentage = BigDecimal.ZERO; // GA01-155: Percentage of revenue (0-100)

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.status == null) {
            this.status = CollaborationStatus.PENDING;
        }
        if (this.revenuePercentage == null) {
            this.revenuePercentage = BigDecimal.ZERO;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Check if collaboration is for a song
     */
    public boolean isForSong() {
        return songId != null;
    }

    /**
     * Check if collaboration is for an album
     */
    public boolean isForAlbum() {
        return albumId != null;
    }

    /**
     * Get the entity ID (song or album)
     */
    public Long getEntityId() {
        return songId != null ? songId : albumId;
    }

    /**
     * Get the entity type
     */
    public String getEntityType() {
        return songId != null ? "SONG" : "ALBUM";
    }
}
