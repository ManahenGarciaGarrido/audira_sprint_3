package io.audira.catalog.controller;

import io.audira.catalog.model.Song;
import io.audira.catalog.service.SongService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/songs")
@RequiredArgsConstructor
public class SongController {

    private final SongService songService;

    @PostMapping
    public ResponseEntity<?> createSong(@RequestBody Song song) {
        try {
            Song createdSong = songService.createSong(song);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdSong);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @GetMapping
    public ResponseEntity<List<Song>> getAllSongs() {
        return ResponseEntity.ok(songService.getAllSongs());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getSongById(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(songService.getSongById(id));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @GetMapping("/artist/{artistId}")
    public ResponseEntity<List<Song>> getSongsByArtist(@PathVariable Long artistId) {
        return ResponseEntity.ok(songService.getSongsByArtist(artistId));
    }

    @GetMapping("/album/{albumId}")
    public ResponseEntity<List<Song>> getSongsByAlbum(@PathVariable Long albumId) {
        return ResponseEntity.ok(songService.getSongsByAlbum(albumId));
    }

    @GetMapping("/genre/{genreId}")
    public ResponseEntity<List<Song>> getSongsByGenre(@PathVariable Long genreId) {
        return ResponseEntity.ok(songService.getSongsByGenre(genreId));
    }

    @GetMapping("/recent")
    public ResponseEntity<List<Song>> getRecentSongs() {
        return ResponseEntity.ok(songService.getRecentSongs());
    }

    @GetMapping("/top")
    public ResponseEntity<List<Song>> getTopSongs() {
        return ResponseEntity.ok(songService.getTopSongsByPlays());
    }

    @GetMapping("/search")
    public ResponseEntity<List<Song>> searchSongs(@RequestParam String query) {
        return ResponseEntity.ok(songService.searchSongs(query));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateSong(@PathVariable Long id, @RequestBody Song song) {
        try {
            return ResponseEntity.ok(songService.updateSong(id, song));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteSong(@PathVariable Long id) {
        try {
            songService.deleteSong(id);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping("/{id}/play")
    public ResponseEntity<Song> incrementPlays(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(songService.incrementPlays(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * GA01-152: Publicar o ocultar una canción
     */
    @PatchMapping("/{id}/publish")
    public ResponseEntity<Song> publishSong(@PathVariable Long id, @RequestParam boolean published) {
        try {
            return ResponseEntity.ok(songService.publishSong(id, published));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // Endpoints públicos que solo retornan contenido publicado
    @GetMapping("/public/recent")
    public ResponseEntity<List<Song>> getRecentPublishedSongs() {
        return ResponseEntity.ok(songService.getRecentPublishedSongs());
    }

    @GetMapping("/public/top")
    public ResponseEntity<List<Song>> getTopPublishedSongs() {
        return ResponseEntity.ok(songService.getTopPublishedSongsByPlays());
    }

    @GetMapping("/public/search")
    public ResponseEntity<List<Song>> searchPublishedSongs(@RequestParam String query) {
        return ResponseEntity.ok(songService.searchPublishedSongs(query));
    }

    @GetMapping("/public/genre/{genreId}")
    public ResponseEntity<List<Song>> getPublishedSongsByGenre(@PathVariable Long genreId) {
        return ResponseEntity.ok(songService.getPublishedSongsByGenre(genreId));
    }
}
