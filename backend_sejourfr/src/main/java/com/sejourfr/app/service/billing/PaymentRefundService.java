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
 * <p><b>Idempotence</b> : {@code (provider, provider_refund_id)} unique, et
 * l'ecriture est un {@code INSERT … ON CONFLICT DO NOTHING} execute
 * immediatement (controle A) : un webhook rejoue, deux notifications
 * distinctes du meme remboursement, ou deux livraisons CONCURRENTES n'ecrivent
 * qu'une ligne, et aucune ne fait echouer sa transaction. Plusieurs
 * remboursements PARTIELS d'un meme achat donnent plusieurs lignes.
 *
 * <p><b>Ne fait jamais tomber le retrait d'acces</b> : les appelants posent
 * d'abord l'etat d'acces, puis appellent ce service. Le calcul (conversion,
 * delta de net) est du Java pur garde : s'il leve, la ligne s'ecrit avec un
 * equivalent euros et un delta {@code null} (inconnu). Les valeurs ecrites
 * respectent les CHECK de V074 par construction (montant &gt; 0, delta &le; 0,
 * delta et version nuls ensemble).
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

    /** Prefixe des lignes de litige Stripe perdu : hors cumul {@code amount_refunded}. */
    static final String PREFIXE_LITIGE = "dispute:";

    private final PaymentRefundManager paymentRefundManager;
    private final RevenueCalculator revenueCalculator;

    /**
     * Remboursement Stripe connu par son CUMUL sur une charge
     * ({@code charge.amount_refunded}) : ecrit la difference avec ce qui est
     * deja enregistre pour cette charge, sous l'identifiant
     * {@code <charge>:<cumul>} (D35). Un etat rejoue retombe sur le meme
     * identifiant ou sur une difference nulle, et n'ecrit rien.
     *
     * <p>🛑 L'appelant a verrouille la ligne d'achat
     * ({@code UserSubscriptionManager.verrouiller}) : deux cumuls differents
     * traites en parallele liraient sinon le meme « deja rembourse » et
     * compteraient deux fois la meme somme.
     */
    @Transactional
    public boolean enregistrerCumulStripe(UserSubscription sub, String chargeId, long cumul,
                                          String currency, Instant refundedAt) {
        if (sub.getId() == null || chargeId == null || chargeId.isBlank() || cumul <= 0) {
            return false;
        }
        String prefixe = chargeId + ":";
        long nouveau = cumul - paymentRefundManager.sumRefundedAmountWithPrefix(sub.getId(), prefixe);
        if (nouveau <= 0) {
            log.debug("Remboursement Stripe {}{} deja couvert — rien a ecrire.", prefixe, cumul);
            return false;
        }
        return enregistrer(sub, prefixe + cumul, nouveau, currency, refundedAt);
    }

    /**
     * @param refundedAmountCents montant rendu, dans la devise {@code currency}
     * @return {@code true} si une ligne a ete ecrite, {@code false} pour un
     *         rejeu ou un montant inexploitable
     */
    @Transactional
    public boolean enregistrer(UserSubscription sub, String providerRefundId,
                               long refundedAmountCents, String currency, Instant refundedAt) {
        return ecrire(sub, providerRefundId, refundedAmountCents, currency, refundedAt, FraisEnSus.AUCUN);
    }

    /**
     * Litige Stripe PERDU (controle N6) : le montant conteste quitte le compte
     * comme un remboursement, sous l'identifiant {@code dispute:<id>}.
     *
     * <p>Le delta de net porte AUSSI les frais de litige preleves par Stripe
     * ({@code fraisLitigeEurCents}, lus sur les balance transactions du
     * litige) : c'est une perte reelle de l'achat. Frais illisibles
     * ({@code null}) ⇒ delta {@code null} — inconnu plutot que faux.
     */
    @Transactional
    public boolean enregistrerLitigePerdu(UserSubscription sub, String disputeId, long montantConteste,
                                          String currency, Instant closedAt, Integer fraisLitigeEurCents) {
        if (disputeId == null || disputeId.isBlank()) return false;
        return ecrire(sub, PREFIXE_LITIGE + disputeId, montantConteste, currency, closedAt,
                new FraisEnSus(true, fraisLitigeEurCents));
    }

    private boolean ecrire(UserSubscription sub, String providerRefundId, long refundedAmountCents,
                           String currency, Instant refundedAt, FraisEnSus frais) {
        SubscriptionSource provider = sub.getSource();
        if (sub.getId() == null || providerRefundId == null || providerRefundId.isBlank()
                || refundedAmountCents <= 0 || refundedAmountCents > Integer.MAX_VALUE) {
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
        Integer refundedEur = null;
        Integer delta = null;
        try {
            refundedEur = enEuros((int) refundedAmountCents, devise, sub);
            delta = frais.appliquer(deltaNet(sub, refundedEur));
        } catch (RuntimeException e) {
            // Java pur, aucun appel base : l'ecriture reste possible, le chiffre
            // devient inconnu plutot que de faire tomber la transaction.
            log.warn("Remboursement {} {} (achat={}) : calcul du montant en euros ou du delta en echec, "
                    + "ecrit avec un effet inconnu ({}).", provider, providerRefundId, sub.getId(),
                    e.toString());
            refundedEur = null;
            delta = null;
        }
        if (delta != null && delta > 0) {
            log.warn("Remboursement {} {} : delta positif {} refuse, inconnu.", provider, providerRefundId, delta);
            delta = null;
        }

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
        if (!paymentRefundManager.insertIfAbsent(refund)) {
            log.debug("Remboursement {} {} deja enregistre — rejeu.", provider, providerRefundId);
            return false;
        }
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

    /**
     * Frais preleves EN PLUS du montant rendu (litige). {@code requis} sans
     * montant connu rend le delta inconnu.
     */
    private record FraisEnSus(boolean requis, Integer eurCents) {

        static final FraisEnSus AUCUN = new FraisEnSus(false, null);

        Integer appliquer(Integer delta) {
            if (!requis || delta == null) return delta;
            if (eurCents == null || eurCents < 0) return null;
            return Math.subtractExact(delta, eurCents);
        }
    }
}
