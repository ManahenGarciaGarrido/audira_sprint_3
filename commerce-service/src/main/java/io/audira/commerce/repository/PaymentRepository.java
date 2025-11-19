package io.audira.commerce.repository;

import io.audira.commerce.model.Payment;
import io.audira.commerce.model.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByTransactionId(String transactionId);

    List<Payment> findByUserId(Long userId);

    List<Payment> findByOrderId(Long orderId);

    List<Payment> findByUserIdAndStatus(Long userId, PaymentStatus status);

    List<Payment> findByStatus(PaymentStatus status);
}
