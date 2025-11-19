package io.audira.commerce.controller;

import io.audira.commerce.dto.CartDTO;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.service.CartService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    /**
     * Get cart for a user
     */
    @GetMapping("/{userId}")
    public ResponseEntity<CartDTO> getCart(@PathVariable Long userId) {
        CartDTO cart = cartService.getCartByUserId(userId);
        return ResponseEntity.ok(cart);
    }

    /**
     * Add item to cart
     */
    @PostMapping("/{userId}/items")
    public ResponseEntity<CartDTO> addToCart(
            @PathVariable Long userId,
            @RequestParam String itemType,
            @RequestParam Long itemId,
            @RequestParam BigDecimal price,
            @RequestParam(defaultValue = "1") Integer quantity) {

        ItemType type = ItemType.valueOf(itemType);
        CartDTO cart = cartService.addItemToCart(userId, type, itemId, price, quantity);
        return ResponseEntity.ok(cart);
    }

    /**
     * Update cart item quantity
     */
    @PutMapping("/{userId}/items/{itemId}")
    public ResponseEntity<CartDTO> updateCartItem(
            @PathVariable Long userId,
            @PathVariable Long itemId,
            @RequestParam Integer quantity) {

        CartDTO cart = cartService.updateCartItemQuantity(userId, itemId, quantity);
        return ResponseEntity.ok(cart);
    }

    /**
     * Remove item from cart
     */
    @DeleteMapping("/{userId}/items/{itemId}")
    public ResponseEntity<CartDTO> removeFromCart(
            @PathVariable Long userId,
            @PathVariable Long itemId) {

        CartDTO cart = cartService.removeItemFromCart(userId, itemId);
        return ResponseEntity.ok(cart);
    }

    /**
     * Clear cart (remove all items)
     */
    @DeleteMapping("/{userId}")
    public ResponseEntity<Void> clearCart(@PathVariable Long userId) {
        cartService.clearCart(userId);
        return ResponseEntity.ok().build();
    }

    /**
     * Get cart item count
     */
    @GetMapping("/{userId}/count")
    public ResponseEntity<Integer> getCartCount(@PathVariable Long userId) {
        Integer count = cartService.getCartItemCount(userId);
        return ResponseEntity.ok(count);
    }
}
