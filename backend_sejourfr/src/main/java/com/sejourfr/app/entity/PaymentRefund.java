package com.sejourfr.app.entity;

import com.sejourfr.app.enums.SubscriptionSource;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * Un remboursement, eventuellement partiel ({@code payment_refunds}, V074).
 * Plusieurs lignes par achat possibles ; idempotence par
 * {@code (provider, provider_refund_id)}.
 *
 * <p>{@code netExVatDeltaCents} (&le; 0) est fige a l'ecriture par les regles
 * de revenus en vigueur : Stripe garde ses frais (delta = −HT du rembourse),
 * un store rend sa part (delta = −net HT au prorata). {@code null} = achat dont
 * la decomposition est inconnue.
 */
@Entity
@Table(name = "payment_refunds")
@Getter
@Setter
public class PaymentRefund {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "subscription_id", nullable = false, columnDefinition = "uuid")
    private UUID subscriptionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "provider", nullable = false, length = 16)
    private SubscriptionSource provider;

    @Column(name = "provider_refund_id", nullable = false, length = 255)
    private String providerRefundId;

    @Column(name = "refunded_amount_cents", nullable = false)
    private int refundedAmountCents;

    @Column(name = "currency", nullable = false, length = 3)
    private String currency;

    @Column(name = "refunded_eur_cents")
    private Integer refundedEurCents;

    @Column(name = "net_ex_vat_delta_cents")
    private Integer netExVatDeltaCents;

    @Column(name = "revenue_rules_version")
    private Integer revenueRulesVersion;

    @Column(name = "refunded_at", nullable = false)
    private Instant refundedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
