package io.audira.commerce.controller;

import io.audira.commerce.dto.ReceiptDTO;
import io.audira.commerce.service.ReceiptService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/receipts")
@RequiredArgsConstructor
@Slf4j
public class ReceiptController {

    private final ReceiptService receiptService;

    @GetMapping("/payment/{paymentId}")
    public ResponseEntity<?> getReceiptByPaymentId(@PathVariable Long paymentId) {
        try {
            log.info("GET /api/receipts/payment/{} - Fetching receipt", paymentId);
            ReceiptDTO receipt = receiptService.getReceiptByPaymentId(paymentId);
            return ResponseEntity.ok(receipt);
        } catch (RuntimeException e) {
            log.error("Error fetching receipt for payment {}: {}", paymentId, e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("paymentId", paymentId.toString());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @GetMapping("/transaction/{transactionId}")
    public ResponseEntity<?> getReceiptByTransactionId(@PathVariable String transactionId) {
        try {
            log.info("GET /api/receipts/transaction/{} - Fetching receipt", transactionId);
            ReceiptDTO receipt = receiptService.getReceiptByTransactionId(transactionId);
            return ResponseEntity.ok(receipt);
        } catch (RuntimeException e) {
            log.error("Error fetching receipt for transaction {}: {}", transactionId, e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("transactionId", transactionId);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping("/generate/{paymentId}")
    public ResponseEntity<?> generateReceipt(@PathVariable Long paymentId) {
        try {
            log.info("POST /api/receipts/generate/{} - Generating receipt", paymentId);
            ReceiptDTO receipt = receiptService.generateReceipt(paymentId);
            return ResponseEntity.ok(receipt);
        } catch (RuntimeException e) {
            log.error("Error generating receipt for payment {}: {}", paymentId, e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("paymentId", paymentId.toString());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }
}

