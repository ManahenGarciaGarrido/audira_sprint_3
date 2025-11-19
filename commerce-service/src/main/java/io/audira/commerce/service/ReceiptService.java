package io.audira.commerce.service;

import io.audira.commerce.client.UserClient;
import io.audira.commerce.dto.*;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.Payment;
import io.audira.commerce.model.PaymentStatus;
import io.audira.commerce.repository.OrderRepository;
import io.audira.commerce.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final OrderService orderService;
    private final UserClient userClient;

    public ReceiptDTO generateReceipt(Long paymentId) {
        log.info("=== Generating receipt for payment ID: {} ===", paymentId);

        // Find payment with detailed logging
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> {
                    log.error("Payment not found with ID: {}", paymentId);
                    return new RuntimeException("Payment not found with ID: " + paymentId);
                });

        log.info("Payment found: transactionId={}, orderId={}, userId={}, status={}",
                payment.getTransactionId(), payment.getOrderId(), payment.getUserId(), payment.getStatus());

        // Verify payment is completed - receipts can only be generated for completed payments
        if (payment.getStatus() != PaymentStatus.COMPLETED) {
            log.warn("Cannot generate receipt for payment {} with status: {}. Only COMPLETED payments can have receipts.",
                    paymentId, payment.getStatus());
            throw new RuntimeException("Receipt can only be generated for completed payments. Current payment status: " +
                    payment.getStatus());
        }

        // Find order with detailed logging
        Order order = orderRepository.findById(payment.getOrderId())
                .orElseThrow(() -> {
                    log.error("Order not found with ID: {} for payment: {}", payment.getOrderId(), paymentId);
                    return new RuntimeException("Order not found with ID: " + payment.getOrderId());
                });

        log.info("Order found: orderNumber={}, userId={}, itemsCount={}, totalAmount={}",
                order.getOrderNumber(), order.getUserId(), order.getItems().size(), order.getTotalAmount());

        // Generate receipt number
        String receiptNumber = "RCP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // Calculate tax (10% for example)
        BigDecimal subtotal = order.getTotalAmount();
        BigDecimal taxRate = new BigDecimal("0.10");
        BigDecimal tax = subtotal.multiply(taxRate);
        BigDecimal total = subtotal.add(tax);

        // Map order items to receipt items
        List<ReceiptItemDTO> items = order.getItems().stream()
                .map(this::mapToReceiptItem)
                .collect(Collectors.toList());

        log.info("Mapped {} order items to receipt items", items.size());

        PaymentDTO paymentDTO = paymentService.getPaymentById(paymentId);
        OrderDTO orderDTO = orderService.getOrderById(order.getId());

        // Fetch real user information
        UserDTO user = userClient.getUserById(order.getUserId());
        String customerName = user.getFirstName() + " " + user.getLastName();
        String customerEmail = user.getEmail();

        log.info("Customer information: name={}, email={}", customerName, customerEmail);

        ReceiptDTO receipt = ReceiptDTO.builder()
                .receiptNumber(receiptNumber)
                .payment(paymentDTO)
                .order(orderDTO)
                .customerName(customerName)
                .customerEmail(customerEmail)
                .subtotal(subtotal)
                .tax(tax)
                .total(total)
                .issuedAt(LocalDateTime.now())
                .items(items)
                .build();

        log.info("=== Receipt generated successfully: {} ===", receiptNumber);
        return receipt;
    }

    public ReceiptDTO getReceiptByPaymentId(Long paymentId) {
        return generateReceipt(paymentId);
    }

    public ReceiptDTO getReceiptByTransactionId(String transactionId) {
        Payment payment = paymentRepository.findByTransactionId(transactionId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return generateReceipt(payment.getId());
    }

    private ReceiptItemDTO mapToReceiptItem(OrderItem item) {
        BigDecimal totalPrice = item.getPrice().multiply(new BigDecimal(item.getQuantity()));

        return ReceiptItemDTO.builder()
                .itemName(getItemName(item))
                .itemType(item.getItemType().toString())
                .quantity(item.getQuantity())
                .unitPrice(item.getPrice())
                .totalPrice(totalPrice)
                .build();
    }

    private String getItemName(OrderItem item) {
        // In a real application, you would fetch the actual item name from the respective service
        return item.getItemType() + " #" + item.getItemId();
    }
}

