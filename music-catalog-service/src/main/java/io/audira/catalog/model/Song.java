package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "songs")
@DiscriminatorValue("SONG")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Song extends Product {

    @Column(name = "album_id")
    private Long albumId;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "song_genres", joinColumns = @JoinColumn(name = "song_id"))
    @Column(name = "genre_id")
    @Builder.Default
    private Set<Long> genreIds = new HashSet<>();

    @Column(nullable = false)
    private Integer duration; // Duration in seconds

    @Column(name = "audio_url")
    private String audioUrl;

    @Column(columnDefinition = "TEXT")
    private String lyrics;

    @Column(name = "track_number")
    private Integer trackNumber; // Only filled if part of an album

    @Column(nullable = false)
    @Builder.Default
    private Long plays = 0L; // Number of times played

    @Column(length = 100)
    private String category; // Category: Single, Album, EP, Remix, Cover, etc.
    
    @Override
    public String getProductType() {
        return "SONG";
    }
}
