package com.sejourfr.app.enums;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La correspondance <b>démarche → palier de français</b>, gelée.
 *
 * <p>C'est une donnée légale (seuils en vigueur au 1ᵉʳ janvier 2026), pas un
 * réglage : {@code CSP → A2}, {@code CR → B1}, {@code NAT → B2}. Elle vit dans
 * l'enum et les trois fronts en tiennent un miroir gelé du même côté —
 * {@code web_sejoufr/lib/types.test.ts} et
 * {@code mobile_sejourfr/test/target_level_test.dart}. Même technique que
 * {@code SkillLabelsTest} : quatre couches, une seule table, quatre tests qui
 * refusent de diverger.
 *
 * <p>Ce test est la raison pour laquelle un futur Claude ne doit <b>pas</b>
 * réécrire ce switch dans un service, un écran ou un composant. Il l'a été six
 * fois, et c'est ainsi qu'un candidat visant la naturalisation s'est retrouvé
 * tiré vers le B1.
 */
class TargetProcedureTest {

    /** Le référentiel, écrit une fois de plus, à la main, exprès. */
    private static final Map<TargetProcedure, TargetLevel> REFERENTIEL = Map.of(
        TargetProcedure.CSP, TargetLevel.A2,
        TargetProcedure.CR, TargetLevel.B1,
        TargetProcedure.NAT, TargetLevel.B2);

    @Test
    void chaqueDemarcheExigeSonPalier() {
        assertThat(TargetProcedure.CSP.getRequiredTcfLevel()).isEqualTo(TargetLevel.A2);
        assertThat(TargetProcedure.CR.getRequiredTcfLevel()).isEqualTo(TargetLevel.B1);
        assertThat(TargetProcedure.NAT.getRequiredTcfLevel()).isEqualTo(TargetLevel.B2);
    }

    /** Une démarche ajoutée sans son palier ne doit pas passer inaperçue. */
    @Test
    void toutesLesDemarchesSontCouvertes() {
        assertThat(TargetProcedure.values()).hasSize(REFERENTIEL.size());
        for (TargetProcedure p : TargetProcedure.values()) {
            assertThat(p.getRequiredTcfLevel())
                .as("palier exigé par %s", p)
                .isEqualTo(REFERENTIEL.get(p));
        }
    }

    /** L'ordre de déclaration EST l'ordre CECRL : tout le plancher en dépend. */
    @Test
    void lOrdreDesPaliersEstCeluiDuCecrl() {
        assertThat(TargetLevel.values())
            .containsExactly(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);
    }

    // ------------------------------------------------------------- plancher

    /**
     * LE DÉFAUT D'ORIGINE : naturalisation + un niveau déclaré plus bas. La
     * démarche l'emporte — sinon le candidat n'est jamais tiré vers le B2 dont
     * il a besoin, et le système le félicite d'un objectif qu'il n'a pas.
     */
    @Test
    void laDemarcheFaitPlancher() {
        assertThat(TargetProcedure.niveauVise(TargetProcedure.NAT, TargetLevel.B1))
            .isEqualTo(TargetLevel.B2);
        assertThat(TargetProcedure.niveauVise(TargetProcedure.NAT, TargetLevel.A2))
            .isEqualTo(TargetLevel.B2);
        assertThat(TargetProcedure.niveauVise(TargetProcedure.CR, TargetLevel.A2))
            .isEqualTo(TargetLevel.B1);
    }

    /** Viser plus haut que sa démarche est un choix légitime : on le respecte. */
    @Test
    void unNiveauDeclarePlusHautLEmporte() {
        assertThat(TargetProcedure.niveauVise(TargetProcedure.CSP, TargetLevel.B2))
            .isEqualTo(TargetLevel.B2);
        assertThat(TargetProcedure.niveauVise(TargetProcedure.CSP, TargetLevel.B1))
            .isEqualTo(TargetLevel.B1);
    }

    @Test
    void sansNiveauDeclare_laDemarcheFaitFoi() {
        assertThat(TargetProcedure.niveauVise(TargetProcedure.NAT, null))
            .isEqualTo(TargetLevel.B2);
    }

    /** Candidat TCF sans démarche civique : son choix, seul. */
    @Test
    void sansDemarche_leNiveauDeclareFaitFoi() {
        assertThat(TargetProcedure.niveauVise(null, TargetLevel.B1)).isEqualTo(TargetLevel.B1);
    }

    /** Rien de connu ⇒ rien de deviné. On n'invente jamais une démarche. */
    @Test
    void rienDeConnu_rienDeDevine() {
        assertThat(TargetProcedure.niveauVise(null, null)).isNull();
    }

    /** Le couple cohérent est un point fixe : la règle ne bouge pas ce qui va. */
    @Test
    void unCoupleCoherentEstUnPointFixe() {
        for (TargetProcedure p : TargetProcedure.values()) {
            assertThat(TargetProcedure.niveauVise(p, p.getRequiredTcfLevel()))
                .isEqualTo(p.getRequiredTcfLevel());
        }
    }
}
