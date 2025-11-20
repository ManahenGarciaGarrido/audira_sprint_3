package io.audira.catalog.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for creating collaboration invitations
 * GA01-154: Añadir/aceptar colaboradores
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CollaborationRequest {

    private Long songId; // Either songId or albumId must be provided

    private Long albumId; // Either songId or albumId must be provided

    @NotNull(message = "Artist ID is required")
    private Long artistId; // The artist being invited to collaborate

    @NotNull(message = "Role is required")
    @Size(min = 1, max = 100, message = "Role must be between 1 and 100 characters")
    private String role; // feature, producer, composer, etc.
}
