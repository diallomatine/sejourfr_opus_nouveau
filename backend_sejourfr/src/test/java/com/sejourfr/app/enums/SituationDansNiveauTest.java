package com.sejourfr.app.enums;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Ce que verrouille cette classe : le champ qui REMPLACE, sur une tache isolee,
 * la note /20 qu'on n'affiche plus au candidat.
 *
 * <ul>
 *   <li>les bornes viennent des SEUILS de la grille active, pas d'une constante
 *       Java : changer d'echelle deplace les crans, il n'y a rien a recompiler ;</li>
 *   <li>les libelles sont ENCOURAGEANTS et n'annoncent jamais un manque —
 *       « A2 solide », jamais « presque B1 » ;</li>
 *   <li>tout ce qui ne se situe pas rend {@code null} plutot qu'un cran faux.</li>
 * </ul>
 */
class SituationDansNiveauTest {

    /** Echelle du TCF, celle des grilles v6+ : A2 = 2-5, B1 = 6-9, B2 = 10-20. */
    private static ProductionEvaluationProperties.NiveauCecrl seuilsTcf() {
        ProductionEvaluationProperties.NiveauCecrl s = new ProductionEvaluationProperties.NiveauCecrl();
        s.setSeuilB2(10.0);
        s.setSeuilB1(6.0);
        s.setSeuilA2(2.0);
        return s;
    }

    @ParameterizedTest
    @CsvSource({
        // bande A2 = [2 ; 6) -> tiers a 3,33 et 4,67
        "2.0,  A2, ENTREE_DE_PALIER",
        "3.0,  A2, ENTREE_DE_PALIER",
        "4.0,  A2, PALIER_CONFIRME",
        "5.0,  A2, PALIER_SOLIDE",
        // bande B1 = [6 ; 10) -> tiers a 7,33 et 8,67
        "6.0,  B1, ENTREE_DE_PALIER",
        "7.5,  B1, PALIER_CONFIRME",
        "9.0,  B1, PALIER_SOLIDE",
        // bande B2 = [10 ; 20] -> tiers a 13,33 et 16,67
        "10.0, B2, ENTREE_DE_PALIER",
        "15.0, B2, PALIER_CONFIRME",
        "18.0, B2, PALIER_SOLIDE",
        // bande A1 = ]0 ; 2) -> tiers a 0,67 et 1,33
        "0.5,  A1, ENTREE_DE_PALIER",
        "1.0,  A1, PALIER_CONFIRME",
        "1.8,  A1, PALIER_SOLIDE"
    })
    void situeLaNoteDansSaPropreBande(String note, NiveauCecrl niveau, SituationDansNiveau attendu) {
        assertThat(SituationDansNiveau.of(new BigDecimal(note), niveau, seuilsTcf()))
            .isEqualTo(attendu);
    }

    @Test
    void sansNoteOuSansNiveau_rienASituer() {
        assertThat(SituationDansNiveau.of(null, NiveauCecrl.B1, seuilsTcf())).isNull();
        assertThat(SituationDansNiveau.of(new BigDecimal("8"), null, seuilsTcf())).isNull();
        assertThat(SituationDansNiveau.of(new BigDecimal("8"), NiveauCecrl.B1, null)).isNull();
    }

    /** La bande {@code A1_NON_ATTEINT} ne vaut qu'un point : il n'y a pas de position. */
    @Test
    void a1NonAtteintNeSeSituePas() {
        assertThat(SituationDansNiveau.of(BigDecimal.ZERO, NiveauCecrl.A1_NON_ATTEINT, seuilsTcf()))
            .isNull();
    }

    /** C1/C2 sont hors du profil TCF IRN, plafonne a B2. */
    @Test
    void horsProfilTcfIrn_pasDeSituation() {
        assertThat(SituationDansNiveau.of(new BigDecimal("18"), NiveauCecrl.C1, seuilsTcf())).isNull();
        assertThat(SituationDansNiveau.of(new BigDecimal("19"), NiveauCecrl.C2, seuilsTcf())).isNull();
    }

    /**
     * Cas reel : un niveau PLAFONNE (cf. {@code plafond_niveau}) decorrele la
     * note du palier affiche — la note reste celle du bareme, le niveau a ete
     * abaisse. On situe alors dans le palier REELLEMENT annonce, jamais hors de
     * sa propre bande.
     */
    @Test
    void niveauPlafonne_laNoteEstRameneeDansLaBandeAffichee() {
        assertThat(SituationDansNiveau.of(new BigDecimal("12"), NiveauCecrl.A2, seuilsTcf()))
            .isEqualTo(SituationDansNiveau.PALIER_SOLIDE);
        assertThat(SituationDansNiveau.of(new BigDecimal("-3"), NiveauCecrl.B1, seuilsTcf()))
            .isEqualTo(SituationDansNiveau.ENTREE_DE_PALIER);
    }

    /** Les bornes suivent la GRILLE : sur l'ancienne echelle (v3-v5), 12 est un bas de B1. */
    @Test
    void lesBornesSuiventLaGrilleActive() {
        ProductionEvaluationProperties.NiveauCecrl ancienne =
            new ProductionEvaluationProperties.NiveauCecrl();
        ancienne.setSeuilB2(15.0);
        ancienne.setSeuilB1(12.0);
        ancienne.setSeuilA2(8.0);

        assertThat(SituationDansNiveau.of(new BigDecimal("12"), NiveauCecrl.B1, ancienne))
            .isEqualTo(SituationDansNiveau.ENTREE_DE_PALIER);
        assertThat(SituationDansNiveau.of(new BigDecimal("12"), NiveauCecrl.B2, seuilsTcf()))
            .isEqualTo(SituationDansNiveau.ENTREE_DE_PALIER);
    }

    // ------------------------------------------------------------- libelles

    /**
     * CONTRAT GELE, a repercuter a l'identique sur les trois fronts. Aucun de
     * ces libelles ne nomme un manque : on vient de retirer la note /20
     * precisement pour ne plus faire lire un A2 normal comme un echec.
     */
    @Test
    void lesLibellesSontGelesEtEncourageants() {
        assertThat(SituationDansNiveau.ENTREE_DE_PALIER.getLibelle()).isEqualTo("Palier atteint");
        assertThat(SituationDansNiveau.PALIER_CONFIRME.getLibelle()).isEqualTo("Palier confirmé");
        assertThat(SituationDansNiveau.PALIER_SOLIDE.getLibelle()).isEqualTo("Palier solide");

        assertThat(SituationDansNiveau.ENTREE_DE_PALIER.libelleAvecNiveau(NiveauCecrl.A2))
            .isEqualTo("A2 atteint");
        assertThat(SituationDansNiveau.PALIER_CONFIRME.libelleAvecNiveau(NiveauCecrl.B1))
            .isEqualTo("B1 confirmé");
        assertThat(SituationDansNiveau.PALIER_SOLIDE.libelleAvecNiveau(NiveauCecrl.A2))
            .isEqualTo("A2 solide");
    }

    /** Aucun libelle ne doit reintroduire le vocabulaire de deficit qu'on retire. */
    @Test
    void aucunLibelleNAnnonceUnManque() {
        for (SituationDansNiveau s : SituationDansNiveau.values()) {
            assertThat(s.getLibelle().toLowerCase())
                .doesNotContain("presque", "faible", "insuffisant", "manque", "juste",
                    "limite", "fragile");
        }
    }

    @Test
    void pasDeLibelleCompletSurUnNiveauNonSituable() {
        assertThat(SituationDansNiveau.PALIER_SOLIDE.libelleAvecNiveau(NiveauCecrl.A1_NON_ATTEINT))
            .isNull();
        assertThat(SituationDansNiveau.PALIER_SOLIDE.libelleAvecNiveau(null)).isNull();
    }
}
