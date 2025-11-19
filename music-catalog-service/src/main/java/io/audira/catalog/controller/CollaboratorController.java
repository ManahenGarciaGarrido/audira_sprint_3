package io.audira.catalog.controller;

import io.audira.catalog.model.Collaborator;
import io.audira.catalog.service.CollaboratorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/collaborators")
@CrossOrigin(origins = "*")
public class CollaboratorController {

    @Autowired
    private CollaboratorService collaboratorService;

    @GetMapping
    public ResponseEntity<List<Collaborator>> getAllCollaborators() {
        return ResponseEntity.ok(collaboratorService.getAllCollaborators());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Collaborator> getCollaboratorById(@PathVariable Long id) {
        return collaboratorService.getCollaboratorById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/song/{songId}")
    public ResponseEntity<List<Collaborator>> getCollaboratorsBySongId(@PathVariable Long songId) {
        return ResponseEntity.ok(collaboratorService.getCollaboratorsBySongId(songId));
    }

    @GetMapping("/artist/{artistId}")
    public ResponseEntity<List<Collaborator>> getCollaboratorsByArtistId(@PathVariable Long artistId) {
        return ResponseEntity.ok(collaboratorService.getCollaboratorsByArtistId(artistId));
    }

    @PostMapping
    public ResponseEntity<Collaborator> createCollaborator(@RequestBody Collaborator collaborator) {
        Collaborator created = collaboratorService.createCollaborator(collaborator);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PostMapping("/batch")
    public ResponseEntity<List<Collaborator>> createCollaborators(@RequestBody List<Collaborator> collaborators) {
        List<Collaborator> created = collaboratorService.createCollaborators(collaborators);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Collaborator> updateCollaborator(
            @PathVariable Long id,
            @RequestBody Collaborator collaboratorDetails) {
        try {
            Collaborator updated = collaboratorService.updateCollaborator(id, collaboratorDetails);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCollaborator(@PathVariable Long id) {
        collaboratorService.deleteCollaborator(id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/song/{songId}")
    public ResponseEntity<Void> deleteCollaboratorsBySongId(@PathVariable Long songId) {
        collaboratorService.deleteCollaboratorsBySongId(songId);
        return ResponseEntity.noContent().build();
    }
}