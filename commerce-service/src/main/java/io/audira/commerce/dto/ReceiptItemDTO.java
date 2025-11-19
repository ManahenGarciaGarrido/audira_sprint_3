package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReceiptItemDTO {
    private String itemName;
    private String itemType;
    private int quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;
}

