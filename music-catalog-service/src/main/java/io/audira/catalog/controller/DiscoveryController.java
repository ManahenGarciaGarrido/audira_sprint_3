package io.audira.catalog.controller;

import io.audira.catalog.model.Album;
import io.audira.catalog.model.Song;
import io.audira.catalog.service.DiscoveryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/discovery")
@RequiredArgsConstructor
public class DiscoveryController {

    private final DiscoveryService discoveryService;

    @GetMapping("/trending/songs")
    public ResponseEntity<List<Song>> getTrendingSongs(@RequestParam(defaultValue = "20") int limit) {
        List<Song> songs = discoveryService.getTrendingSongs();
        return ResponseEntity.ok(songs.stream().limit(limit).toList());
    }

    // Search endpoints for GA01-96 and GA01-98
    @GetMapping("/search/songs")
    public ResponseEntity<Map<String, Object>> searchSongs(
            @RequestParam("query") String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Song> songPage = discoveryService.searchSongs(query, pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("content", songPage.getContent());
        response.put("currentPage", songPage.getNumber());
        response.put("totalItems", songPage.getTotalElements());
        response.put("totalPages", songPage.getTotalPages());
        response.put("hasMore", songPage.hasNext());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/search/albums")
    public ResponseEntity<Map<String, Object>> searchAlbums(
            @RequestParam("query") String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Album> albumPage = discoveryService.searchAlbums(query, pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("content", albumPage.getContent());
        response.put("currentPage", albumPage.getNumber());
        response.put("totalItems", albumPage.getTotalElements());
        response.put("totalPages", albumPage.getTotalPages());
        response.put("hasMore", albumPage.hasNext());

        return ResponseEntity.ok(response);
    }
}