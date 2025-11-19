package io.audira.catalog.dto;

import io.audira.catalog.model.Album;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumResponse {

    private Long id;
    private String title;
    private Long artistId;
    private String description;
    private BigDecimal price;
    private String coverImageUrl;
    private Set<Long> genreIds;
    private LocalDate releaseDate;
    private Double discountPercentage;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private boolean published;
    private int songCount;

    public static AlbumResponse fromAlbum(Album album, int songCount) {
        return AlbumResponse.builder()
                .id(album.getId())
                .title(album.getTitle())
                .artistId(album.getArtistId())
                .description(album.getDescription())
                .price(album.getPrice())
                .coverImageUrl(album.getCoverImageUrl())
                .genreIds(album.getGenreIds())
                .releaseDate(album.getReleaseDate())
                .discountPercentage(album.getDiscountPercentage())
                .createdAt(album.getCreatedAt())
                .updatedAt(album.getUpdatedAt())
                .published(album.isPublished())
                .songCount(songCount)
                .build();
    }
}