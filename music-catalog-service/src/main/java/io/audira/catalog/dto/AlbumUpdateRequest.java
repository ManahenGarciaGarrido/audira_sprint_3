package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumUpdateRequest {

    private String title;
    private String description;
    private BigDecimal price;
    private String coverImageUrl;
    private Set<Long> genreIds;
    private LocalDate releaseDate;
    private Double discountPercentage;
}