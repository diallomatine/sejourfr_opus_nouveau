package com.sejourfr.app.entity;

import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import jakarta.persistence.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Souscription Premium d'un utilisateur. Multi-source : peut venir de Stripe
 * (web), Apple (iOS) ou Google (Android). Un même utilisateur peut avoir
 * plusieurs lignes — l'agrégateur de statut ({@code SubscriptionStatusService})
 * tranche en cas de cumul.
 *
 * <p>Clé de réconciliation des renouvellements : {@code (source,
 * originalTransactionId)}. Un webhook de renouvellement vient updater la ligne
 * existante (nouvelle {@code externalTransactionId}, {@code endsAt} repoussé),
 * il NE CRÉE PAS une nouvelle ligne. Garanti par l'index unique
 * {@code ux_user_subscriptions_source_original} (cf. migration V103).
 */
@Entity
@Table(name = "user_subscriptions")
public class UserSubscription {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "plan_id", nullable = false)
    private Plan plan;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private SubscriptionStatus status;

    @Column(name = "starts_at", nullable = false)
    private Instant startsAt;

    @Column(name = "ends_at")
    private Instant endsAt;

    /** D'où vient cette souscription. Pose la convention de lecture des champs ci-dessous. */
    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 16)
    private SubscriptionSource source;

    /**
     * Id de transaction courant côté source. Change à chaque renouvellement
     * (Apple: transactionId, Google: orderId, Stripe: payment_intent / invoice).
     * Utile pour la traçabilité d'une activation précise.
     */
    @Column(name = "external_transaction_id", length = 255)
    private String externalTransactionId;

    /**
     * Id stable sur toute la chaîne de renouvellements pour ce user et ce
     * produit (Apple: originalTransactionId, Google: purchaseToken, Stripe:
     * subscription_id ou checkout_session_id en mode one-shot). C'est CETTE
     * valeur qu'on utilise pour retrouver une souscription existante quand
     * un renouvellement arrive — d'où l'index unique
     * {@code (source, original_transaction_id)}.
     */
    @Column(name = "original_transaction_id", nullable = false, length = 255)
    private String originalTransactionId;

    /**
     * SKU produit côté store (ex: "integral_monthly", "civique_quarterly").
     * Côté Stripe on stocke le {@code Plan.code} interne. Permet d'identifier
     * l'offre choisie sans dépendre du {@code plan_id} (utile si on change la
     * référence Plan mais qu'on veut garder une trace historique).
     */
    @Column(name = "product_id", length = 128)
    private String productId;

    /**
     * L'utilisateur a-t-il activé le renouvellement automatique ? Posé à
     * false quand il annule sans expiration immédiate — l'accès reste ouvert
     * jusqu'à {@code endsAt} avant de basculer EXPIRED.
     */
    @Column(name = "auto_renew", nullable = false)
    private boolean autoRenew = false;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    /**
     * Stripe customer id — conservé tant que la refonte des plans (lot 4)
     * n'a pas migré le modèle vers du subscription récurrent. {@code null}
     * pour les souscriptions Apple/Google.
     */
    @Column(name = "stripe_customer_id", length = 255)
    private String stripeCustomerId;

    /**
     * Stripe subscription id (ou checkout session id en mode one-shot). Le
     * code Stripe historique le lit encore. Avec V103 il duplique en pratique
     * {@code externalTransactionId} pour les rows STRIPE. À supprimer quand le
     * lot 4 refera passer Stripe en abonnements récurrents.
     */
    @Column(name = "stripe_subscription_id", length = 255)
    private String stripeSubscriptionId;

    /**
     * Pass one-time (lot 5) : date d'envoi du rappel « ton accès se termine
     * bientôt ». NULL tant qu'aucun rappel envoyé. Anti-doublon du job
     * d'expiration.
     */
    @Column(name = "expiry_reminded_at")
    private Instant expiryRemindedAt;

    /**
     * Solde de sessions EO temps réel du pass. Posé à la souscription
     * (= {@code plans.realtime_eo_sessions}), cumulé à la prolongation / au
     * ré-achat, décrémenté de 1 à la connexion réelle d'une session, et
     * ajustable par l'admin. Source de vérité du quota temps réel
     * (cf. {@code RealtimeQuotaService}).
     */
    @Column(name = "realtime_eo_sessions_remaining", nullable = false)
    private int realtimeEoSessionsRemaining = 0;

    /**
     * Montant reellement encaisse, dans la plus petite unite de
     * {@link #currency}, <b>fige a l'ecriture</b>.
     *
     * <p>{@code null} = inconnu (ligne anterieure a la mesure), <b>jamais
     * zero</b>. 🛑 Ne jamais le recalculer depuis {@code plans.price} : ce prix
     * est modifiable en console admin, le relire pour dater un achat passe
     * falsifierait l'historique — c'est exactement le defaut que ces colonnes
     * corrigent.
     */
    @Column(name = "amount_cents")
    private Integer amountCents;

    /** Devise ISO 4217 de {@link #amountCents}. Presente si et seulement si lui l'est. */
    @Column(name = "currency", length = 3)
    private String currency;

    /**
     * Le meme montant en centimes d'euro, converti au taux du jour de
     * l'encaissement. {@code null} si la devise n'avait pas de taux : on
     * n'invente pas une conversion.
     */
    @Column(name = "amount_eur_cents")
    private Integer amountEurCents;

    /**
     * Taux applique a l'encaissement, fige. {@code 1} pour un achat en euros.
     * Jamais relu ni rafraichi : sinon le chiffre d'affaires du passe bougerait
     * tout seul au gre des cours.
     */
    @Column(name = "fx_rate_to_eur", precision = 12, scale = 6)
    private java.math.BigDecimal fxRateToEur;

    @PreUpdate
    public void touchUpdatedAt() {
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Plan getPlan() { return plan; }
    public void setPlan(Plan plan) { this.plan = plan; }

    public SubscriptionStatus getStatus() { return status; }
    public void setStatus(SubscriptionStatus status) { this.status = status; }

    public Instant getStartsAt() { return startsAt; }
    public void setStartsAt(Instant startsAt) { this.startsAt = startsAt; }

    public Instant getEndsAt() { return endsAt; }
    public void setEndsAt(Instant endsAt) { this.endsAt = endsAt; }

    public SubscriptionSource getSource() { return source; }
    public void setSource(SubscriptionSource source) { this.source = source; }

    public String getExternalTransactionId() { return externalTransactionId; }
    public void setExternalTransactionId(String externalTransactionId) { this.externalTransactionId = externalTransactionId; }

    public String getOriginalTransactionId() { return originalTransactionId; }
    public void setOriginalTransactionId(String originalTransactionId) { this.originalTransactionId = originalTransactionId; }

    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public boolean isAutoRenew() { return autoRenew; }
    public void setAutoRenew(boolean autoRenew) { this.autoRenew = autoRenew; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public String getStripeCustomerId() { return stripeCustomerId; }
    public void setStripeCustomerId(String stripeCustomerId) { this.stripeCustomerId = stripeCustomerId; }

    public String getStripeSubscriptionId() { return stripeSubscriptionId; }
    public void setStripeSubscriptionId(String stripeSubscriptionId) { this.stripeSubscriptionId = stripeSubscriptionId; }

    public Instant getExpiryRemindedAt() { return expiryRemindedAt; }
    public void setExpiryRemindedAt(Instant expiryRemindedAt) { this.expiryRemindedAt = expiryRemindedAt; }

    public int getRealtimeEoSessionsRemaining() { return realtimeEoSessionsRemaining; }
    public void setRealtimeEoSessionsRemaining(int realtimeEoSessionsRemaining) {
        this.realtimeEoSessionsRemaining = realtimeEoSessionsRemaining;
    }
    public Integer getAmountCents() { return amountCents; }
    public void setAmountCents(Integer amountCents) { this.amountCents = amountCents; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public Integer getAmountEurCents() { return amountEurCents; }
    public void setAmountEurCents(Integer amountEurCents) { this.amountEurCents = amountEurCents; }

    public java.math.BigDecimal getFxRateToEur() { return fxRateToEur; }
    public void setFxRateToEur(java.math.BigDecimal fxRateToEur) { this.fxRateToEur = fxRateToEur; }
}
