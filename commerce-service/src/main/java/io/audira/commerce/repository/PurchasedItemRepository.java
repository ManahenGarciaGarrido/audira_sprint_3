package io.audira.commerce.repository;

import io.audira.commerce.model.ItemType;
import io.audira.commerce.model.PurchasedItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PurchasedItemRepository extends JpaRepository<PurchasedItem, Long> {

    /**
     * Find all purchased items for a specific user
     */
    List<PurchasedItem> findByUserId(Long userId);

    /**
     * Find all purchased items of a specific type for a user
     */
    List<PurchasedItem> findByUserIdAndItemType(Long userId, ItemType itemType);

    /**
     * Check if a user has purchased a specific item
     */
    boolean existsByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Find a specific purchased item
     */
    Optional<PurchasedItem> findByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Find all purchased items from a specific order
     */
    List<PurchasedItem> findByOrderId(Long orderId);

    /**
     * Find all purchased items from a specific payment
     */
    List<PurchasedItem> findByPaymentId(Long paymentId);

    /**
     * Delete all purchased items for a user (for testing/admin purposes)
     */
    void deleteByUserId(Long userId);
}
