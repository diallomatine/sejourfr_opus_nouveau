package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Le <b>seul</b> reglage du parcours TCF qui vive dans {@code application.yaml} :
 * quelle version de {@code plan/tcf-journey-config-vN.json} est active.
 *
 * <p>Cette classe ne porte <b>aucune</b> valeur metier — il n'y a donc rien a
 * garder synchronise entre deux endroits.
 *
 * <p>🛑 <b>Pourquoi un fichier a part et pas une section de
 * {@code plan-config}.</b> {@link PlanProperties} porte l'interdiction explicite
 * (arbitrage du proprietaire, 2026-08-26) que {@code plan-config} « ne puisse
 * RIEN influencer du calcul de maitrise », pour que le rejeu de
 * {@code progression-config} reste intact quand on regle un rideau d'ecran. Or
 * {@code trainSeriesQuota} decide de la <b>cloture d'une etape</b> : il n'a pas
 * sa place sous cette interdiction.
 */
@ConfigurationProperties(prefix = "sejourfr.tcf-journey")
public class TcfJourneyProperties {

    /**
     * La version de configuration a charger : le fichier lu est
     * {@code plan/tcf-journey-config-v{configVersion}.json}.
     */
    private int configVersion = 3;

    public int getConfigVersion() {
        return configVersion;
    }

    public void setConfigVersion(int configVersion) {
        this.configVersion = configVersion;
    }
}
