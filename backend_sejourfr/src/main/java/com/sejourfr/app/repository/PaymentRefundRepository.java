package com.sejourfr.app.repository;

import com.sejourfr.app.entity.PaymentRefund;
import com.sejourfr.app.enums.SubscriptionSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface PaymentRefundRepository extends JpaRepository<PaymentRefund, UUID> {

    boolean existsByProviderAndProviderRefundId(SubscriptionSource provider, String providerRefundId);

    List<PaymentRefund> findBySubscriptionId(UUID subscriptionId);

    /** Total deja rembourse sur un achat, dans sa devise. */
    @Query("SELECT COALESCE(SUM(r.refundedAmountCents), 0) FROM PaymentRefund r "
            + "WHERE r.subscriptionId = :subscriptionId")
    long sumRefundedAmount(@Param("subscriptionId") UUID subscriptionId);
}
