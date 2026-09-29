package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.enums.CivicThemeState;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LE SCORE DE PRIORITÉ CIVIQUE ({@code 20_} §5.3).
 *
 * <p>Ce que ce test verrouille :
 * <ul>
 *   <li>🛑 <b>le malus de contenu insuffisant est écrasant</b> — une notion qui
 *       n'a pas de quoi remplir une série ne doit JAMAIS remonter en priorité,
 *       même chargée de tous les autres signaux ({@code 50_} §6.1) ;</li>
 *   <li>🛑 <b>{@code NON_APPLICABLE} ne prend AUCUN malus</b> — une notion qui
 *       n'est pas au programme de cette démarche n'est pas un mauvais choix,
 *       elle n'est pas un choix du tout. Le plan l'écarte par un filtre, qui
 *       est strictement plus sévère qu'un −10 ; lui coller le malus du manque
 *       serait la confusion {@code inconnu ⇒ mauvais} du dépôt ;</li>
 *   <li>🛑 <b>{@code NON_EVALUE} pèse 0</b>, comme {@code SOLIDE} : un thème que
 *       le diagnostic n'a pas touché n'est pas faible. Lui donner le poids de
 *       {@code FAIBLE} inventerait une fragilité ;</li>
 *   <li>les erreurs répétées sont <b>plafonnées</b> : au-delà de trois, en
 *       ajouter n'ordonne plus rien et écraserait tous les autres signaux ;</li>
 *   <li>une cible maîtrisée <b>descend</b>, elle ne disparaît pas — elle reste
 *       classable en révision d'entretien.</li>
 * </ul>
 */
class CivicPrioriteScorerTest {

    private static final Instant MAINTENANT = Instant.parse("2026-09-20T10:00:00Z");

    private final CivicPrioriteScorer scorer = new CivicPrioriteScorer();

    private static CivicEtatCible etat(
            CivicMaitrise maitrise, Instant derniereErreur, int erreursRecentes,
            Instant prochaineRevue) {
        return new CivicEtatCible(
                2, 6, 3, 0, MAINTENANT.minus(Duration.ofDays(1)),
                derniereErreur, erreursRecentes, prochaineRevue, maitrise);
    }

    @Test
    @DisplayName("Une cible vierge sur un thème non évalué vaut 0 : rien ne la pousse, rien ne la punit")
    void neutre() {
        int score = scorer.score(
                CivicEtatCible.vierge(), CivicThemeState.NON_EVALUE, false, MAINTENANT);
        assertThat(score).isZero();
    }

    @Test
    @DisplayName("Erreur récente + erreurs répétées + échéance franchie + thème faible s'additionnent")
    void signauxCumules() {
        CivicEtatCible e = etat(
                CivicMaitrise.A_TRAVAILLER,
                MAINTENANT.minus(Duration.ofDays(2)),   // +3 (fenêtre chaude)
                5,                                       // +2×3 = 6 (plafonné)
                MAINTENANT.minus(Duration.ofDays(1)));   // +2 (échéance franchie)

        int score = scorer.score(
                e, CivicThemeState.FAIBLE, true, MAINTENANT);

        // 3 + 6 + 2 (diagnostic) + 2 (échéance) + 2 (thème faible)
        assertThat(score).isEqualTo(15);
    }

    @Test
    @DisplayName("🛑 Les erreurs répétées sont plafonnées à trois")
    void erreursPlafonnees() {
        CivicEtatCible troisErreurs = etat(CivicMaitrise.A_TRAVAILLER, null, 3, null);
        CivicEtatCible dixErreurs = etat(CivicMaitrise.A_TRAVAILLER, null, 10, null);

        assertThat(scorer.score(troisErreurs, null, false, MAINTENANT))
                .isEqualTo(scorer.score(dixErreurs, null, false, MAINTENANT))
                .isEqualTo(6);
    }

    @Test
    @DisplayName("🛑 Une erreur hors de la fenêtre chaude ne pèse plus les 3 points")
    void fenetreChaude() {
        CivicEtatCible vieille =
                etat(CivicMaitrise.A_TRAVAILLER, MAINTENANT.minus(Duration.ofDays(30)), 0, null);
        CivicEtatCible fraiche =
                etat(CivicMaitrise.A_TRAVAILLER, MAINTENANT.minus(Duration.ofDays(2)), 0, null);

        assertThat(scorer.score(vieille, null, false, MAINTENANT))
                .isZero();
        assertThat(scorer.score(fraiche, null, false, MAINTENANT))
                .isEqualTo(3);
    }

    @Test
    @DisplayName("🛑 NON_EVALUE et SOLIDE pèsent le MÊME poids : zéro")
    void nonEvaluéNestPasFaible() {
        CivicEtatCible e = CivicEtatCible.vierge();

        assertThat(scorer.score(
                e, CivicThemeState.NON_EVALUE, false, MAINTENANT))
                .isEqualTo(scorer.score(
                        e, CivicThemeState.SOLIDE, false, MAINTENANT))
                .isZero();
        assertThat(scorer.score(
                e, CivicThemeState.A_RENFORCER, false, MAINTENANT))
                .isEqualTo(1);
        assertThat(scorer.score(
                e, CivicThemeState.FAIBLE, false, MAINTENANT))
                .isEqualTo(2);
    }

    // ⚠️ DEUX TESTS SUPPRIMES ICI, ET C'EST VOULU (P8.2b, 2026-09-20).
    // « Le contenu insuffisant ecrase tous les autres signaux » (−10) et
    // « NON_APPLICABLE ne prend aucun malus » portaient sur `CivicDotation`,
    // qui a disparu avec le filtre de mention : sans filtre, AUCUN couple ne
    // tombe sous le seuil et `NON_APPLICABLE` est devenu impossible (D-27).
    // Les garder aurait fige une regle morte -- « refonte = suppression
    // immediate de l'ancien ».

    /** La cible la plus chargée que le score puisse produire : 15. */
    private static CivicEtatCible pire() {
        return etat(
                CivicMaitrise.A_TRAVAILLER,
                MAINTENANT.minus(Duration.ofDays(1)),
                10,
                MAINTENANT.minus(Duration.ofDays(1)));
    }

    @Test
    @DisplayName("Une cible maîtrisée descend de 3, elle ne disparaît pas")
    void maitriseeDescend() {
        CivicEtatCible maitrisee = etat(CivicMaitrise.MAITRISEE, null, 0, null);
        assertThat(scorer.score(
                maitrisee, CivicThemeState.FAIBLE, false, MAINTENANT))
                .isEqualTo(-1);
    }
}
