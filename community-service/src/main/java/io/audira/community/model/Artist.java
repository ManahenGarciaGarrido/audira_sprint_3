package io.audira.community.model;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

@Entity
@Table(name = "artists")
@DiscriminatorValue("ARTIST")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Artist extends User {

    @Column(name = "artist_name")
    private String artistName; // Stage name

    @Column(name = "verified_artist")
    private Boolean verifiedArtist;

    @Column(columnDefinition = "TEXT")
    private String artistBio;

    private String recordLabel;

    @Override
    public String getUserType() {
        return "ARTIST";
    }
}
