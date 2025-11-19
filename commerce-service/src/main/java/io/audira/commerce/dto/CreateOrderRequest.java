package io.audira.commerce.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderRequest {

    @NotNull(message = "User ID cannot be null")
    private Long userId;

    @NotBlank(message = "Shipping address cannot be blank")
    private String shippingAddress;

    @NotEmpty(message = "Order must contain at least one item")
    @Valid // This enables validation on the OrderItemDTOs inside the list
    private List<OrderItemDTO> items;
}
