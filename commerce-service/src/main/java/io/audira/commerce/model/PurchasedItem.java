package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "purchased_items", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "item_type", "item_id"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PurchasedItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "item_type", nullable = false)
    private ItemType itemType;

    @Column(name = "item_id", nullable = false)
    private Long itemId;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "payment_id", nullable = false)
    private Long paymentId;

    @Column(precision = 10, scale = 2, nullable = false)
    private BigDecimal price;

    @Column(nullable = false)
    private Integer quantity;

    @CreationTimestamp
    @Column(name = "purchased_at", nullable = false, updatable = false)
    private LocalDateTime purchasedAt;

    public PurchasedItem(Long userId, ItemType itemType, Long itemId, Long orderId, Long paymentId, BigDecimal price, Integer quantity) {
        this.userId = userId;
        this.itemType = itemType;
        this.itemId = itemId;
        this.orderId = orderId;
        this.paymentId = paymentId;
        this.price = price;
        this.quantity = quantity;
    }
}
