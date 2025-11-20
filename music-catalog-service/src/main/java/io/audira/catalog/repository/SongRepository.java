package io.audira.catalog.repository;

import io.audira.catalog.model.Song;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.query.Param;
import java.util.List;

@Repository
public interface SongRepository extends JpaRepository<Song, Long> {
    // Métodos sin filtro de publicación (para studio/admin)
    List<Song> findByArtistId(Long artistId);
    List<Song> findByAlbumId(Long albumId);
    List<Song> findByTitleContainingIgnoreCase(String title);
    List<Song> findTop20ByOrderByCreatedAtDesc();
    List<Song> findByAlbumIdOrderByTrackNumberAsc(Long albumId);

    @Query("SELECT s FROM Song s WHERE LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Song> searchByTitleOrArtist(String query);

    @Query("SELECT s FROM Song s ORDER BY s.createdAt DESC")
    List<Song> findRecentSongs();

    @Query("SELECT s FROM Song s JOIN s.genreIds g WHERE g = :genreId")
    List<Song> findByGenreId(Long genreId);

    @Query("SELECT s FROM Song s ORDER BY s.plays DESC")
    List<Song> findTopByPlays();

    @Query("SELECT s FROM Song s WHERE LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Song> searchByTitle(@Param("query") String query, Pageable pageable);

    @Query("SELECT s FROM Song s WHERE s.artistId IN :artistIds")
    Page<Song> searchByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    @Query("SELECT s FROM Song s WHERE LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%')) OR s.artistId IN :artistIds")
    Page<Song> searchByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);

    // Métodos con filtro de publicación (para vistas públicas)
    List<Song> findTop20ByPublishedTrueOrderByCreatedAtDesc();

    @Query("SELECT s FROM Song s WHERE s.published = true ORDER BY s.createdAt DESC")
    List<Song> findRecentPublishedSongs();

    @Query("SELECT s FROM Song s WHERE s.published = true AND LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Song> searchPublishedByTitleOrArtist(String query);

    @Query("SELECT s FROM Song s JOIN s.genreIds g WHERE s.published = true AND g = :genreId")
    List<Song> findPublishedByGenreId(Long genreId);

    @Query("SELECT s FROM Song s WHERE s.published = true ORDER BY s.plays DESC")
    List<Song> findTopPublishedByPlays();

    @Query("SELECT s FROM Song s WHERE s.published = true AND LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Song> searchPublishedByTitle(@Param("query") String query, Pageable pageable);

    @Query("SELECT s FROM Song s WHERE s.published = true AND s.artistId IN :artistIds")
    Page<Song> searchPublishedByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    @Query("SELECT s FROM Song s WHERE s.published = true AND (LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%')) OR s.artistId IN :artistIds)")
    Page<Song> searchPublishedByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);
}
