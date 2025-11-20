package io.audira.community.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for changing user active status
 * GA01-165: Suspender/reactivar cuentas
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangeStatusRequest {

    @NotNull(message = "Active status is required")
    private Boolean isActive;
}
