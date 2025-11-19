package io.audira.catalog.service;

import io.audira.catalog.model.Album;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DiscoveryService {
    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${community.service.url:http://172.16.0.4:8081}")
    private String communityServiceUrl;

    public List<Song> getTrendingSongs() {
        return songRepository.findTopByPlays();
    }

    public List<Album> getTrendingAlbums() {
        // Por ahora devuelve los álbumes más recientes
        return albumRepository.findTop20ByOrderByCreatedAtDesc();
    }

    // Search methods for GA01-96 and GA01-98
    public Page<Song> searchSongs(String query, Pageable pageable) {
        if (query == null || query.trim().isEmpty()) {
            return Page.empty(pageable);
        }

        // Get artist IDs matching the query from community-service
        List<Long> artistIds = getArtistIdsByName(query);

        // Search by title and/or artist IDs
        if (artistIds.isEmpty()) {
            // Only search by title
            return songRepository.searchByTitle(query, pageable);
        } else {
            // Search by both title and artist IDs
            return songRepository.searchByTitleOrArtistIds(query, artistIds, pageable);
        }
    }

    public Page<Album> searchAlbums(String query, Pageable pageable) {
        if (query == null || query.trim().isEmpty()) {
            return Page.empty(pageable);
        }

        // Get artist IDs matching the query from community-service
        List<Long> artistIds = getArtistIdsByName(query);

        // Search by title and/or artist IDs
        if (artistIds.isEmpty()) {
            // Only search by title
            return albumRepository.searchByTitle(query, pageable);
        } else {
            // Search by both title and artist IDs
            return albumRepository.searchByTitleOrArtistIds(query, artistIds, pageable);
        }
    }

    private List<Long> getArtistIdsByName(String query) {
        try {
            String url = UriComponentsBuilder.fromHttpUrl(communityServiceUrl + "/api/users/search/artist-ids")
                    .queryParam("query", query)
                    .toUriString();

            ResponseEntity<List<Long>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Long>>() {}
            );

            return response.getBody() != null ? response.getBody() : new ArrayList<>();
        } catch (Exception e) {
            // If community-service is unavailable, just return empty list
            // This allows searching by title only
            return new ArrayList<>();
        }
    }
}