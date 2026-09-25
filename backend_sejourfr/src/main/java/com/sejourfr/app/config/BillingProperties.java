package com.sejourfr.app.config;

import com.sejourfr.app.enums.BillingMode;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration du mode commercial. Lu via {@code sejourfr.billing.mode}
 * (env {@code BILLING_MODE}). Bascule à chaud (redémarrage backend suffit).
 *
 * <p>Défaut {@code ONE_TIME} : le lot 5 a activé les passes en base (les plans
 * récurrents sont désactivés mais conservés). Pour revenir aux abonnements :
 * réactiver les plans récurrents + désactiver les passes + poser
 * {@code BILLING_MODE=SUBSCRIPTION}.
 */
@ConfigurationProperties(prefix = "sejourfr.billing")
public class BillingProperties {

    private BillingMode mode = BillingMode.ONE_TIME;

    /**
     * Version de {@code billing/revenue-rules-v{n}.json} appliquee aux achats A
     * VENIR (TVA, frais, net). Chaque achat fige la sienne : changer cette
     * valeur ne recalcule rien du passe. Une version inconnue echoue au boot.
     */
    private int revenueRulesVersion = 1;

    public BillingMode getMode() { return mode; }
    public void setMode(BillingMode mode) { this.mode = mode; }

    public int getRevenueRulesVersion() { return revenueRulesVersion; }
    public void setRevenueRulesVersion(int revenueRulesVersion) { this.revenueRulesVersion = revenueRulesVersion; }

    public boolean isOneTime() { return mode == BillingMode.ONE_TIME; }
    public boolean isSubscription() { return mode == BillingMode.SUBSCRIPTION; }
}
