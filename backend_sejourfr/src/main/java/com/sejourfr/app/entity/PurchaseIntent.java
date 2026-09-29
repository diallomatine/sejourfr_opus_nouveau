package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AnalyticsCtaLocation;
import com.sejourfr.app.enums.ClientPlatform;
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
 * Intention d'achat posee cote serveur avant CHAQUE demarrage d'achat
 * ({@code purchase_intent}, V074, arbitrage Q12). Usage unique, TTL en config.
 *
 * <p>Transport : {@code metadata.intentId} de la Checkout Session (Stripe), ou
 * {@code purchaseIntentId} renvoye par le mobile avec verify-receipt
 * (Apple/Google). 🛑 Jamais {@code appAccountToken} ni
 * {@code obfuscatedAccountId/ProfileId} : ils portent l'identite du compte.
 *
 * <p>{@code diagnosticRunId} est RESOLU SERVEUR depuis le parcours (Q8), jamais
 * recu du client.
 */
@Entity
@Table(name = "purchase_intent")
@Getter
@Setter
public class PurchaseIntent {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "cta_location", nullable = false, length = 32)
    private AnalyticsCtaLocation ctaLocation;

    /** {@code plans.code} du pass vise. */
    @Column(name = "product_id", nullable = false, length = 128)
    private String productId;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", length = 16)
    private ClientPlatform platform;

    @Column(name = "journey_id", columnDefinition = "uuid")
    private UUID journeyId;

    @Column(name = "diagnostic_run_id", columnDefinition = "uuid")
    private UUID diagnosticRunId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "consumed_at")
    private Instant consumedAt;
}
