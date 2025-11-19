package io.audira.commerce.controller;

import io.audira.commerce.dto.PurchasedItemDTO;
import io.audira.commerce.dto.UserLibraryDTO;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.service.LibraryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/library")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class LibraryController {

    private final LibraryService libraryService;

    /**
     * Get user's complete library organized by type
     * GET /api/library/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<UserLibraryDTO> getUserLibrary(@PathVariable Long userId) {
        log.info("Request to get library for user: {}", userId);

        UserLibraryDTO library = libraryService.getUserLibrary(userId);
        return ResponseEntity.ok(library);
    }

    /**
     * Get all purchased items for a user (flat list)
     * GET /api/library/user/{userId}/items
     */
    @GetMapping("/user/{userId}/items")
    public ResponseEntity<List<PurchasedItemDTO>> getAllPurchasedItems(@PathVariable Long userId) {
        log.info("Request to get all purchased items for user: {}", userId);

        List<PurchasedItemDTO> items = libraryService.getAllPurchasedItems(userId);
        return ResponseEntity.ok(items);
    }

    /**
     * Get purchased items of a specific type
     * GET /api/library/user/{userId}/items/{itemType}
     */
    @GetMapping("/user/{userId}/items/{itemType}")
    public ResponseEntity<List<PurchasedItemDTO>> getPurchasedItemsByType(
            @PathVariable Long userId,
            @PathVariable ItemType itemType) {
        log.info("Request to get purchased {} for user: {}", itemType, userId);

        List<PurchasedItemDTO> items = libraryService.getPurchasedItemsByType(userId, itemType);
        return ResponseEntity.ok(items);
    }

    /**
     * Check if user has purchased a specific item
     * GET /api/library/user/{userId}/check/{itemType}/{itemId}
     */
    @GetMapping("/user/{userId}/check/{itemType}/{itemId}")
    public ResponseEntity<Boolean> checkIfPurchased(
            @PathVariable Long userId,
            @PathVariable ItemType itemType,
            @PathVariable Long itemId) {
        log.info("Checking if user {} has purchased {}/{}", userId, itemType, itemId);

        boolean purchased = libraryService.hasUserPurchasedItem(userId, itemType, itemId);
        return ResponseEntity.ok(purchased);
    }

    /**
     * Clear user library (for testing/admin purposes)
     * DELETE /api/library/user/{userId}
     */
    @DeleteMapping("/user/{userId}")
    public ResponseEntity<Void> clearUserLibrary(@PathVariable Long userId) {
        log.warn("Request to clear library for user: {}", userId);

        libraryService.clearUserLibrary(userId);
        return ResponseEntity.noContent().build();
    }
}
