package com.sejourfr.app.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Reglages du <b>plan civique</b> (lot L10, spec 20_ §5 et §6).
 *
 * <p>🛑 <b>Les valeurs par defaut sont IDENTIQUES a celles d'application.yaml.</b>
 * Un POJO qui diverge de son YAML ne se decouvre que le jour ou la cle
 * disparait de la configuration — regle du depot.
 *
 * <p>🛑 <b>Aucune version de configuration ici, et c'est voulu.</b> Le plan est
 * un <b>derive relu a chaque lecture</b> : rien n'est fige, donc rien ne se
 * reinterprete retroactivement. C'est la difference avec le diagnostic, qui
 * fige un resultat date et porte pour cette raison un {@code config-version}.
 * Changer un reglage ici change le plan au prochain appel, sans migration.
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "sejourfr.civic-plan")
public class CivicPlanProperties {

    /**
     * Part des questions actives d'un theme qui doivent etre taguees pour que le
     * plan y travaille <b>par notion</b> (20_ §3.3).
     *
     * <p>🛑 <b>La bascule est PAR THEME</b>, jamais globale : un theme tague a
     * 90 % n'attend pas celui qui est a 10 %. Au lancement de ce lot, 0 question
     * sur 1 016 est taguee — les cinq themes sont donc au grain THEME, ce qui
     * est le mode PREVU par la spec (§3.3 phase 1), pas une panne.
     */
    private double seuilTagging = 0.80;

    /**
     * Questions minimales pour qu'une notion soit proposable en priorite
     * (20_ §3.4 : {@code insufficient_content}).
     *
     * <p>🛑 <b>Compte PAR MENTION.</b> Une notion peut etre pleinement dotee
     * pour un candidat NAT et vide pour un CSP : rendre un verdict global
     * effacerait exactement cette nuance (meme regle qu'au referentiel, 50_
     * §6.1).
     */
    private int questionsMinParNotion = 4;

    /**
     * Priorites servies au front (20_ §5.3 : « 3 priorites visibles maximum »).
     *
     * <p>🛑 <b>C'est un plafond d'AFFICHAGE, jamais un budget de calcul.</b> Le
     * moteur classe TOUTES les cibles ; le DTO en sert {@code priorites} et
     * <b>compte</b> le reste (« + 6 autres notions a consolider »). Utiliser ce
     * nombre pour borner la production a deja prive trois domaines sur quatre de
     * toute action cote TCF (2026-08-25).
     */
    private int prioritesVisibles = 3;

    /**
     * Cibles servies dans « a revoir bientot » (20_ §6 bloc 5). Meme nature :
     * un plafond d'affichage.
     */
    private int revisionsVisibles = 3;

    /**
     * Questions d'une serie ciblee (20_ §6 bloc 2 : « 10 questions ciblees »).
     *
     * <p>La duree annoncee s'en <b>derive</b> ({@link #secondesParQuestion}) :
     * raccourcir la serie raccourcit la promesse, sans qu'aucun ecran n'ait a
     * etre touche.
     */
    private int questionsParSerie = 10;

    /**
     * Secondes par question, pour l'ordre de grandeur annonce (« ~6 min »).
     *
     * <p>🛑 <b>Ordre de grandeur, jamais un chrono</b> : rien dans une serie
     * ciblee ne chronometre le candidat sur cette valeur.
     */
    private int secondesParQuestion = 36;
}
