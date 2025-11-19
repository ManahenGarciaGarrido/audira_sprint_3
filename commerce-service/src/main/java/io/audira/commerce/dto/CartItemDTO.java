package io.audira.commerce.dto;

import io.audira.commerce.model.ItemType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItemDTO {
    private Long id;
    private Long cartId;
    private ItemType itemType;
    private Long itemId;
    private Integer quantity;
    private BigDecimal price;
}
