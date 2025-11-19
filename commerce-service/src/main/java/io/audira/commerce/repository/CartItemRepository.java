package io.audira.commerce.repository;

import io.audira.commerce.model.CartItem;
import io.audira.commerce.model.ItemType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    List<CartItem> findByCartId(Long cartId);

    Optional<CartItem> findByCartIdAndItemTypeAndItemId(Long cartId, ItemType itemType, Long itemId);

    @Modifying
    @Query("DELETE FROM CartItem ci WHERE ci.cartId = :cartId")
    int deleteByCartId(@Param("cartId") Long cartId);

    @Modifying
    @Query("DELETE FROM CartItem ci WHERE ci.id = :itemId")
    int deleteCartItemById(@Param("itemId") Long itemId);
}
