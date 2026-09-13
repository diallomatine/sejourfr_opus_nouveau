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
     * <p>🛑 <b>A incrementer des qu'un reglage change le SENS d'un resultat</b>
     * (composition du tirage, seuils). Un diagnostic se relit avec la
     * configuration qui l'a produit : sans ce numero, un recalibrage
     * reinterpreterait retroactivement des diagnostics deja passes.
     *
     * <p>⚠️ <b>3 depuis le 2026-09-13</b> : chaque epreuve de comprehension du
     * diagnostic est desormais <b>un examen blanc d'epreuve</b> — 25 items
     * (8/9/8) et duree pleine, au lieu de 24 items a repartition egale et d'un
     * chrono au prorata. {@code items-per-level} a disparu avec ce tirage.
     */
    private int configVersion = 3;

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
