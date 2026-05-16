package com.sejourfr.app.entity;

import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;
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

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

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

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
