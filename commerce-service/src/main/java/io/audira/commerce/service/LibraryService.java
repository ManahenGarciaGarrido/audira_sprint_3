package io.audira.commerce.service;

import io.audira.commerce.dto.PurchasedItemDTO;
import io.audira.commerce.dto.UserLibraryDTO;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.PurchasedItem;
import io.audira.commerce.repository.PurchasedItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LibraryService {

    private final PurchasedItemRepository purchasedItemRepository;

    /**
     * Get user's complete library organized by item type
     */
    @Transactional(readOnly = true)
    public UserLibraryDTO getUserLibrary(Long userId) {
        log.info("Getting library for user: {}", userId);

        List<PurchasedItem> allItems = purchasedItemRepository.findByUserId(userId);
        UserLibraryDTO library = new UserLibraryDTO(userId);

        for (PurchasedItem item : allItems) {
            PurchasedItemDTO dto = PurchasedItemDTO.fromEntity(item);

            switch (item.getItemType()) {
                case SONG:
                    library.addSong(dto);
                    break;
                case ALBUM:
                    library.addAlbum(dto);
                    break;
                case MERCHANDISE:
                    library.addMerchandise(dto);
                    break;
            }
        }

        log.info("Found {} items in library for user {}", library.getTotalItems(), userId);
        return library;
    }

    /**
     * Get all purchased items for a user
     */
    @Transactional(readOnly = true)
    public List<PurchasedItemDTO> getAllPurchasedItems(Long userId) {
        log.info("Getting all purchased items for user: {}", userId);

        return purchasedItemRepository.findByUserId(userId)
            .stream()
            .map(PurchasedItemDTO::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Get purchased items of a specific type
     */
    @Transactional(readOnly = true)
    public List<PurchasedItemDTO> getPurchasedItemsByType(Long userId, ItemType itemType) {
        log.info("Getting purchased {} for user: {}", itemType, userId);

        return purchasedItemRepository.findByUserIdAndItemType(userId, itemType)
            .stream()
            .map(PurchasedItemDTO::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Check if user has purchased a specific item
     */
    @Transactional(readOnly = true)
    public boolean hasUserPurchasedItem(Long userId, ItemType itemType, Long itemId) {
        boolean purchased = purchasedItemRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId);
        log.debug("User {} {} purchased {}/{}", userId, purchased ? "has" : "has not", itemType, itemId);
        return purchased;
    }

    /**
     * Add items from a completed order to user's library
     * This should be called when a payment is completed successfully
     */
    @Transactional
    public void addOrderToLibrary(Order order, Long paymentId) {
        log.info("Adding order {} items to library for user {}", order.getId(), order.getUserId());

        for (OrderItem orderItem : order.getItems()) {
            // Check if already exists (avoid duplicates)
            boolean exists = purchasedItemRepository.existsByUserIdAndItemTypeAndItemId(
                order.getUserId(),
                orderItem.getItemType(),
                orderItem.getItemId()
            );

            if (!exists) {
                PurchasedItem purchasedItem = new PurchasedItem(
                    order.getUserId(),
                    orderItem.getItemType(),
                    orderItem.getItemId(),
                    order.getId(),
                    paymentId,
                    orderItem.getPrice(),
                    orderItem.getQuantity()
                );

                purchasedItemRepository.save(purchasedItem);
                log.info("Added {} {} to library for user {}",
                    orderItem.getItemType(), orderItem.getItemId(), order.getUserId());
            } else {
                log.debug("Item {}/{} already in library for user {}",
                    orderItem.getItemType(), orderItem.getItemId(), order.getUserId());
            }
        }

        log.info("Finished adding order {} to library", order.getId());
    }

    /**
     * Delete all library items for a user (admin/testing purposes)
     */
    @Transactional
    public void clearUserLibrary(Long userId) {
        log.warn("Clearing all library items for user: {}", userId);
        purchasedItemRepository.deleteByUserId(userId);
    }
}
