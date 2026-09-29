package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LA TOLERANCE DES PLAFONDS DE MOTS — le defaut corrige le 2026-08-11.
 *
 * <p>La formule historique {@code floor(plafond * 1,2)} n'accordait <b>aucune
 * marge</b> sur les petits plafonds : sur 3 elle rendait 3. Or les plafonds les
 * plus serres du depot valent justement 3 mots ({@code apport},
 * {@code strength_tag}, {@code focus_tag}), et c'est exactement la que la
 * tolerance avait ete ecrite pour servir.
 *
 * <p>Ce que verrouille cette classe : la tolerance est REELLE partout (toujours
 * au moins un mot de plus), et elle n'a RIEN change aux grands plafonds, ou les
 * 20 % dominaient deja.
 */
class PlafondMotsTest {

    /**
     * Les plafonds reellement declares par les grilles actives, avec leur
     * tolerance effective AVANT / APRES.
     */
    @ParameterizedTest(name = "plafond {0} : {1} avant, {2} apres")
    @CsvSource({
        // plafond, tolere AVANT (floor x1,2), tolere APRES
        "3,  3,  4",   // apport, strength_tag, focus_tag — AUCUNE marge avant
        "5,  6,  6",   // exemple
        "6,  7,  7",   // action
        "8,  9,  9",   // formule
        "14, 16, 16",  // explication
        "20, 24, 24",  // verdict
        "25, 30, 30",  // ce_qui_manque (contrat v1)
        "30, 36, 36",  // success_point
        "35, 42, 42",  // improvement_priority
        "60, 72, 72"   // reformule
    })
    void toleranceEffectiveParPlafond(int plafond, int avant, int apres) {
        assertThat((int) Math.floor(plafond * PlafondMots.TOLERANCE))
            .as("formule historique, conservee comme reference")
            .isEqualTo(avant);
        assertThat(PlafondMots.tolere(plafond)).isEqualTo(apres);
    }

    @Test
    void unPlafondToleTOUJOURSAuMoinsUnMotDePlus() {
        for (int plafond = 1; plafond <= 100; plafond++) {
            assertThat(PlafondMots.tolere(plafond))
                .as("plafond %d", plafond)
                .isGreaterThan(plafond);
        }
    }

    /** NON-REGRESSION : au-dessus de 4, la marge de 20 % l'emporte, comme avant. */
    @Test
    void auDelaDeQuatreLaFormuleHistoriqueEstInchangee() {
        for (int plafond = 5; plafond <= 200; plafond++) {
            assertThat(PlafondMots.tolere(plafond))
                .as("plafond %d", plafond)
                .isEqualTo((int) Math.floor(plafond * PlafondMots.TOLERANCE));
        }
    }

    @Test
    void unApportDeQuatreMotsPasse_deCinqNon() {
        assertThat(PlafondMots.depasse("plus poli et net", 3)).isFalse();
        assertThat(PlafondMots.depasse("plus poli et net encore", 3)).isTrue();
    }

    @Test
    void leComptageIgnoreLesBlancsDeBordEtLesSuites() {
        assertThat(PlafondMots.compter("  plus   poli  ")).isEqualTo(2);
        assertThat(PlafondMots.compter("   ")).isZero();
        assertThat(PlafondMots.compter(null)).isZero();
    }
}
