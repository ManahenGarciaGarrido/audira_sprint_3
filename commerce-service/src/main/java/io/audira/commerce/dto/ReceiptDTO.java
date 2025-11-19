package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReceiptDTO {
    private String receiptNumber;
    private PaymentDTO payment;
    private OrderDTO order;
    private String customerName;
    private String customerEmail;
    private BigDecimal subtotal;
    private BigDecimal tax;
    private BigDecimal total;
    private LocalDateTime issuedAt;
    private List<ReceiptItemDTO> items;
}
