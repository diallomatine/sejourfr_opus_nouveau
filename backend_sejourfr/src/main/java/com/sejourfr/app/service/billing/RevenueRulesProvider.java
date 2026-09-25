package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.BillingProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Expose les regles de revenus en vigueur, chargees et verifiees une fois au
 * demarrage. Consommees par la decomposition des achats (lot 2 du chantier
 * Suivi) ; les charger des maintenant fait echouer le boot sur une regle fausse.
 */
@Configuration
@RequiredArgsConstructor
public class RevenueRulesProvider {

    private final BillingProperties properties;

    @Bean
    public RevenueRules revenueRules() {
        return RevenueRulesLoader.load(properties.getRevenueRulesVersion());
    }
}
