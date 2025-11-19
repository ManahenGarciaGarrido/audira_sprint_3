package io.audira.commerce.dto;

import io.audira.commerce.model.ItemType;
import io.audira.commerce.model.PurchasedItem;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PurchasedItemDTO {

    private Long id;
    private Long userId;
    private ItemType itemType;
    private Long itemId;
    private Long orderId;
    private Long paymentId;
    private BigDecimal price;
    private Integer quantity;
    private LocalDateTime purchasedAt;

    public static PurchasedItemDTO fromEntity(PurchasedItem item) {
        return new PurchasedItemDTO(
            item.getId(),
            item.getUserId(),
            item.getItemType(),
            item.getItemId(),
            item.getOrderId(),
            item.getPaymentId(),
            item.getPrice(),
            item.getQuantity(),
            item.getPurchasedAt()
        );
    }
}
