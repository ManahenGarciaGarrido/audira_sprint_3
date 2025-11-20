package io.audira.catalog.service;

import io.audira.catalog.model.Playlist;
import io.audira.catalog.repository.PlaylistRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Service for managing playlists
 * GA01-113: Crear lista con nombre
 * GA01-114: Añadir/eliminar canciones
 * GA01-115: Editar nombre / eliminar lista
 */
@Service
public class PlaylistService {

    private static final Logger logger = LoggerFactory.getLogger(PlaylistService.class);

    @Autowired
    private PlaylistRepository playlistRepository;

    /**
     * Get all playlists
     * @return List of all playlists
     */
    public List<Playlist> getAllPlaylists() {
        return playlistRepository.findAll();
    }

    /**
     * Get playlist by ID
     * GA01-113: View playlist details
     * @param id Playlist ID
     * @return Playlist if found
     */
    public Optional<Playlist> getPlaylistById(Long id) {
        return playlistRepository.findById(id);
    }

    /**
     * Get all playlists created by a user
     * GA01-113: List user's playlists
     * @param userId User ID
     * @return List of user's playlists
     */
    public List<Playlist> getUserPlaylists(Long userId) {
        return playlistRepository.findByUserId(userId);
    }

    /**
     * Get all public playlists
     * @return List of public playlists
     */
    public List<Playlist> getPublicPlaylists() {
        return playlistRepository.findByIsPublicTrue();
    }

    /**
     * Create a new playlist
     * GA01-113: Crear lista con nombre
     * @param playlist Playlist to create
     * @return Created playlist
     */
    @Transactional
    public Playlist createPlaylist(Playlist playlist) {
        // Validate playlist data
        if (playlist.getName() == null || playlist.getName().trim().isEmpty()) {
            throw new IllegalArgumentException("Playlist name is required");
        }
        if (playlist.getUserId() == null) {
            throw new IllegalArgumentException("User ID is required");
        }

        logger.info("Creating playlist '{}' for user {}", playlist.getName(), playlist.getUserId());
        return playlistRepository.save(playlist);
    }

    /**
     * Update playlist information
     * GA01-115: Editar nombre / eliminar lista
     * @param id Playlist ID
     * @param name New name (optional)
     * @param description New description (optional)
     * @param isPublic New public status (optional)
     * @return Updated playlist
     */
    @Transactional
    public Playlist updatePlaylist(Long id, String name, String description, Boolean isPublic) {
        Playlist playlist = playlistRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Playlist not found with id: " + id));

        if (name != null && !name.trim().isEmpty()) {
            playlist.setName(name.trim());
        }
        if (description != null) {
            playlist.setDescription(description.trim().isEmpty() ? null : description.trim());
        }
        if (isPublic != null) {
            playlist.setIsPublic(isPublic);
        }

        logger.info("Updating playlist {} with new details", id);
        return playlistRepository.save(playlist);
    }

    /**
     * Delete a playlist
     * GA01-115: Editar nombre / eliminar lista
     * @param id Playlist ID
     */
    @Transactional
    public void deletePlaylist(Long id) {
        Playlist playlist = playlistRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Playlist not found with id: " + id));

        logger.info("Deleting playlist {} '{}' for user {}", id, playlist.getName(), playlist.getUserId());
        playlistRepository.deleteById(id);
    }

    /**
     * Add a song to a playlist
     * GA01-114: Añadir/eliminar canciones
     * @param playlistId Playlist ID
     * @param songId Song ID to add
     * @return Updated playlist
     */
    @Transactional
    public Playlist addSongToPlaylist(Long playlistId, Long songId) {
        Playlist playlist = playlistRepository.findById(playlistId)
                .orElseThrow(() -> new RuntimeException("Playlist not found with id: " + playlistId));

        if (playlist.containsSong(songId)) {
            logger.warn("Song {} already exists in playlist {}", songId, playlistId);
            return playlist; // Song already in playlist
        }

        playlist.addSong(songId);
        logger.info("Adding song {} to playlist {}", songId, playlistId);
        return playlistRepository.save(playlist);
    }

    /**
     * Remove a song from a playlist
     * GA01-114: Añadir/eliminar canciones
     * @param playlistId Playlist ID
     * @param songId Song ID to remove
     * @return Updated playlist
     */
    @Transactional
    public Playlist removeSongFromPlaylist(Long playlistId, Long songId) {
        Playlist playlist = playlistRepository.findById(playlistId)
                .orElseThrow(() -> new RuntimeException("Playlist not found with id: " + playlistId));

        boolean removed = playlist.removeSong(songId);
        if (removed) {
            logger.info("Removing song {} from playlist {}", songId, playlistId);
            return playlistRepository.save(playlist);
        } else {
            logger.warn("Song {} not found in playlist {}", songId, playlistId);
            return playlist;
        }
    }

    /**
     * Reorder songs in a playlist
     * GA01-114: Manage playlist song order
     * @param playlistId Playlist ID
     * @param songIds New ordered list of song IDs
     * @return Updated playlist
     */
    @Transactional
    public Playlist reorderPlaylistSongs(Long playlistId, List<Long> songIds) {
        Playlist playlist = playlistRepository.findById(playlistId)
                .orElseThrow(() -> new RuntimeException("Playlist not found with id: " + playlistId));

        // Validate that all provided song IDs are in the playlist
        for (Long songId : songIds) {
            if (!playlist.containsSong(songId)) {
                throw new IllegalArgumentException("Song " + songId + " is not in the playlist");
            }
        }

        // Validate that all playlist songs are in the provided list
        if (songIds.size() != playlist.getSongCount()) {
            throw new IllegalArgumentException("Song count mismatch. Expected " +
                    playlist.getSongCount() + " songs, but got " + songIds.size());
        }

        playlist.setSongIds(songIds);
        logger.info("Reordering songs in playlist {}", playlistId);
        return playlistRepository.save(playlist);
    }

    /**
     * Check if user owns a playlist
     * @param playlistId Playlist ID
     * @param userId User ID
     * @return true if user owns the playlist
     */
    public boolean isPlaylistOwner(Long playlistId, Long userId) {
        Optional<Playlist> playlist = playlistRepository.findById(playlistId);
        return playlist.isPresent() && playlist.get().getUserId().equals(userId);
    }

    /**
     * Get playlists that contain a specific song
     * @param userId User ID
     * @param songId Song ID
     * @return List of playlists containing the song
     */
    public List<Playlist> getPlaylistsContainingSong(Long userId, Long songId) {
        return playlistRepository.findByUserId(userId).stream()
                .filter(playlist -> playlist.containsSong(songId))
                .toList();
    }
}
