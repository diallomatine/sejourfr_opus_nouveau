package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.EnumSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LA MARCHE SUIVANTE — {@code min(constate + 1, vise)}, seule autorite du
 * module.
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>un saut de deux paliers est ramene a UN : c'est le defaut mesure en base
 *       (constate A2, objectif B2, texte modele reevalue A2 apres avoir ete
 *       recopie tel quel par le candidat) ;</li>
 *   <li>l'objectif reste un PLAFOND : on ne propose jamais plus haut que ce que
 *       la demarche exige ;</li>
 *   <li>« rien a viser » ne rend rien du tout — donc aucun appel paye ;</li>
 *   <li>profil TCF IRN : jamais au-dessus du B2, jamais en dessous de l'A2 (les
 *       seuls paliers qu'une demarche puisse exiger).</li>
 * </ul>
 */
class CompetenceNiveauVisePalierCibleTest {

    @ParameterizedTest(name = "constate {0}, objectif {1} -> cible {2}")
    @CsvSource({
        // Depuis le bas, la marche suivante est l'A2 : c'est le plus petit
        // palier qu'une demarche puisse exiger, on ne descend pas plus bas.
        "A1_NON_ATTEINT, A2, A2",
        "A1_NON_ATTEINT, B2, A2",
        "A1,             A2, A2",
        "A1,             B1, A2",
        "A1,             B2, A2",
        // LE CAS CORRIGE : A2 qui vise le B2 ne recevait pas une marche, il
        // recevait un etage.
        "A2,             B2, B1",
        "A2,             B1, B1",
        // Un seul palier d'ecart : rien ne change.
        "B1,             B2, B2"
    })
    void laCibleEstLaMarcheSuivantePlafonneeParLObjectif(String constate, String vise,
                                                         String cible) {
        assertThat(CompetenceNiveauViseService.palierCible(
            NiveauCecrl.valueOf(constate), TargetLevel.valueOf(vise)))
            .isEqualTo(TargetLevel.valueOf(cible));
    }

    /**
     * Rien a viser ⇒ rien du tout : aucun appel n'est emis. Montrer une
     * « version B1 » a quelqu'un qui ecrit deja du B2 serait un contresens, et le
     * payer le serait deux fois.
     */
    @ParameterizedTest(name = "constate {0}, objectif {1}")
    @CsvSource({
        "B1, B1",
        "B2, B2",
        "B2, B1",
        "B2, A2",
        "C1, B2",
        "C2, B2"
    })
    void aucuneCibleQuandLObjectifEstDejaAtteint(String constate, String vise) {
        assertThat(CompetenceNiveauViseService.palierCible(
            NiveauCecrl.valueOf(constate), TargetLevel.valueOf(vise))).isNull();
    }

    @Test
    void aucuneCibleSansNiveauConstateNiObjectif() {
        assertThat(CompetenceNiveauViseService.palierCible(null, TargetLevel.B2)).isNull();
        assertThat(CompetenceNiveauViseService.palierCible(NiveauCecrl.A2, null)).isNull();
        assertThat(CompetenceNiveauViseService.palierCible(null, null)).isNull();
    }

    /**
     * PROFIL TCF IRN : la cible est toujours un palier visable (A2, B1 ou B2), et
     * jamais au-dessus du B2 — le contrat de sortie ne connait pas C1/C2, et une
     * demarche n'en exige aucun.
     */
    @ParameterizedTest
    @EnumSource(NiveauCecrl.class)
    void laCibleResteToujoursUnPalierVisable(NiveauCecrl constate) {
        for (TargetLevel vise : TargetLevel.values()) {
            TargetLevel cible = CompetenceNiveauViseService.palierCible(constate, vise);
            if (cible == null) continue;
            assertThat(cible.ordinal()).isLessThanOrEqualTo(vise.ordinal());
            assertThat(NiveauCecrl.valueOf(cible.name()).ordinal())
                .isGreaterThan(constate.ordinal());
        }
    }
}
