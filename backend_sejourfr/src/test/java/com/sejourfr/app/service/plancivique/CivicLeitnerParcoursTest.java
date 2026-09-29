package com.sejourfr.app.service.plancivique;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.sejourfr.app.service.plancivique.CivicEtapeEtat.A_VENIR;
import static com.sejourfr.app.service.plancivique.CivicEtapeEtat.EN_COURS;
import static com.sejourfr.app.service.plancivique.CivicEtapeEtat.FRANCHIE;
import static org.assertj.core.api.Assertions.assertThat;

/**
 * LE PARCOURS D'UNE CIBLE CIVIQUE — ce que le candidat voit de sa progression.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>le parcours est SERVI</b>. Une premiere version le derivait de
 *       {@code boite} dans les deux fronts : un front qui classe un nombre en
 *       etat pedagogique, ce que le depot interdit, et deux implementations
 *       vouees a diverger. Ce test est ce qui empeche d'y revenir ;</li>
 *   <li>🛑 <b>il y a AU PLUS une etape en cours</b> — sans quoi l'ecran ne dit
 *       plus ou en est le candidat ;</li>
 *   <li>🛑 <b>une cible maitrisee n'a AUCUNE etape en cours</b> : l'ecran
 *       redemanderait un travail deja fait ;</li>
 *   <li>🛑 <b>le parcours RECULE apres une erreur</b>. C'est la propriete qui
 *       rend l'effet Leitner visible ({@code 30_} §510) : un plan qui se
 *       reorganise en silence ne se distingue pas d'une liste de themes ;</li>
 *   <li>une boite hors bornes ne casse rien — un historique ancien ne doit pas
 *       produire un parcours vide.</li>
 * </ul>
 */
class CivicLeitnerParcoursTest {

    @Test
    @DisplayName("il y a toujours exactement cinq etapes, autant que de boites")
    void cinqEtapes() {
        for (int boite = CivicLeitner.PREMIERE; boite <= CivicLeitner.DERNIERE; boite++) {
            assertThat(CivicLeitner.parcours(boite, false))
                    .as("boite %d", boite)
                    .hasSize(CivicLeitner.DERNIERE);
        }
    }

    @Test
    @DisplayName("la boite situe l'etape en cours, et ce qui precede est franchi")
    void positionne() {
        assertThat(CivicLeitner.parcours(1, false))
                .containsExactly(EN_COURS, A_VENIR, A_VENIR, A_VENIR, A_VENIR);
        assertThat(CivicLeitner.parcours(3, false))
                .containsExactly(FRANCHIE, FRANCHIE, EN_COURS, A_VENIR, A_VENIR);
        assertThat(CivicLeitner.parcours(5, false))
                .containsExactly(FRANCHIE, FRANCHIE, FRANCHIE, FRANCHIE, EN_COURS);
    }

    @Test
    @DisplayName("au plus une etape en cours, quelle que soit la boite")
    void uneSeuleEnCours() {
        for (int boite = 0; boite <= CivicLeitner.DERNIERE + 2; boite++) {
            assertThat(CivicLeitner.parcours(boite, false))
                    .as("boite %d", boite)
                    .filteredOn(EN_COURS::equals)
                    .hasSize(1);
        }
    }

    @Test
    @DisplayName("une cible maitrisee a tout franchi, et n'a plus rien en cours")
    void maitriseeNaRienEnCours() {
        List<CivicEtapeEtat> parcours = CivicLeitner.parcours(5, true);
        assertThat(parcours).containsOnly(FRANCHIE);
        assertThat(parcours).doesNotContain(EN_COURS, A_VENIR);
    }

    @Test
    @DisplayName("🛑 le parcours RECULE apres une erreur — c'est ce qui doit se voir")
    void reculeApresUneErreur() {
        int avant = 4;
        assertThat(CivicLeitner.parcours(avant, false))
                .containsExactly(FRANCHIE, FRANCHIE, FRANCHIE, EN_COURS, A_VENIR);

        int apres = CivicLeitner.suivante(avant, false);
        assertThat(apres).isEqualTo(CivicLeitner.PREMIERE);
        assertThat(CivicLeitner.parcours(apres, false))
                .containsExactly(EN_COURS, A_VENIR, A_VENIR, A_VENIR, A_VENIR);
    }

    @Test
    @DisplayName("une boite hors bornes est ramenee dedans, jamais un parcours vide")
    void borneLesValeursAberrantes() {
        assertThat(CivicLeitner.parcours(0, false))
                .isEqualTo(CivicLeitner.parcours(CivicLeitner.PREMIERE, false));
        assertThat(CivicLeitner.parcours(99, false))
                .isEqualTo(CivicLeitner.parcours(CivicLeitner.DERNIERE, false));
    }
}
