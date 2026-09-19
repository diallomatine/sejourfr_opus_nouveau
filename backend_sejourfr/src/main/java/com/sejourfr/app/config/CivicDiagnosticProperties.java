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

    /*
     * 🛑 `connaissances: 28` ET `mises-en-situation: 12` ONT DISPARU D'ICI
     * (D-44, 2026-09-19), et ne sont pas remplacees par un alias.
     *
     * Le partage 28 / 12 est de la LOI : arrete du 10 octobre 2025, annexe I.
     * Il est lu chez son autorite unique, `CivicExamFormat.CONNAISSANCES` et
     * `CivicExamFormat.MISES_EN_SITUATION`.
     *
     * POURQUOI LE `configVersion` NE LES JUSTIFIAIT PAS. L'argument etait qu'un
     * resultat date se relit avec la configuration qui l'a produit. Mesure faite
     * avant de trancher : `config_version` est bien ECRIT sur
     * `civic_diagnostic_sessions`, mais il n'est JAMAIS RELU pour reinterpreter
     * un resultat civique ; aucun test ne fait varier ces deux valeurs ; et
     * aucun profil ne surcharge le bloc `civic-diagnostic`. Elles ne pilotaient
     * rien -- elles offraient seulement a quelqu'un la possibilite de faire
     * cesser le diagnostic de simuler l'examen legal, sans que rien ne l'en
     * empeche.
     *
     * CE QUE `configVersion` JUSTIFIE ENCORE, et qui reste ci-dessous : les
     * seuils (`solide`, `faible`) et `min-par-theme`, qui changent le SENS d'un
     * resultat a la relecture. Eux sont des conventions de mesure, pas la loi.
     */

    /**
     * Minimum de questions de connaissance par theme (20_ §4.2).
     *
     * <p>🛑 Contrainte explicite de la spec : « <b>ne jamais evaluer un theme
     * sur une seule question</b> ». Un theme juge sur une reponse produirait un
     * etat qui ne veut rien dire.
     *
     * <p>Releve de 3 a 4 avec le passage a 40 questions : 28 questions de
     * connaissance sur 5 themes en autorisent 4 chacun (20) et laissent 8 au
     * complement. Un plancher qui ne bouge pas quand le total grandit rend le
     * minimum de moins en moins significatif.
     */
    private int minParTheme = 4;

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
