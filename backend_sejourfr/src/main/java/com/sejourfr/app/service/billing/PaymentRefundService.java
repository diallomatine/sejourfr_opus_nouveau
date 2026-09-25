package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.PaymentRefund;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.manager.PaymentRefundManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.Locale;
import java.util.UUID;

/**
 * Ecrit les remboursements des trois canaux dans {@code payment_refunds}
 * (brief §6.4) — autorite unique de cette table.
 *
 * <p><b>Idempotence</b> : {@code (provider, provider_refund_id)} unique ; un
 * webhook rejoue, ou deux notifications distinctes du meme remboursement,
 * n'ecrivent qu'une ligne. Plusieurs remboursements PARTIELS d'un meme achat
 * donnent plusieurs lignes.
 *
 * <p><b>Montants</b> : dans la devise de l'achat, convertis en euros au taux
 * FIGE sur la ligne d'achat (jamais au taux du jour). Le delta de net HT se
 * fige avec les regles de revenus en vigueur ; il reste {@code null} quand
 * la decomposition de l'achat est inconnue (achat anterieur a la mesure) —
 * un inconnu ne devient jamais un zero.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentRefundService {

    private final PaymentRefundManager paymentRefundManager;
    private final RevenueCalculator revenueCalculator;

    /** Total deja enregistre comme rembourse sur cet achat, dans sa devise. */
    @Transactional(readOnly = true)
    public long dejaRembourse(UserSubscription sub) {
        return sub.getId() == null ? 0 : paymentRefundManager.sumRefundedAmount(sub.getId());
    }

    /**
     * @param refundedAmountCents montant rendu, dans la devise {@code currency}
     * @return {@code true} si une ligne a ete ecrite, {@code false} pour un
     *         rejeu ou un montant inexploitable
     */
    @Transactional
    public boolean enregistrer(UserSubscription sub, String providerRefundId,
                               long refundedAmountCents, String currency, Instant refundedAt) {
        SubscriptionSource provider = sub.getSource();
        if (providerRefundId == null || providerRefundId.isBlank() || refundedAmountCents <= 0
                || refundedAmountCents > Integer.MAX_VALUE) {
            log.info("Remboursement {} sans identifiant ou montant exploitable (achat={}) : non ecrit.",
                    provider, sub.getId());
            return false;
        }
        String devise = devise(currency, sub.getCurrency());
        if (devise == null) {
            log.info("Remboursement {} {} sans devise connue (achat={}) : non ecrit.",
                    provider, providerRefundId, sub.getId());
            return false;
        }
        if (paymentRefundManager.exists(provider, providerRefundId)) {
            log.debug("Remboursement {} {} deja enregistre — rejeu.", provider, providerRefundId);
            return false;
        }
        Integer refundedEur = enEuros((int) refundedAmountCents, devise, sub);
        Integer delta = deltaNet(sub, refundedEur);

        PaymentRefund refund = new PaymentRefund();
        refund.setId(UUID.randomUUID());
        refund.setSubscriptionId(sub.getId());
        refund.setProvider(provider);
        refund.setProviderRefundId(providerRefundId);
        refund.setRefundedAmountCents((int) refundedAmountCents);
        refund.setCurrency(devise);
        refund.setRefundedEurCents(refundedEur);
        refund.setNetExVatDeltaCents(delta);
        refund.setRevenueRulesVersion(delta == null ? null : revenueCalculator.rulesVersion());
        refund.setRefundedAt(refundedAt != null ? refundedAt : Instant.now());
        refund.setCreatedAt(Instant.now());
        paymentRefundManager.save(refund);
        log.info("Remboursement {} enregistre achat={} montant={} {} deltaNet={}",
                provider, sub.getId(), refundedAmountCents, devise, delta);
        return true;
    }

    private Integer deltaNet(UserSubscription sub, Integer refundedEur) {
        if (refundedEur == null || sub.getNetExVatCents() == null || sub.getAmountEurCents() == null) {
            return null;
        }
        return switch (sub.getSource()) {
            case STRIPE -> revenueCalculator.deltaRemboursementStripe(refundedEur);
            case APPLE, GOOGLE -> revenueCalculator.deltaRemboursementStore(
                    sub.getNetExVatCents(), sub.getAmountEurCents(), refundedEur);
        };
    }

    /** Au taux fige de l'achat, et seulement dans la devise de l'achat. */
    private static Integer enEuros(int cents, String devise, UserSubscription sub) {
        if (sub.getCurrency() == null || !sub.getCurrency().equalsIgnoreCase(devise)
                || sub.getFxRateToEur() == null) {
            return null;
        }
        return BigDecimal.valueOf(cents).multiply(sub.getFxRateToEur())
                .setScale(0, RoundingMode.HALF_UP).intValueExact();
    }

    private static String devise(String declared, String ofPurchase) {
        String raw = (declared != null && !declared.isBlank()) ? declared : ofPurchase;
        if (raw == null || raw.isBlank()) return null;
        String d = raw.trim().toUpperCase(Locale.ROOT);
        return d.matches("^[A-Z]{3}$") ? d : null;
    }
}
