package io.audira.community.repository;

import io.audira.community.model.Artist;
import io.audira.community.model.User;
import io.audira.community.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByUsername(String username);
    Optional<User> findByEmailOrUsername(String email, String username);

    Boolean existsByEmail(String email);
    Boolean existsByUsername(String username);

    List<User> findByRole(UserRole role);
    List<User> findByIsActive(Boolean isActive);

    @Query("SELECT a FROM Artist a WHERE " +
           "LOWER(a.artistName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(a.firstName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(a.lastName) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Artist> searchArtistsByName(@Param("query") String query);

    @Query("SELECT a.id FROM Artist a WHERE " +
           "LOWER(a.artistName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(a.firstName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(a.lastName) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Long> searchArtistIdsByName(@Param("query") String query);
}
