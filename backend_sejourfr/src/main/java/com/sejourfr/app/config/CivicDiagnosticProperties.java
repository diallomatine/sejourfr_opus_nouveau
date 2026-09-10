package com.sejourfr.app.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Reglages du diagnostic civique (lot L9, spec 20_ §4).
 *
 * <p>🛑 <b>Les valeurs par defaut sont IDENTIQUES a celles d'application.yaml.</b>
 * Un POJO qui diverge de son YAML ne se decouvre que le jour ou la cle
 * disparait de la configuration — regle du depot.
 *
 * <p>Ce qui vit ici, ce sont des <b>reglages</b> : combien de questions, quels
 * taux font basculer un theme. Ce qui n'y vit PAS, c'est le format officiel de
 * l'examen (40 questions, seuil 32) : c'est une donnee officielle, donc du
 * code — cf. {@code CivicExamFormat}.
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "sejourfr.civic-diagnostic")
public class CivicDiagnosticProperties {

    /**
     * Version de configuration recopiee sur chaque session.
     *
     * <p>🛑 <b>A incrementer des qu'un reglage ci-dessous change le SENS d'un
     * resultat</b> (composition, seuils). Un diagnostic se relit avec la
     * configuration qui l'a produit : sans ce numero, un recalibrage
     * reinterpreterait retroactivement des diagnostics deja passes.
     */
    private int configVersion = 1;

    /** Questions de CONNAISSANCE tirees (20_ §4.2 : 17). */
    private int connaissances = 17;

    /**
     * Mises en situation tirees (20_ §4.2 : 7, soit ~29 %).
     *
     * <p>Le ratio n'est pas decoratif : il reprend celui de l'examen reel
     * (12 sur 40). Une mise en situation demande d'appliquer une regle a un cas
     * concret — c'est une competence distincte, et l'ecran la compte a part.
     */
    private int misesEnSituation = 7;

    /**
     * Minimum de questions de connaissance par theme (20_ §4.2).
     *
     * <p>🛑 Contrainte explicite de la spec : « <b>ne jamais evaluer un theme
     * sur une seule question</b> ». Un theme juge sur une reponse produirait un
     * etat qui ne veut rien dire.
     */
    private int minParTheme = 3;

    /** Seuils de bascule de l'etat d'un theme (20_ §4.4). */
    private Seuils seuils = new Seuils();

    /**
     * Delai minimal entre deux diagnostics civiques pour un abonne
     * (20_ §4.3 : 14 jours). Meme raison qu'au TCF : sans lui, une reevaluation
     * a volonte ne mesurerait plus une progression.
     */
    private Duration reevaluation = Duration.ofDays(14);

    @Getter
    @Setter
    public static class Seuils {
        /** Taux a partir duquel un theme est SOLIDE. */
        private double solide = 0.80;

        /** Taux en dessous duquel un theme est FAIBLE. */
        private double faible = 0.55;
    }
}
