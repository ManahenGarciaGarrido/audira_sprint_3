package io.audira.commerce.service;

import io.audira.commerce.dto.CreateOrderRequest;
import io.audira.commerce.dto.OrderDTO;
import io.audira.commerce.dto.OrderItemDTO;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.OrderStatus;
import io.audira.commerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;

    /**
     * Create a new order
     */
    @Transactional
    public OrderDTO createOrder(CreateOrderRequest request) {
        // Generate unique order number
        String orderNumber = generateOrderNumber();

        // Calculate total amount
        BigDecimal totalAmount = request.getItems().stream()
                .map(item -> item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Create order without items first to get the ID
        Order order = Order.builder()
                .userId(request.getUserId())
                .orderNumber(orderNumber)
                .items(new ArrayList<>())
                .totalAmount(totalAmount)
                .status(OrderStatus.PENDING)
                .shippingAddress(request.getShippingAddress())
                .build();

        // Save to get the order ID
        order = orderRepository.save(order);

        // Now create order items with the order ID
        final Long orderId = order.getId();
        List<OrderItem> orderItems = request.getItems().stream()
                .map(itemDTO -> OrderItem.builder()
                        .orderId(orderId)
                        .itemType(itemDTO.getItemType())
                        .itemId(itemDTO.getItemId())
                        .quantity(itemDTO.getQuantity())
                        .price(itemDTO.getPrice())
                        .build())
                .collect(Collectors.toList());

        // Add items to order and save again
        order.setItems(orderItems);
        Order savedOrder = orderRepository.save(order);

        return mapToDTO(savedOrder);
    }

    /**
     * Generate unique order number
     */
    private String generateOrderNumber() {
        String orderNumber;
        do {
            orderNumber = "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        } while (orderRepository.existsByOrderNumber(orderNumber));
        return orderNumber;
    }

    public OrderDTO getOrderById(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + orderId));
        return mapToDTO(order);
    }

    public OrderDTO getOrderByOrderNumber(String orderNumber) {
        Order order = orderRepository.findByOrderNumber(orderNumber)
                .orElseThrow(() -> new RuntimeException("Order not found with order number: " + orderNumber));
        return mapToDTO(order);
    }

    public List<OrderDTO> getAllOrders() {
        return orderRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getOrdersByUserIdAndStatus(Long userId, OrderStatus status) {
        return orderRepository.findByUserIdAndStatus(userId, status).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    private OrderDTO mapToDTO(Order order) {
        List<OrderItemDTO> itemDTOs = order.getItems().stream()
                .map(item -> OrderItemDTO.builder()
                        .id(item.getId())
                        .itemType(item.getItemType())
                        .itemId(item.getItemId())
                        .quantity(item.getQuantity())
                        .price(item.getPrice())
                        .build())
                .collect(Collectors.toList());

        return OrderDTO.builder()
                .id(order.getId())
                .userId(order.getUserId())
                .orderNumber(order.getOrderNumber())
                .items(itemDTOs)
                .totalAmount(order.getTotalAmount())
                .status(order.getStatus())
                .shippingAddress(order.getShippingAddress())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }
}
