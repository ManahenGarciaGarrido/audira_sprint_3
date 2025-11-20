package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Playlist entity representing user-created playlists
 * GA01-113: Crear lista con nombre
 * GA01-114: Añadir/eliminar canciones
 * GA01-115: Editar nombre / eliminar lista
 */
@Entity
@Table(name = "playlists")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Playlist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_public", nullable = false)
    @Builder.Default
    private Boolean isPublic = false;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "playlist_songs", joinColumns = @JoinColumn(name = "playlist_id"))
    @Column(name = "song_id")
    @OrderColumn(name = "song_order")
    @Builder.Default
    private List<Long> songIds = new ArrayList<>();

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.isPublic == null) {
            this.isPublic = false;
        }
        if (this.songIds == null) {
            this.songIds = new ArrayList<>();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Get the number of songs in the playlist
     */
    public int getSongCount() {
        return songIds != null ? songIds.size() : 0;
    }

    /**
     * Check if the playlist contains a specific song
     */
    public boolean containsSong(Long songId) {
        return songIds != null && songIds.contains(songId);
    }

    /**
     * Add a song to the playlist
     */
    public void addSong(Long songId) {
        if (songIds == null) {
            songIds = new ArrayList<>();
        }
        if (!songIds.contains(songId)) {
            songIds.add(songId);
        }
    }

    /**
     * Remove a song from the playlist
     */
    public boolean removeSong(Long songId) {
        if (songIds != null) {
            return songIds.remove(songId);
        }
        return false;
    }
}
