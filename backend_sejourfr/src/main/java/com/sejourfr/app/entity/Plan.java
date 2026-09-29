package com.sejourfr.app.entity;

import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "plans")
public class Plan {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(nullable = false, unique = true, length = 64)
    private String code;

    @Column(nullable = false, length = 120)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "billing_cycle", nullable = false, length = 16)
    private BillingCycle billingCycle;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    /** Prix « normal » affiché barré sur la page paiement (offre de lancement). */
    @Column(name = "original_price", precision = 10, scale = 2)
    private BigDecimal originalPrice;

    @Enumerated(EnumType.STRING)
    @Column(name = "module_access", nullable = false, length = 16)
    private ModuleAccess moduleAccess = ModuleAccess.NONE;

    /** Durée d'accès en jours après paiement one-shot. */
    @Column(name = "duration_days", nullable = false)
    private int durationDays = 0;

    /**
     * Nature commerciale : abonnement récurrent (SUBSCRIPTION, lots 2/3/4) ou
     * pass d'accès à durée fixe (ONE_TIME, lot 5). En mode ONE_TIME,
     * {@link #durationDays} EST la source de vérité de la durée Premium.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "purchase_type", nullable = false, length = 16)
    private PlanPurchaseType purchaseType = PlanPurchaseType.SUBSCRIPTION;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /**
     * Nombre de sessions d'expression orale en TEMPS RÉEL (examinateur IA, T1/T2)
     * ouvertes par ce pass. 0 = non éligible (Civique / Free). Cap du quota ;
     * la consommation est dérivée de la table {@code realtime_sessions}.
     */
    @Column(name = "realtime_eo_sessions", nullable = false)
    private int realtimeEoSessions = 0;

    /**
     * SKU Apple App Store correspondant à ce Plan (ex: "integral.monthly").
     * NULL tant que le produit n'a pas été créé côté App Store Connect. Sert
     * au backend à retrouver le Plan à partir du {@code productId} remonté
     * par un reçu IAP.
     */
    @Column(name = "apple_product_id", length = 128)
    private String appleProductId;

    /**
     * SKU Google Play correspondant à ce Plan. Même fonction que
     * {@link #appleProductId} côté Android.
     */
    @Column(name = "google_product_id", length = 128)
    private String googleProductId;

    /**
     * Stripe Price ID (format {@code price_xxx}) correspondant à ce Plan en
     * mode abonnement récurrent (Checkout Session mode=SUBSCRIPTION). NULL
     * pour le plan FREE. Lu au lieu de StripeProperties — la config Stripe
     * vit désormais sur la ligne Plan, pas en yaml.
     */
    @Column(name = "stripe_price_id", length = 255)
    private String stripePriceId;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public BillingCycle getBillingCycle() { return billingCycle; }
    public void setBillingCycle(BillingCycle billingCycle) { this.billingCycle = billingCycle; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public BigDecimal getOriginalPrice() { return originalPrice; }
    public void setOriginalPrice(BigDecimal originalPrice) { this.originalPrice = originalPrice; }

    public ModuleAccess getModuleAccess() { return moduleAccess; }
    public void setModuleAccess(ModuleAccess moduleAccess) { this.moduleAccess = moduleAccess; }

    public int getDurationDays() { return durationDays; }
    public void setDurationDays(int durationDays) { this.durationDays = durationDays; }

    public PlanPurchaseType getPurchaseType() { return purchaseType; }
    public void setPurchaseType(PlanPurchaseType purchaseType) { this.purchaseType = purchaseType; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public int getRealtimeEoSessions() { return realtimeEoSessions; }
    public void setRealtimeEoSessions(int realtimeEoSessions) { this.realtimeEoSessions = realtimeEoSessions; }

    public String getAppleProductId() { return appleProductId; }
    public void setAppleProductId(String appleProductId) { this.appleProductId = appleProductId; }

    public String getGoogleProductId() { return googleProductId; }
    public void setGoogleProductId(String googleProductId) { this.googleProductId = googleProductId; }

    public String getStripePriceId() { return stripePriceId; }
    public void setStripePriceId(String stripePriceId) { this.stripePriceId = stripePriceId; }
}
