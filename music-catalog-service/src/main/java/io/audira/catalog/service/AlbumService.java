package io.audira.catalog.service;

import io.audira.catalog.dto.AlbumCreateRequest;
import io.audira.catalog.dto.AlbumResponse;
import io.audira.catalog.dto.AlbumUpdateRequest;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AlbumService {

    private final AlbumRepository albumRepository;
    private final SongRepository songRepository;

    public List<Album> getRecentAlbums() {
        return albumRepository.findRecentAlbums();
    }

    public Optional<Album> getAlbumById(Long id) {
        return albumRepository.findById(id);
    }

    public List<Album> getAllAlbums() {
        return albumRepository.findAll();
    }

    public List<Album> getAlbumsByArtist(Long artistId) {
        return albumRepository.findByArtistId(artistId);
    }

    @Transactional
    public AlbumResponse createAlbum(AlbumCreateRequest request) {
        // Crear el álbum
        Album album = Album.builder()
                .title(request.getTitle())
                .artistId(request.getArtistId())
                .description(request.getDescription())
                .price(request.getPrice())
                .coverImageUrl(request.getCoverImageUrl())
                .genreIds(request.getGenreIds())
                .releaseDate(request.getReleaseDate())
                .discountPercentage(request.getDiscountPercentage() != null ?
                        request.getDiscountPercentage() : 0.15)
                .published(false) // Por defecto no publicado
                .build();

        album = albumRepository.save(album);

        // Asociar canciones al álbum
        if (request.getSongIds() != null && !request.getSongIds().isEmpty()) {
            int trackNumber = 1;
            for (Long songId : request.getSongIds()) {
                Optional<Song> songOpt = songRepository.findById(songId);
                if (songOpt.isPresent()) {
                    Song song = songOpt.get();
                    song.setAlbumId(album.getId());
                    song.setTrackNumber(trackNumber++);
                    song.setCategory("Album");
                    songRepository.save(song);
                }
            }
        }

        int songCount = songRepository.findByAlbumId(album.getId()).size();
        return AlbumResponse.fromAlbum(album, songCount);
    }

    @Transactional
    public Optional<AlbumResponse> updateAlbum(Long id, AlbumUpdateRequest request) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return Optional.empty();
        }

        Album album = albumOpt.get();
        if (request.getTitle() != null) album.setTitle(request.getTitle());
        if (request.getDescription() != null) album.setDescription(request.getDescription());
        if (request.getPrice() != null) album.setPrice(request.getPrice());
        if (request.getCoverImageUrl() != null) album.setCoverImageUrl(request.getCoverImageUrl());
        if (request.getGenreIds() != null) album.setGenreIds(request.getGenreIds());
        if (request.getReleaseDate() != null) album.setReleaseDate(request.getReleaseDate());
        if (request.getDiscountPercentage() != null)
            album.setDiscountPercentage(request.getDiscountPercentage());

        album = albumRepository.save(album);
        int songCount = songRepository.findByAlbumId(album.getId()).size();
        return Optional.of(AlbumResponse.fromAlbum(album, songCount));
    }

    @Transactional
    public Optional<AlbumResponse> publishAlbum(Long id, boolean published) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return Optional.empty();
        }

        Album album = albumOpt.get();
        album.setPublished(published);
        album = albumRepository.save(album);

        int songCount = songRepository.findByAlbumId(album.getId()).size();
        return Optional.of(AlbumResponse.fromAlbum(album, songCount));
    }

    @Transactional
    public boolean deleteAlbum(Long id) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return false;
        }

        // Desasociar canciones del álbum
        List<Song> songs = songRepository.findByAlbumId(id);
        for (Song song : songs) {
            song.setAlbumId(null);
            song.setTrackNumber(null);
            song.setCategory("Single");
            songRepository.save(song);
        }

        albumRepository.deleteById(id);
        return true;
    }

    public AlbumResponse getAlbumResponseById(Long id) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return null;
        }

        Album album = albumOpt.get();
        int songCount = songRepository.findByAlbumId(id).size();
        return AlbumResponse.fromAlbum(album, songCount);
    }
}