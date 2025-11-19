package io.audira.catalog.service;

import io.audira.catalog.model.Genre;
import io.audira.catalog.repository.GenreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class GenreService {

    private final GenreRepository genreRepository;

    @Transactional
    public Genre createGenre(Genre genre) {
        if (genreRepository.existsByName(genre.getName())) {
            throw new IllegalArgumentException("Genre with name '" + genre.getName() + "' already exists");
        }
        return genreRepository.save(genre);
    }

    public List<Genre> getAllGenres() {
        return genreRepository.findAll();
    }

    public Genre getGenreById(Long id) {
        return genreRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Genre not found with id: " + id));
    }

    public Optional<Genre> getGenreByName(String name) {
        return genreRepository.findByName(name);
    }

    @Transactional
    public Genre updateGenre(Long id, Genre genreDetails) {
        Genre genre = genreRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Genre not found with id: " + id));

        if (genreDetails.getName() != null && !genreDetails.getName().equals(genre.getName())) {
            if (genreRepository.existsByName(genreDetails.getName())) {
                throw new IllegalArgumentException("Genre with name '" + genreDetails.getName() + "' already exists");
            }
            genre.setName(genreDetails.getName());
        }

        if (genreDetails.getDescription() != null) {
            genre.setDescription(genreDetails.getDescription());
        }

        if (genreDetails.getImageUrl() != null) {
            genre.setImageUrl(genreDetails.getImageUrl());
        }

        return genreRepository.save(genre);
    }

    @Transactional
    public void deleteGenre(Long id) {
        if (!genreRepository.existsById(id)) {
            throw new IllegalArgumentException("Genre not found with id: " + id);
        }
        genreRepository.deleteById(id);
    }
}
