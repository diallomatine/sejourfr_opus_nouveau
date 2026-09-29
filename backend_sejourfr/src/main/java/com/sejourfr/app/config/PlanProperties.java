package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Le <b>seul</b> reglage du Plan qui vive dans {@code application.yaml} :
 * quelle version de {@code plan-config-vN.json} est active.
 *
 * <p>Plafonds d'affichage et poids de classement vivent dans ce fichier
 * versionne, et nulle part ailleurs. Cette classe ne porte donc <b>aucune</b>
 * valeur metier : il n'y a rien a garder synchronise entre deux endroits.
 *
 * <p>🛑 <b>A ne pas confondre avec {@code ProgressionProperties}</b>. Les deux
 * configurations ont des cycles de vie <b>opposes</b> et doivent le rester :
 * <ul>
 *   <li>{@code progression-config-vN.json} porte l'integrite d'{@code engineVersion}
 *       et le <b>rejeu</b> de la maitrise — on n'y touche qu'avec un replay
 *       controle ;</li>
 *   <li>{@code plan-config-vN.json} pilote la <b>selection et l'affichage</b>
 *       (composition de la seance, rideau, classement) et bougera souvent.</li>
 * </ul>
 * Les melanger invaliderait le rejeu a chaque reglage d'ecran. D'ou l'invariant :
 * <b>{@code plan-config} ne peut RIEN influencer du calcul de maitrise</b>
 * (arbitrage du proprietaire, 2026-08-26).
 */
@ConfigurationProperties(prefix = "sejourfr.plan")
public class PlanProperties {

    /**
     * La version de configuration a charger : le fichier lu est
     * {@code plan/plan-config-v{configVersion}.json}.
     */
    private int configVersion = 1;

    public int getConfigVersion() {
        return configVersion;
    }

    public void setConfigVersion(int configVersion) {
        this.configVersion = configVersion;
    }
}
