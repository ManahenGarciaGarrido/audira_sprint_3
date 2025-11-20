package io.audira.catalog.repository;

import io.audira.catalog.model.Playlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for Playlist entity
 * GA01-113: Crear lista con nombre
 * GA01-114: Añadir/eliminar canciones
 * GA01-115: Editar nombre / eliminar lista
 */
@Repository
public interface PlaylistRepository extends JpaRepository<Playlist, Long> {

    /**
     * Find all playlists created by a specific user
     * @param userId User ID
     * @return List of playlists
     */
    List<Playlist> findByUserId(Long userId);

    /**
     * Find all public playlists
     * @return List of public playlists
     */
    List<Playlist> findByIsPublicTrue();

    /**
     * Find playlists by user and public status
     * @param userId User ID
     * @param isPublic Public status
     * @return List of playlists
     */
    List<Playlist> findByUserIdAndIsPublic(Long userId, Boolean isPublic);

    /**
     * Delete all playlists created by a specific user
     * @param userId User ID
     */
    void deleteByUserId(Long userId);
}
