package io.audira.catalog.controller;

import io.audira.catalog.model.Playlist;
import io.audira.catalog.service.PlaylistService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * REST Controller for Playlist management
 * GA01-113: Crear lista con nombre
 * GA01-114: Añadir/eliminar canciones
 * GA01-115: Editar nombre / eliminar lista
 */
@RestController
@RequestMapping("/api/playlists")
@RequiredArgsConstructor
public class PlaylistController {

    private final PlaylistService playlistService;

    /**
     * Get all playlists
     * @return List of all playlists
     */
    @GetMapping
    public ResponseEntity<List<Playlist>> getAllPlaylists() {
        return ResponseEntity.ok(playlistService.getAllPlaylists());
    }

    /**
     * Get playlist by ID
     * GA01-113: View playlist details
     * @param id Playlist ID
     * @return Playlist details
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getPlaylistById(@PathVariable Long id) {
        Optional<Playlist> playlist = playlistService.getPlaylistById(id);
        if (playlist.isPresent()) {
            return ResponseEntity.ok(playlist.get());
        } else {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Playlist not found with id: " + id);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Get all playlists for a user
     * GA01-113: List user's playlists
     * @param userId User ID
     * @return List of user's playlists
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Playlist>> getUserPlaylists(@PathVariable Long userId) {
        return ResponseEntity.ok(playlistService.getUserPlaylists(userId));
    }

    /**
     * Get all public playlists
     * @return List of public playlists
     */
    @GetMapping("/public")
    public ResponseEntity<List<Playlist>> getPublicPlaylists() {
        return ResponseEntity.ok(playlistService.getPublicPlaylists());
    }

    /**
     * Create a new playlist
     * GA01-113: Crear lista con nombre
     * @param playlist Playlist data
     * @return Created playlist
     */
    @PostMapping
    public ResponseEntity<?> createPlaylist(@RequestBody Playlist playlist) {
        try {
            Playlist createdPlaylist = playlistService.createPlaylist(playlist);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdPlaylist);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Update playlist information
     * GA01-115: Editar nombre / eliminar lista
     * @param id Playlist ID
     * @param updates Map with fields to update (name, description, isPublic)
     * @return Updated playlist
     */
    @PatchMapping("/{id}")
    public ResponseEntity<?> updatePlaylist(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            String name = (String) updates.get("name");
            String description = (String) updates.get("description");
            Boolean isPublic = (Boolean) updates.get("isPublic");

            Playlist updatedPlaylist = playlistService.updatePlaylist(id, name, description, isPublic);
            return ResponseEntity.ok(updatedPlaylist);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Delete a playlist
     * GA01-115: Editar nombre / eliminar lista
     * @param id Playlist ID
     * @return No content
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePlaylist(@PathVariable Long id) {
        try {
            playlistService.deletePlaylist(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Add a song to a playlist
     * GA01-114: Añadir/eliminar canciones
     * @param id Playlist ID
     * @param songId Song ID (from query parameter)
     * @return Updated playlist
     */
    @PostMapping("/{id}/songs")
    public ResponseEntity<?> addSongToPlaylist(
            @PathVariable Long id,
            @RequestParam Long songId) {
        try {
            Playlist updatedPlaylist = playlistService.addSongToPlaylist(id, songId);
            return ResponseEntity.ok(updatedPlaylist);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Remove a song from a playlist
     * GA01-114: Añadir/eliminar canciones
     * @param id Playlist ID
     * @param songId Song ID to remove
     * @return Updated playlist
     */
    @DeleteMapping("/{id}/songs/{songId}")
    public ResponseEntity<?> removeSongFromPlaylist(
            @PathVariable Long id,
            @PathVariable Long songId) {
        try {
            Playlist updatedPlaylist = playlistService.removeSongFromPlaylist(id, songId);
            return ResponseEntity.ok(updatedPlaylist);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Reorder songs in a playlist
     * GA01-114: Manage playlist song order
     * @param id Playlist ID
     * @param request Map with "songIds" list
     * @return Updated playlist
     */
    @PutMapping("/{id}/songs/reorder")
    public ResponseEntity<?> reorderPlaylistSongs(
            @PathVariable Long id,
            @RequestBody Map<String, List<Long>> request) {
        try {
            List<Long> songIds = request.get("songIds");
            if (songIds == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "songIds is required");
                return ResponseEntity.badRequest().body(error);
            }

            Playlist updatedPlaylist = playlistService.reorderPlaylistSongs(id, songIds);
            return ResponseEntity.ok(updatedPlaylist);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Get playlists containing a specific song
     * @param userId User ID
     * @param songId Song ID
     * @return List of playlists containing the song
     */
    @GetMapping("/user/{userId}/song/{songId}")
    public ResponseEntity<List<Playlist>> getPlaylistsContainingSong(
            @PathVariable Long userId,
            @PathVariable Long songId) {
        return ResponseEntity.ok(playlistService.getPlaylistsContainingSong(userId, songId));
    }
}
