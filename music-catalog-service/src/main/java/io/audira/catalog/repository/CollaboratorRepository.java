package io.audira.catalog.repository;

import io.audira.catalog.model.Collaborator;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CollaboratorRepository extends JpaRepository<Collaborator, Long> {

    List<Collaborator> findBySongId(Long songId);

    List<Collaborator> findByArtistId(Long artistId);

    void deleteBySongId(Long songId);
}