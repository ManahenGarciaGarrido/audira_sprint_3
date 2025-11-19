package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumCreateRequest {

    private String title;
    private Long artistId;
    private String description;
    private BigDecimal price;
    private String coverImageUrl;
    private Set<Long> genreIds;
    private LocalDate releaseDate;
    private Double discountPercentage;

    // Lista de IDs de canciones a incluir en el álbum
    private List<Long> songIds;
}