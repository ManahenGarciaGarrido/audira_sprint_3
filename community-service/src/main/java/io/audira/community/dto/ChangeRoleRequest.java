package io.audira.community.dto;

import io.audira.community.model.UserRole;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for changing user role
 * GA01-164: Buscar/editar usuario (roles, estado)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangeRoleRequest {

    @NotNull(message = "Role is required")
    private UserRole role;
}
