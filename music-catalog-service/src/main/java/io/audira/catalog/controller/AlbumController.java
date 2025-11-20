package io.audira.catalog.controller;

import io.audira.catalog.dto.AlbumCreateRequest;
import io.audira.catalog.dto.AlbumResponse;
import io.audira.catalog.dto.AlbumUpdateRequest;
import io.audira.catalog.model.Album;
import io.audira.catalog.service.AlbumService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/albums")
@RequiredArgsConstructor
public class AlbumController {

    private final AlbumService albumService;

    @GetMapping("/latest-releases")
    public ResponseEntity<List<Album>> getLatestReleases(@RequestParam(defaultValue = "20") int limit) {
        List<Album> albums = albumService.getRecentAlbums();
        return ResponseEntity.ok(albums.stream().limit(limit).toList());
    }

    @GetMapping
    public ResponseEntity<List<Album>> getAllAlbums() {
        List<Album> albums = albumService.getAllAlbums();
        return ResponseEntity.ok(albums);
    }

    @GetMapping("/{id}")
    public ResponseEntity<AlbumResponse> getAlbumById(@PathVariable Long id) {
        AlbumResponse response = albumService.getAlbumResponseById(id);
        if (response == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/artist/{artistId}")
    public ResponseEntity<List<Album>> getAlbumsByArtist(@PathVariable Long artistId) {
        List<Album> albums = albumService.getAlbumsByArtist(artistId);
        return ResponseEntity.ok(albums);
    }

    @PostMapping
    public ResponseEntity<AlbumResponse> createAlbum(@RequestBody AlbumCreateRequest request) {
        try {
            AlbumResponse response = albumService.createAlbum(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<AlbumResponse> updateAlbum(
            @PathVariable Long id,
            @RequestBody AlbumUpdateRequest request) {
        Optional<AlbumResponse> response = albumService.updateAlbum(id, request);
        return response.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/publish")
    public ResponseEntity<AlbumResponse> publishAlbum(
            @PathVariable Long id,
            @RequestParam boolean published) {
        Optional<AlbumResponse> response = albumService.publishAlbum(id, published);
        return response.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAlbum(@PathVariable Long id) {
        boolean deleted = albumService.deleteAlbum(id);
        if (deleted) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }

    // Endpoints públicos que solo retornan contenido publicado
    @GetMapping("/public/latest-releases")
    public ResponseEntity<List<Album>> getLatestPublishedReleases(@RequestParam(defaultValue = "20") int limit) {
        List<Album> albums = albumService.getRecentPublishedAlbums();
        return ResponseEntity.ok(albums.stream().limit(limit).toList());
    }
}
