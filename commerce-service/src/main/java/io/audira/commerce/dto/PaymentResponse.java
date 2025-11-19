package io.audira.commerce.dto;

import io.audira.commerce.model.PaymentStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentResponse {
    private boolean success;
    private String transactionId;
    private PaymentStatus status;
    private String message;
    private PaymentDTO payment;
}
