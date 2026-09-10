package com.sejourfr.app.service.plancivique;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LE REPLI LEITNER (L10, {@code 20_} §5.1 et §5.2).
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>l'ORDRE fait la boîte</b> — c'est la propriété dont tout dépend.
 *       Un {@code ORDER BY} oublié dans la requête se verrait comme un plan qui
 *       change sans raison, et rien d'autre ne l'attraperait ;</li>
 *   <li>🛑 <b>une erreur renvoie en boîte 1, toujours</b>, quelle que soit la
 *       hauteur atteinte : c'est ce qui fait revenir tout de suite ce qui vient
 *       de coûter des points ;</li>
 *   <li>🛑 <b>moins de deux réponses ⇒ NON_EVALUEE</b>, jamais « à
 *       travailler ». Une absence de mesure n'est pas un mauvais verdict — la
 *       confusion inverse a produit les faux {@code A1_NON_ATTEINT} du TCF ;</li>
 *   <li>une cible jamais vue n'est <b>jamais en retard</b> : rien à repousser.</li>
 * </ul>
 */
class CivicLeitnerResolverTest {

    private static final Instant T0 = Instant.parse("2026-09-01T10:00:00Z");
    private static final Instant MAINTENANT = Instant.parse("2026-09-20T10:00:00Z");
    private static final Duration FENETRE = Duration.ofDays(30);
    private static final UUID NOTION = UUID.randomUUID();
    private static final UUID THEME = UUID.randomUUID();

    private final CivicLeitnerResolver resolver = new CivicLeitnerResolver();

    private static CivicReponse reponse(boolean correcte, long joursApresT0) {
        return new CivicReponse(NOTION, THEME, correcte, T0.plus(Duration.ofDays(joursApresT0)));
    }

    @Test
    @DisplayName("Aucune réponse : boîte 1, non évaluée, jamais en retard")
    void vierge() {
        CivicEtatCible etat = resolver.resoudre(List.of(), FENETRE, MAINTENANT);

        assertThat(etat.boite()).isEqualTo(CivicLeitner.PREMIERE);
        assertThat(etat.maitrise()).isEqualTo(CivicMaitrise.NON_EVALUEE);
        // 🛑 Jamais vue ⇒ pas d'échéance, donc pas « en retard ». Une cible
        // neuve n'a rien à rattraper.
        assertThat(etat.prochaineRevue()).isNull();
        assertThat(etat.aRevoir(MAINTENANT)).isFalse();
    }

    @Test
    @DisplayName("Quatre bonnes réponses montent jusqu'en boîte 5, et pas au-delà")
    void monteeEtPlafond() {
        CivicEtatCible etat = resolver.resoudre(List.of(
                reponse(true, 0), reponse(true, 1), reponse(true, 2),
                reponse(true, 3), reponse(true, 4), reponse(true, 5)),
                FENETRE, MAINTENANT);

        assertThat(etat.boite()).isEqualTo(CivicLeitner.DERNIERE);
        assertThat(etat.maitrise()).isEqualTo(CivicMaitrise.MAITRISEE);
        assertThat(etat.consecutivesJustes()).isEqualTo(6);
    }

    @Test
    @DisplayName("🛑 Une erreur renvoie en boîte 1, même depuis la boîte 5")
    void uneErreurRamèneEnBas() {
        CivicEtatCible etat = resolver.resoudre(List.of(
                reponse(true, 0), reponse(true, 1), reponse(true, 2),
                reponse(true, 3), reponse(true, 4),
                reponse(false, 5)),
                FENETRE, MAINTENANT);

        assertThat(etat.boite()).isEqualTo(CivicLeitner.PREMIERE);
        assertThat(etat.maitrise()).isEqualTo(CivicMaitrise.A_TRAVAILLER);
        assertThat(etat.consecutivesJustes()).isZero();
        assertThat(etat.derniereErreur()).isEqualTo(T0.plus(Duration.ofDays(5)));
    }

    @Test
    @DisplayName("🛑 L'ORDRE fait la boîte : les mêmes réponses inversées ne donnent pas le même état")
    void lOrdreFaitLaBoite() {
        CivicReponse juste = reponse(true, 1);
        CivicReponse fausse = reponse(false, 0);

        // Servies dans le désordre : le repli les remet dans l'ordre du temps.
        CivicEtatCible faussePuisJuste =
                resolver.resoudre(List.of(juste, fausse), FENETRE, MAINTENANT);
        CivicEtatCible justePuisFausse = resolver.resoudre(
                List.of(reponse(true, 0), reponse(false, 1)), FENETRE, MAINTENANT);

        // fausse (→1) puis juste (→2)
        assertThat(faussePuisJuste.boite()).isEqualTo(2);
        // juste (→2) puis fausse (→1)
        assertThat(justePuisFausse.boite()).isEqualTo(1);
    }

    @Test
    @DisplayName("🛑 Une seule réponse ne conclut rien : NON_EVALUEE, même juste")
    void uneSeuleReponseNeConcluPas() {
        assertThat(resolver.resoudre(List.of(reponse(true, 0)), FENETRE, MAINTENANT).maitrise())
                .isEqualTo(CivicMaitrise.NON_EVALUEE);
        assertThat(resolver.resoudre(List.of(reponse(false, 0)), FENETRE, MAINTENANT).maitrise())
                .isEqualTo(CivicMaitrise.NON_EVALUEE);
    }

    @Test
    @DisplayName("Boîte 4 avec une dernière réponse fausse n'est PAS maîtrisée")
    void maitriseExigeLaDerniereJuste() {
        // 3 justes (→4), puis une fausse ramène en 1 : on vérifie l'autre
        // branche, celle où la boîte est haute mais la dernière est fausse.
        CivicEtatCible etat = new CivicEtatCible(
                4, 5, 4, 0, T0, T0, 1, T0.plus(Duration.ofDays(7)),
                CivicMaitrise.of(5, 4, false));
        assertThat(etat.maitrise()).isEqualTo(CivicMaitrise.EN_PROGRESSION);
    }

    @Test
    @DisplayName("L'échéance suit la boîte, et se franchit toute seule à la lecture")
    void echeanceDeriveeDeLaBoite() {
        // 2 justes ⇒ boîte 3 ⇒ 3 jours d'attente après la dernière vue.
        CivicEtatCible etat = resolver.resoudre(
                List.of(reponse(true, 0), reponse(true, 1)), FENETRE, MAINTENANT);

        assertThat(etat.boite()).isEqualTo(3);
        assertThat(etat.prochaineRevue())
                .isEqualTo(T0.plus(Duration.ofDays(1)).plus(Duration.ofDays(3)));
        // 🛑 Aucun job quotidien : l'échéance est dépassée parce qu'on la
        // compare à MAINTENANT, pas parce qu'un batch l'a marquée.
        assertThat(etat.aRevoir(MAINTENANT)).isTrue();
        assertThat(etat.aRevoir(T0.plus(Duration.ofDays(2)))).isFalse();
    }

    @Test
    @DisplayName("Les erreurs récentes sont comptées sur la fenêtre servie, pas sur tout l'historique")
    void erreursRecentesBorneesParLaFenetre() {
        CivicEtatCible etat = resolver.resoudre(List.of(
                reponse(false, 0),    // hors fenêtre de 7 jours
                reponse(false, 18),   // dans les 7 derniers jours
                reponse(false, 19)),
                Duration.ofDays(7), MAINTENANT);

        assertThat(etat.reponses()).isEqualTo(3);
        assertThat(etat.erreurs()).isEqualTo(3);
        assertThat(etat.erreursRecentes()).isEqualTo(2);
    }
}
