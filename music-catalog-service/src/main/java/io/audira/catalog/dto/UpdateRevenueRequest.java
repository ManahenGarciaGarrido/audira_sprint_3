package io.audira.catalog.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Request DTO for updating revenue percentage of a collaboration
 * GA01-155: Definir porcentaje de ganancias
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateRevenueRequest {

    @NotNull(message = "Revenue percentage is required")
    @DecimalMin(value = "0.00", message = "Revenue percentage must be at least 0")
    @DecimalMax(value = "100.00", message = "Revenue percentage cannot exceed 100")
    private BigDecimal revenuePercentage;
}
