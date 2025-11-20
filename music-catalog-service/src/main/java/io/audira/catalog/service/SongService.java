package io.audira.catalog.service;

import io.audira.catalog.model.Song;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SongService {

    private final SongRepository songRepository;

    @Transactional
    public Song createSong(Song song) {
        // Validate required fields
        if (song.getTitle() == null || song.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("Song title is required");
        }
        if (song.getArtistId() == null) {
            throw new IllegalArgumentException("Artist ID is required");
        }
        if (song.getDuration() == null || song.getDuration() <= 0) {
            throw new IllegalArgumentException("Valid duration is required");
        }
        if (song.getGenreIds() == null || song.getGenreIds().isEmpty()) {
            throw new IllegalArgumentException("At least one genre is required");
        }

        return songRepository.save(song);
    }

    public List<Song> getAllSongs() {
        return songRepository.findAll();
    }

    public Song getSongById(Long id) {
        return songRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));
    }

    public List<Song> getSongsByArtist(Long artistId) {
        return songRepository.findByArtistId(artistId);
    }

    public List<Song> getSongsByAlbum(Long albumId) {
        return songRepository.findByAlbumId(albumId);
    }

    public List<Song> getSongsByGenre(Long genreId) {
        return songRepository.findByGenreId(genreId);
    }

    public List<Song> getRecentSongs() {
        return songRepository.findTop20ByOrderByCreatedAtDesc();
    }

    public List<Song> getTopSongsByPlays() {
        return songRepository.findTopByPlays();
    }

    public List<Song> searchSongs(String query) {
        return songRepository.searchByTitleOrArtist(query);
    }

    @Transactional
    public Song updateSong(Long id, Song songDetails) {
        Song song = songRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));

        if (songDetails.getTitle() != null) {
            song.setTitle(songDetails.getTitle());
        }
        if (songDetails.getDescription() != null) {
            song.setDescription(songDetails.getDescription());
        }
        if (songDetails.getPrice() != null) {
            song.setPrice(songDetails.getPrice());
        }
        if (songDetails.getCoverImageUrl() != null) {
            song.setCoverImageUrl(songDetails.getCoverImageUrl());
        }
        if (songDetails.getAudioUrl() != null) {
            song.setAudioUrl(songDetails.getAudioUrl());
        }
        if (songDetails.getLyrics() != null) {
            song.setLyrics(songDetails.getLyrics());
        }
        if (songDetails.getDuration() != null) {
            song.setDuration(songDetails.getDuration());
        }
        if (songDetails.getGenreIds() != null && !songDetails.getGenreIds().isEmpty()) {
            song.setGenreIds(songDetails.getGenreIds());
        }
        if (songDetails.getCategory() != null) {
            song.setCategory(songDetails.getCategory());
        }
        if (songDetails.getAlbumId() != null) {
            song.setAlbumId(songDetails.getAlbumId());
        }
        if (songDetails.getTrackNumber() != null) {
            song.setTrackNumber(songDetails.getTrackNumber());
        }

        return songRepository.save(song);
    }

    @Transactional
    public void deleteSong(Long id) {
        if (!songRepository.existsById(id)) {
            throw new IllegalArgumentException("Song not found with id: " + id);
        }
        songRepository.deleteById(id);
    }

    @Transactional
    public Song incrementPlays(Long id) {
        Song song = getSongById(id);
        song.setPlays(song.getPlays() + 1);
        return songRepository.save(song);
    }

    /**
     * GA01-152: Publicar o ocultar una canción
     */
    @Transactional
    public Song publishSong(Long id, boolean published) {
        Song song = songRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));
        song.setPublished(published);
        return songRepository.save(song);
    }

    // Métodos públicos que solo retornan contenido publicado
    public List<Song> getRecentPublishedSongs() {
        return songRepository.findTop20ByPublishedTrueOrderByCreatedAtDesc();
    }

    public List<Song> getTopPublishedSongsByPlays() {
        return songRepository.findTopPublishedByPlays();
    }

    public List<Song> searchPublishedSongs(String query) {
        return songRepository.searchPublishedByTitleOrArtist(query);
    }

    public List<Song> getPublishedSongsByGenre(Long genreId) {
        return songRepository.findPublishedByGenreId(genreId);
    }
}
