package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PaymentRefund;
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

    /**
     * Ecrit la ligne, sauf si son identifiant provider existe deja. Ne leve
     * jamais sur un doublon, meme concurrent.
     *
     * @return {@code true} si la ligne vient d'etre ecrite
     */
    public boolean insertIfAbsent(PaymentRefund refund) {
        return repository.insertIfAbsent(refund.getId(), refund.getSubscriptionId(),
                refund.getProvider().name(), refund.getProviderRefundId(),
                refund.getRefundedAmountCents(), refund.getCurrency(), refund.getRefundedEurCents(),
                refund.getNetExVatDeltaCents(), refund.getRevenueRulesVersion(),
                refund.getRefundedAt(), refund.getCreatedAt()) > 0;
    }

    /** Cumul enregistre sur un achat pour les identifiants qui commencent par {@code prefix}. */
    public long sumRefundedAmountWithPrefix(UUID subscriptionId, String prefix) {
        return repository.sumRefundedAmountWithPrefix(subscriptionId, prefix);
    }

    public List<PaymentRefund> findBySubscriptionId(UUID subscriptionId) {
        return repository.findBySubscriptionId(subscriptionId);
    }
}
