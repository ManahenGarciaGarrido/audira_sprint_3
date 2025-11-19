package io.audira.catalog.service;

import io.audira.catalog.model.Collaborator;
import io.audira.catalog.repository.CollaboratorRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class CollaboratorService {

    @Autowired
    private CollaboratorRepository collaboratorRepository;

    public List<Collaborator> getAllCollaborators() {
        return collaboratorRepository.findAll();
    }

    public Optional<Collaborator> getCollaboratorById(Long id) {
        return collaboratorRepository.findById(id);
    }

    public List<Collaborator> getCollaboratorsBySongId(Long songId) {
        return collaboratorRepository.findBySongId(songId);
    }

    public List<Collaborator> getCollaboratorsByArtistId(Long artistId) {
        return collaboratorRepository.findByArtistId(artistId);
    }

    public Collaborator createCollaborator(Collaborator collaborator) {
        return collaboratorRepository.save(collaborator);
    }

    @Transactional
    public List<Collaborator> createCollaborators(List<Collaborator> collaborators) {
        return collaboratorRepository.saveAll(collaborators);
    }

    public Collaborator updateCollaborator(Long id, Collaborator collaboratorDetails) {
        Collaborator collaborator = collaboratorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Collaborator not found with id: " + id));

        collaborator.setSongId(collaboratorDetails.getSongId());
        collaborator.setArtistId(collaboratorDetails.getArtistId());
        collaborator.setRole(collaboratorDetails.getRole());

        return collaboratorRepository.save(collaborator);
    }

    public void deleteCollaborator(Long id) {
        collaboratorRepository.deleteById(id);
    }

    @Transactional
    public void deleteCollaboratorsBySongId(Long songId) {
        collaboratorRepository.deleteBySongId(songId);
    }
}