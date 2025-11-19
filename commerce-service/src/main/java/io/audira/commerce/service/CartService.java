package io.audira.commerce.service;

import io.audira.commerce.dto.CartDTO;
import io.audira.commerce.dto.CartItemDTO;
import io.audira.commerce.model.Cart;
import io.audira.commerce.model.CartItem;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.repository.CartRepository;
import io.audira.commerce.repository.CartItemRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final EntityManager entityManager;

    /**
     * Get or create cart for a user
     */
    @Transactional
    public CartDTO getCartByUserId(Long userId) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> createNewCart(userId));
        return mapToDTO(cart);
    }

    /**
     * Add item to cart
     */
    @Transactional
    public CartDTO addItemToCart(Long userId, ItemType itemType, Long itemId, BigDecimal price, Integer quantity) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> createNewCart(userId));

        // Check if item already exists in cart
        CartItem existingItem = cartItemRepository
                .findByCartIdAndItemTypeAndItemId(cart.getId(), itemType, itemId)
                .orElse(null);

        if (existingItem != null) {
            // For digital products (SONG, ALBUM), don't allow duplicates
            if (itemType == ItemType.SONG || itemType == ItemType.ALBUM) {
                throw new RuntimeException("Item already exists in cart. Digital products cannot be added more than once.");
            }
            // For physical products, update quantity
            existingItem.setQuantity(existingItem.getQuantity() + quantity);
            cartItemRepository.save(existingItem);
        } else {
            // Create new cart item
            CartItem newItem = CartItem.builder()
                    .cartId(cart.getId())
                    .itemType(itemType)
                    .itemId(itemId)
                    .quantity(quantity)
                    .price(price)
                    .build();
            cartItemRepository.save(newItem);
        }

        // Reload cart with updated items and recalculate total
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.calculateTotalAmount();
        cart = cartRepository.save(cart);

        return mapToDTO(cart);
    }

    /**
     * Update cart item quantity
     */
    @Transactional
    public CartDTO updateCartItemQuantity(Long userId, Long itemId, Integer quantity) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found for user: " + userId));

        CartItem cartItem = cartItemRepository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("Cart item not found: " + itemId));

        if (!cartItem.getCartId().equals(cart.getId())) {
            throw new RuntimeException("Cart item does not belong to user's cart");
        }

        if (quantity <= 0) {
            cartItemRepository.delete(cartItem);
        } else {
            cartItem.setQuantity(quantity);
            cartItemRepository.save(cartItem);
        }

        // Reload cart with updated items and recalculate total
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.calculateTotalAmount();
        cart = cartRepository.save(cart);

        return mapToDTO(cart);
    }

    /**
     * Remove item from cart
     */
    @Transactional
    public CartDTO removeItemFromCart(Long userId, Long itemId) {
        System.out.println("=== removeItemFromCart called - userId: " + userId + ", itemId: " + itemId);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found for user: " + userId));

        System.out.println("Cart found - cartId: " + cart.getId() + ", current items count: " + cart.getItems().size());

        // Verify the item exists and belongs to this cart
        CartItem cartItem = cartItemRepository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("Cart item not found: " + itemId));

        System.out.println("CartItem found - itemId: " + cartItem.getId() + ", cartId: " + cartItem.getCartId());

        if (!cartItem.getCartId().equals(cart.getId())) {
            throw new RuntimeException("Cart item does not belong to user's cart");
        }

        // Delete using custom query to force immediate execution
        System.out.println("Deleting cart item with custom query...");
        int deletedCount = cartItemRepository.deleteCartItemById(itemId);
        System.out.println("Cart item deleted - deleted count: " + deletedCount);

        // Clear the entity manager to remove all cached entities
        entityManager.clear();
        System.out.println("Entity manager cleared");

        // Reload cart with completely fresh data from database
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));

        System.out.println("Cart reloaded - items count after deletion: " + cart.getItems().size());

        // Recalculate total amount
        cart.calculateTotalAmount();
        cart = cartRepository.save(cart);

        System.out.println("Cart saved - final items count: " + cart.getItems().size());

        CartDTO dto = mapToDTO(cart);
        System.out.println("DTO created - items count in DTO: " + dto.getItems().size());

        return dto;
    }

    /**
     * Clear cart (remove all items)
     */
    @Transactional
    public void clearCart(Long userId) {
        System.out.println("=== CartService.clearCart called - userId: " + userId);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found for user: " + userId));

        System.out.println("Cart found - cartId: " + cart.getId() + ", items count: " + cart.getItems().size());

        int deletedCount = cartItemRepository.deleteByCartId(cart.getId());
        System.out.println("Cart items deleted - count: " + deletedCount);

        // Clear entity manager to ensure changes are reflected
        entityManager.clear();

        // Recalculate total amount
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.calculateTotalAmount();
        cartRepository.save(cart);

        System.out.println("=== Cart cleared successfully - userId: " + userId);
    }

    /**
     * Get cart item count
     */
    public Integer getCartItemCount(Long userId) {
        Cart cart = cartRepository.findByUserId(userId).orElse(null);
        if (cart == null) {
            return 0;
        }
        return cart.getTotalItems();
    }

    /**
     * Create a new cart for a user
     */
    private Cart createNewCart(Long userId) {
        Cart cart = Cart.builder()
                .userId(userId)
                .totalAmount(BigDecimal.ZERO)
                .build();
        return cartRepository.save(cart);
    }

    /**
     * Map Cart entity to CartDTO
     */
    private CartDTO mapToDTO(Cart cart) {
        List<CartItemDTO> itemDTOs = cart.getItems().stream()
                .map(item -> CartItemDTO.builder()
                        .id(item.getId())
                        .cartId(item.getCartId())
                        .itemType(item.getItemType())
                        .itemId(item.getItemId())
                        .quantity(item.getQuantity())
                        .price(item.getPrice())
                        .build())
                .collect(Collectors.toList());

        return CartDTO.builder()
                .id(cart.getId())
                .userId(cart.getUserId())
                .items(itemDTOs)
                .totalAmount(cart.getTotalAmount())
                .createdAt(cart.getCreatedAt())
                .updatedAt(cart.getUpdatedAt())
                .build();
    }
}
