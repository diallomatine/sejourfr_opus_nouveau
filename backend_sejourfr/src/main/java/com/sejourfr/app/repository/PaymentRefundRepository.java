package com.sejourfr.app.repository;

import com.sejourfr.app.entity.PaymentRefund;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface PaymentRefundRepository extends JpaRepository<PaymentRefund, UUID> {

    List<PaymentRefund> findBySubscriptionId(UUID subscriptionId);

    /**
     * Insere le remboursement, ou ne fait rien si {@code (provider,
     * provider_refund_id)} existe deja (controle A de la passe Suivi).
     *
     * <p>Native pour le {@code ON CONFLICT DO NOTHING} : l'idempotence est
     * atomique et ne leve jamais. Le « lire puis inserer » d'avant laissait deux
     * livraisons concurrentes passer le controle ; la seconde echouait au commit
     * sur l'unicite et emportait avec elle le retrait d'acces de sa transaction.
     * Executee immediatement (pas au flush du commit) : une concurrente attend
     * ici la fin de la premiere, puis rend 0.
     *
     * <p>🛑 Pas de {@code clearAutomatically} : la souscription en cours de
     * traitement doit rester attachee.
     *
     * @return 1 si la ligne vient d'etre ecrite, 0 sur un rejeu
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            INSERT INTO payment_refunds (id, subscription_id, provider, provider_refund_id,
                                         refunded_amount_cents, currency, refunded_eur_cents,
                                         net_ex_vat_delta_cents, revenue_rules_version,
                                         refunded_at, created_at)
            VALUES (:id, :subscriptionId, :provider, :providerRefundId, :amount, :currency,
                    :eurCents, :delta, :rulesVersion, :refundedAt, :createdAt)
            ON CONFLICT (provider, provider_refund_id) DO NOTHING
            """, nativeQuery = true)
    int insertIfAbsent(@Param("id") UUID id,
                       @Param("subscriptionId") UUID subscriptionId,
                       @Param("provider") String provider,
                       @Param("providerRefundId") String providerRefundId,
                       @Param("amount") int amount,
                       @Param("currency") String currency,
                       @Param("eurCents") Integer eurCents,
                       @Param("delta") Integer delta,
                       @Param("rulesVersion") Integer rulesVersion,
                       @Param("refundedAt") Instant refundedAt,
                       @Param("createdAt") Instant createdAt);

    /**
     * Cumul deja enregistre sur un achat pour les identifiants qui commencent
     * par {@code prefix} — sert au cumul d'UNE charge Stripe
     * ({@code <charge>:<cumul>}) : une ligne de litige ({@code dispute:…})
     * n'entre pas dans le {@code amount_refunded} de Stripe et ne doit pas en
     * etre retranchee.
     */
    @Query(value = """
            SELECT COALESCE(SUM(refunded_amount_cents), 0) FROM payment_refunds
            WHERE subscription_id = :subscriptionId
              AND starts_with(provider_refund_id, :prefix)
            """, nativeQuery = true)
    long sumRefundedAmountWithPrefix(@Param("subscriptionId") UUID subscriptionId,
                                     @Param("prefix") String prefix);
}
