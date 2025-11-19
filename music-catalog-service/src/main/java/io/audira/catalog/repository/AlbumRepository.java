package io.audira.catalog.repository;

import io.audira.catalog.model.Album;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.query.Param;
import java.util.List;

@Repository
public interface AlbumRepository extends JpaRepository<Album, Long>{
    List<Album> findTop20ByOrderByCreatedAtDesc();
    
    List<Album> findByArtistId(Long artistId);
    
    @Query("SELECT a FROM Album a ORDER BY a.releaseDate DESC")
    List<Album> findRecentAlbums();
    
    @Query("SELECT a FROM Album a WHERE LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Album> searchByTitle(@Param("query") String query, Pageable pageable);

    @Query("SELECT a FROM Album a WHERE a.artistId IN :artistIds")
    Page<Album> searchByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    @Query("SELECT a FROM Album a WHERE LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%')) OR a.artistId IN :artistIds")
    Page<Album> searchByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);
}
