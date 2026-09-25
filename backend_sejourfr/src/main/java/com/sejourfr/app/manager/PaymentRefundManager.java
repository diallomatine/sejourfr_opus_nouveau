package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PaymentRefund;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.repository.PaymentRefundRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link PaymentRefundRepository}. */
@Component
@RequiredArgsConstructor
public class PaymentRefundManager {

    private final PaymentRefundRepository repository;

    public boolean exists(SubscriptionSource provider, String providerRefundId) {
        return repository.existsByProviderAndProviderRefundId(provider, providerRefundId);
    }

    public long sumRefundedAmount(UUID subscriptionId) {
        return repository.sumRefundedAmount(subscriptionId);
    }

    public List<PaymentRefund> findBySubscriptionId(UUID subscriptionId) {
        return repository.findBySubscriptionId(subscriptionId);
    }

    public PaymentRefund save(PaymentRefund refund) {
        return repository.save(refund);
    }
}
