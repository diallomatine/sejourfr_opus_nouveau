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

    public BillingMode getMode() { return mode; }
    public void setMode(BillingMode mode) { this.mode = mode; }

    public boolean isOneTime() { return mode == BillingMode.ONE_TIME; }
    public boolean isSubscription() { return mode == BillingMode.SUBSCRIPTION; }
}
