package com.sejourfr.app.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Reglages du diagnostic TCF 4 epreuves (lot L4, spec {@code 10_} §4).
 *
 * <p>🛑 <b>Les valeurs par defaut sont IDENTIQUES a celles d'application.yaml.</b>
 * Un POJO qui diverge de son YAML ne se decouvre que le jour ou la cle
 * disparait de la configuration — regle du depot.
 *
 * <p>Ce qui vit ici, ce sont des <b>reglages</b> : combien d'items par palier,
 * quels taux font basculer un niveau, combien de temps on peut reprendre. Ce
 * qui n'y vit PAS, ce sont les <b>donnees officielles</b> (durees d'epreuve du
 * TCF, table des paliers de la demarche) : celles-la sont du code, pas un
 * reglage — cf. {@code DureeEpreuve} et {@code TargetProcedure}.
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "sejourfr.tcf-diagnostic")
public class TcfDiagnosticProperties {

    /**
     * Version de configuration recopiee sur chaque session
     * ({@code tcf_diagnostic_sessions.config_version}).
     *
     * <p>🛑 <b>A incrementer des qu'un reglage ci-dessous change le SENS d'un
     * resultat</b> (nombre d'items par palier, seuils). Un diagnostic se relit
     * avec la configuration qui l'a produit : sans ce numero, un recalibrage
     * reinterpreterait retroactivement des diagnostics deja passes.
     */
    private int configVersion = 1;

    /**
     * Items tires par palier CECRL, pour CHAQUE epreuve de comprehension —
     * 5 A2 + 5 B1 + 5 B2 = 15 items en CO comme en CE (10_ §4.1).
     *
     * <p>La repartition egale n'est pas cosmetique : le calcul de niveau lit un
     * <b>taux par palier</b>, et un palier sous-dote rendrait son taux
     * beaucoup plus sensible a une seule erreur.
     */
    private int itemsPerLevel = 5;

    /** Seuils de bascule du niveau de comprehension (10_ §4.3). */
    private Seuils seuils = new Seuils();

    /**
     * Delai de REPRISE d'un diagnostic commence (10_ §4.2 : 7 jours).
     *
     * <p>Ce n'est pas une date de peremption du resultat : passe ce delai, les
     * sections realisees comptent toujours et les autres restent « non
     * evaluee ». Rien n'est detruit.
     */
    private Duration reprise = Duration.ofDays(7);

    /**
     * Delai minimal entre deux diagnostics pour un abonne (10_ §4.6 : 14 jours).
     *
     * <p>Sans lui, une reevaluation a volonte ne mesurerait plus une
     * progression — juste le bruit de deux passations rapprochees.
     */
    private Duration reevaluation = Duration.ofDays(14);

    /** Nombre maximum de priorites servies a l'ecran (10_ §4.4, arbitrage A6). */
    private int maxPriorites = 3;

    @Getter
    @Setter
    public static class Seuils {
        /**
         * Taux minimal sur les items A2 pour ne pas rester sous le palier A2.
         * En dessous, le niveau est {@code A1}.
         */
        private double a2 = 0.60;

        /** Taux A2 exige des que l'on vise B1 ou au-dela. */
        private double a2PourB1 = 0.80;

        /** Taux B1 exige pour le palier B1. */
        private double b1 = 0.60;

        /** Taux B1 exige pour le palier B2 (plus severe que pour B1). */
        private double b1PourB2 = 0.70;

        /** Taux B2 exige pour le palier B2. */
        private double b2 = 0.60;
    }
}
